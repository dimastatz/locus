import AppKit
import LocusCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Full-screen transitions take about a second. Lock checks pause this long
    /// after reclaiming the window so the transition doesn't count as an escape.
    private static let transitionGrace: TimeInterval = 2

    private let ownProcessID = ProcessInfo.processInfo.processIdentifier
    private let vault = PasswordVault(store: KeychainSecretStore())
    private lazy var sessions = SessionController(vault: vault)
    private let notifier = SessionNotifier()

    private var statusItem: NSStatusItem!
    private var lockedWindow: LockedWindow?
    private var exitGuard: ExitGuard?
    private var ticker: Timer?
    private var prompt: PasswordPrompt?
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
        notifier.requestAuthorization()
        if !Accessibility.isTrusted {
            Accessibility.requestTrust()
        }
    }

    // MARK: Menu bar (PRD-0001)

    /// Left-click starts a session when idle. Right-click, ⌃-click, or any click during a session opens the menu.
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
            let info = NSMenuItem(title: "\(session.target.appName) locked · \(remaining) left", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
            menu.addItem(item("End Session Early…", #selector(promptUnlock)))
        } else {
            let minutes = Int(FocusSession.defaultDuration / 60)
            menu.addItem(item("Start Focus Session (\(minutes) min)", #selector(startSession)))
            menu.addItem(item("Change Unlock Password…", #selector(changePassword)))
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
            button.image = symbol("lock.fill")
            button.title = " " + Countdown.format(session.remaining(at: Date()))
            button.toolTip = "Locus: \(session.target.appName) is locked"
        } else {
            button.image = symbol("lock.open")
            button.title = ""
            button.toolTip = "Locus: click to lock your focus"
        }
    }

    private func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Locus")
        image?.isTemplate = true
        return image
    }

    // MARK: Starting a session (PRD-0002)

    @objc private func startSession() {
        guard !sessions.isActive else { return }
        guard Accessibility.isTrusted else {
            showAccessibilityAlert()
            return
        }
        guard let app = targetApp() else {
            showError("Nothing to lock", "Click into the app you want to focus on, then click the Locus icon.")
            return
        }
        if vault.hasPassword {
            lock(app)
        } else {
            promptPasswordSetup { [weak self] in self?.lock(app) }
        }
    }

    /// The app the user was working in. Clicking a menu bar item doesn't activate
    /// Locus, so this is normally the frontmost app.
    private func targetApp() -> NSRunningApplication? {
        if let front = NSWorkspace.shared.frontmostApplication, front.processIdentifier != ownProcessID {
            return front
        }
        return lastExternalApp.flatMap { $0.isTerminated ? nil : $0 }
    }

    private func lock(_ app: NSRunningApplication) {
        let name = app.localizedName ?? "This app"
        guard let window = LockedWindow(app: app) else {
            showError("Can't lock \(name)", "Locus couldn't find a window to lock. Open a window in \(name) and try again.")
            return
        }
        guard window.isFullScreen || window.supportsFullScreen else {
            showError("\(name) doesn't support full screen", "Locus locks a window by putting it in full screen, which \(name) doesn't allow.")
            return
        }

        let target = LockTarget(processID: app.processIdentifier, bundleIdentifier: app.bundleIdentifier, appName: name)
        do {
            try sessions.start(target: target, now: Date())
        } catch {
            showError("Couldn't start a focus session", "\(error)")
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
        promptUnlock()
    }

    private func reclaim() {
        lockedWindow?.reclaim()
        checksPausedUntil = Date().addingTimeInterval(Self.transitionGrace)
    }

    @objc private func promptUnlock() {
        guard let session = sessions.session else { return }
        if let prompt, prompt.isVisible {
            prompt.show()
            return
        }

        let remaining = Countdown.format(session.remaining(at: Date()))
        let prompt = PasswordPrompt(
            title: "Stay focused",
            message: "\(remaining) left on \(session.target.appName). To end the session early, type your unlock password.",
            placeholders: ["Unlock password"],
            confirmTitle: "Unlock"
        )
        prompt.onSubmit = { [weak self] values in
            guard let self else { return nil }
            switch self.sessions.unlock(password: values[0]) {
            case .unlocked(let ended):
                self.finish(ended, reason: .unlocked)
                return nil
            case .wrongPassword:
                return "Wrong password. The session is still locked."
            case .noActiveSession:
                return nil
            }
        }
        present(prompt) { [weak self] in
            // Cancelled: hand the keyboard back to the locked window.
            self?.lockedWindow?.focus()
        }
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

    // MARK: Password and permissions

    @objc private func changePassword() {
        promptPasswordSetup(then: nil)
    }

    private func promptPasswordSetup(then completion: (() -> Void)?) {
        let prompt = PasswordPrompt(
            title: "Set Unlock Password",
            message: "Choose a long password, at least \(PasswordVault.minimumLength) characters. You'll have to type it to end a focus session early, so it should be tedious to type.",
            placeholders: ["New password", "Confirm password"],
            confirmTitle: "Save"
        )
        prompt.onSubmit = { [weak self] values in
            guard let self else { return nil }
            do {
                try self.vault.setPassword(values[0], confirmation: values[1])
            } catch PasswordError.tooShort(let minimum) {
                return "The password must be at least \(minimum) characters."
            } catch PasswordError.mismatch {
                return "The passwords don't match."
            } catch {
                return error.localizedDescription
            }
            completion?()
            return nil
        }
        present(prompt, onCancel: nil)
    }

    private func present(_ prompt: PasswordPrompt, onCancel: (() -> Void)?) {
        self.prompt?.close()
        prompt.onClose = { [weak self, weak prompt] in
            // Still current means it closed without finish() taking it down: cancelled or a setup save.
            guard let self, let prompt, self.prompt === prompt else { return }
            self.prompt = nil
            onCancel?()
        }
        self.prompt = prompt
        prompt.show()
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Locus needs Accessibility access"
        alert.informativeText = "Locus uses Accessibility to put the app you're focusing on into full screen and keep it there. Turn on Locus in System Settings → Privacy & Security → Accessibility, then try again."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            Accessibility.openSettings()
        }
    }

    private func showError(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func observeWorkspace() {
        lastExternalApp = NSWorkspace.shared.frontmostApplication
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] note in
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
