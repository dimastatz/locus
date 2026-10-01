import AppKit
import LocusCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Full-screen transitions take about a second. Lock checks pause this long
    /// after reclaiming the window so the transition doesn't count as an escape.
    private static let transitionGrace: TimeInterval = 2

    private let ownProcessID = ProcessInfo.processInfo.processIdentifier
    private let sessions = SessionController()
    private let focusDuration = FocusDurationSetting()
    private lazy var durationMenu = DurationMenu(setting: focusDuration)
    private let notifier = SessionNotifier()

    private var statusItem: NSStatusItem!
    private var lockedWindow: LockedWindow?
    private var exitGuard: ExitGuard?
    private var ticker: Timer?
    private var prompt: ExitPrompt?
    private var startPrompt: StartPrompt?
    private var checksPausedUntil = Date.distantPast
    private var lastExternalApp: NSRunningApplication?
    private var workspaceObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
        render()
        observeWorkspace()
        LegacyKeychain.removeUnlockPassword()
        notifier.requestAuthorization()
        if !Accessibility.isTrusted {
            Accessibility.requestTrust()
        }
    }

    // MARK: Menu bar (PRD-0001)

    /// Left-click starts a session (after confirmation) when idle. Right-click, ⌃-click, or any click during a session opens the menu.
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if sessions.isActive || wantsMenu {
            showMenu()
        } else {
            startSession()
        }
    }

    private func showMenu() {
        statusItem.menu = buildMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        if let session = sessions.session {
            let remaining = Countdown.format(session.remaining(at: Date()))
            let info = NSMenuItem(
                title: "\(session.target.appName) locked · \(remaining) left", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
            menu.addItem(item("End Session Early…", #selector(promptExit)))
        } else {
            menu.addItem(item("Start Focus Session (\(focusDuration.minutes) min)", #selector(startSession)))
            menu.addItem(durationMenu.makeItem())
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Locus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quit.target = NSApp
        quit.isEnabled = !sessions.isActive
        menu.addItem(quit)
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func render() {
        guard let button = statusItem.button else { return }
        if let session = sessions.session {
            button.image = MenuBarIcon.inSession
            button.title = " " + Countdown.format(session.remaining(at: Date()))
            button.toolTip = "Locus: \(session.target.appName) is locked"
        } else {
            button.image = MenuBarIcon.idle
            button.title = ""
            button.toolTip = "Locus: click to lock your focus"
        }
    }

    // MARK: Starting a session (PRD-0002)

    /// Checks that the frontmost window can be locked, then asks for confirmation (PRD-0007).
    @objc private func startSession() {
        guard !sessions.isActive else { return }
        if let startPrompt, startPrompt.isVisible {
            startPrompt.show()
            return
        }
        guard Accessibility.isTrusted else {
            Alerts.showAccessibilityRequired()
            return
        }
        guard let app = targetApp() else {
            Alerts.showError("Nothing to lock", "Click into the app you want to focus on, then click the Locus icon.")
            return
        }
        let name = app.localizedName ?? "This app"
        guard let window = LockedWindow(app: app) else {
            Alerts.showError(
                "Can't lock \(name)", "Locus couldn't find a window to lock. Open a window in \(name) and try again.")
            return
        }
        guard window.isFullScreen || window.supportsFullScreen else {
            Alerts.showError(
                "\(name) doesn't support full screen",
                "Locus locks a window by putting it in full screen, which \(name) doesn't allow.")
            return
        }

        // Read once, so the dialog and the session agree even if the setting changes meanwhile.
        let duration = focusDuration.duration
        let prompt = StartPrompt(appName: name, duration: duration)
        prompt.onStart = { [weak self] in
            self?.startPrompt = nil
            // The app may have quit while the dialog was open.
            guard !app.isTerminated else { return }
            self?.lock(window, name: name, duration: duration)
        }
        prompt.onCancel = { [weak self] in
            self?.startPrompt = nil
            window.focus()
        }
        startPrompt = prompt
        prompt.show()
    }

    /// The app the user was working in. Clicking a menu bar item doesn't activate
    /// Locus, so this is normally the frontmost app.
    private func targetApp() -> NSRunningApplication? {
        if let front = NSWorkspace.shared.frontmostApplication, front.processIdentifier != ownProcessID {
            return front
        }
        return lastExternalApp.flatMap { $0.isTerminated ? nil : $0 }
    }

    private func lock(_ window: LockedWindow, name: String, duration: TimeInterval) {
        let app = window.app
        let target = LockTarget(processID: app.processIdentifier, bundleIdentifier: app.bundleIdentifier, appName: name)
        do {
            try sessions.start(target: target, duration: duration, now: Date())
        } catch {
            Alerts.showError("Couldn't start a focus session", "\(error)")
            return
        }

        lockedWindow = window
        reclaim()

        let exitGuard = ExitGuard(lockedProcessID: app.processIdentifier)
        exitGuard.onEvent = { [weak self] event in self?.handle(event) }
        exitGuard.start()
        self.exitGuard = exitGuard

        let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
        render()
    }

    // MARK: Keeping the lock (PRD-0003)

    private func handle(_ event: ExitGuard.Event) {
        guard let session = sessions.session else { return }
        switch event {
        case .appActivated(let pid):
            if sessions.shouldReclaimFocus(activatedProcessID: pid, ownProcessID: ownProcessID) {
                exitAttempted()
            }
        case .spaceChanged:
            checkLock()
        case .blockedShortcut:
            exitAttempted()
        case .targetTerminated:
            if let ended = sessions.targetDidTerminate(processID: session.target.processID) {
                finish(ended, reason: .targetTerminated)
            }
        }
    }

    private func tick() {
        if let ended = sessions.tick(now: Date()) {
            finish(ended, reason: .completed)
            return
        }
        checkLock()
        render()
        prompt?.update(message: exitMessage())
    }

    /// Fallback for escapes the guard didn't catch: the window left full screen,
    /// was minimized or closed, or another app is in front.
    private func checkLock() {
        guard let window = lockedWindow, Date() >= checksPausedUntil else { return }
        if window.hasEscaped {
            exitAttempted()
        }
    }

    private func exitAttempted() {
        if lockedWindow?.hasEscaped == true {
            reclaim()
        }
        promptExit()
    }

    private func reclaim() {
        lockedWindow?.reclaim()
        checksPausedUntil = Date().addingTimeInterval(Self.transitionGrace)
    }

    // MARK: Hold to exit (PRD-0005)

    @objc private func promptExit() {
        guard sessions.isActive else { return }
        if let prompt, prompt.isVisible {
            prompt.show()
            return
        }

        let prompt = ExitPrompt(message: exitMessage())
        prompt.onGoBack = { [weak self] in
            self?.prompt = nil
            self?.lockedWindow?.focus()
        }
        prompt.onExit = { [weak self] in
            guard let self, let ended = self.sessions.exitEarly() else { return }
            self.finish(ended, reason: .exitedEarly)
        }
        self.prompt = prompt
        prompt.show()
    }

    private func exitMessage() -> String {
        guard let session = sessions.session else { return "" }
        let remaining = Countdown.format(session.remaining(at: Date()))
        return "\(remaining) of focus left on \(session.target.appName)."
    }

    // MARK: Ending a session (PRD-0004)

    private func finish(_ session: FocusSession, reason: SessionEndReason) {
        ticker?.invalidate()
        ticker = nil
        exitGuard?.stop()
        exitGuard = nil
        lockedWindow = nil
        let openPrompt = prompt
        prompt = nil
        openPrompt?.close()
        render()
        notifier.sessionEnded(session, reason: reason)
    }

    private func observeWorkspace() {
        lastExternalApp = NSWorkspace.shared.frontmostApplication
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) {
                [weak self] note in
                guard let self,
                    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                    app.processIdentifier != self.ownProcessID
                else { return }
                self.lastExternalApp = app
            },
            // The end time is wall-clock, so a session that expired during sleep completes right away.
            center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self, self.sessions.isActive else { return }
                self.tick()
            },
        ]
    }
}
