import AppKit
import LocusCore

/// Turns on Do Not Disturb for the length of a session (PRD-0011) by running the
/// user's Focus shortcuts with the `shortcuts` command-line tool.
final class FocusModeController: NSObject {
    /// How long a shortcut may hold back the completion notification, or delay quitting.
    private static let timeout: TimeInterval = 5
    private static let tool = URL(fileURLWithPath: "/usr/bin/shortcuts")

    private let setting = FocusModeSetting()
    private var sync = FocusModeSync()
    /// Set when a shortcut failed; shown in the menu until the next one succeeds.
    private var warning: String?

    // MARK: Menu

    /// The setting's menu item, shown while idle.
    func makeItem() -> NSMenuItem {
        let item = NSMenuItem(
            title: "Turn On Do Not Disturb During Sessions", action: #selector(toggle), keyEquivalent: "")
        item.target = self
        item.state = setting.isEnabled ? .on : .off
        return item
    }

    /// A disabled item explaining the last failure, if a shortcut failed.
    func makeWarningItem() -> NSMenuItem? {
        guard let warning else { return nil }
        let item = NSMenuItem(title: "⚠︎ \(warning)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func toggle() {
        warning = nil
        if setting.isEnabled {
            setting.isEnabled = false
            return
        }
        guard let installed = Self.installedShortcuts() else {
            Alerts.showError("Couldn't read your shortcuts", "Locus uses the Shortcuts app to turn on Do Not Disturb.")
            return
        }
        let missing = FocusShortcut.missing(installed: installed)
        guard missing.isEmpty else {
            Self.showSetup(missing: missing)
            return
        }
        setting.isEnabled = true
    }

    // MARK: Session

    func sessionStarted() {
        guard let shortcut = sync.sessionStarted(enabled: setting.isEnabled) else { return }
        run(shortcut) { [weak self] succeeded in
            if !succeeded {
                self?.sync.turnOnFailed()
            }
        }
    }

    /// Turns Focus off if Locus turned it on, then calls `completion`, so the completion
    /// beep and notification aren't silenced (PRD-0010). Calls it right away otherwise.
    func sessionEnded(then completion: @escaping () -> Void) {
        guard let shortcut = sync.sessionEnded() else {
            completion()
            return
        }
        var finished = false
        let finish = {
            guard !finished else { return }
            finished = true
            completion()
        }
        run(shortcut) { _ in finish() }
        // Don't hold the notification back for long if the shortcut hangs.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout, execute: finish)
    }

    /// Turns Focus off before Locus quits, waiting briefly for the shortcut.
    func appWillTerminate() {
        guard let shortcut = sync.sessionEnded() else { return }
        let process = Self.makeProcess(["run", shortcut.name])
        let done = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in done.signal() }
        guard (try? process.run()) != nil else { return }
        _ = done.wait(timeout: .now() + Self.timeout)
    }

    // MARK: Shortcuts

    /// Runs `shortcut` in the background and reports success on the main queue.
    private func run(_ shortcut: FocusShortcut, completion: @escaping (Bool) -> Void) {
        let process = Self.makeProcess(["run", shortcut.name])
        process.terminationHandler = { finished in
            let succeeded = finished.terminationStatus == 0
            DispatchQueue.main.async { [weak self] in
                self?.warning = succeeded ? nil : "“\(shortcut.name)” failed. Turn the setting off and on to check it."
                completion(succeeded)
            }
        }
        do {
            try process.run()
        } catch {
            warning = "Couldn't run “\(shortcut.name)”."
            completion(false)
        }
    }

    /// Names of the user's shortcuts, or nil if they couldn't be listed.
    private static func installedShortcuts() -> [String]? {
        let process = makeProcess(["list"])
        let output = Pipe()
        process.standardOutput = output
        guard (try? process.run()) != nil else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, let text = String(bytes: data, encoding: .utf8) else { return nil }
        return text.split(separator: "\n").map(String.init)
    }

    private static func makeProcess(_ arguments: [String]) -> Process {
        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        return process
    }

    /// Explains how to create the missing shortcuts and offers to open Shortcuts.
    private static func showSetup(missing: [FocusShortcut]) {
        let steps = missing.map { shortcut in
            switch shortcut {
            case .turnOn:
                "• “\(shortcut.name)”: a Set Focus action that turns Do Not Disturb On until Turned Off."
            case .turnOff:
                "• “\(shortcut.name)”: a Set Focus action that turns Do Not Disturb Off."
            }
        }
        let alert = NSAlert()
        alert.icon = NSApp.applicationIconImage
        alert.messageText = "Set up Do Not Disturb for focus sessions"
        alert.informativeText = """
            macOS doesn't let apps change Focus directly, so Locus runs two shortcuts. \
            In the Shortcuts app, create:

            \(steps.joined(separator: "\n"))

            Then choose Turn On Do Not Disturb During Sessions again.
            """
        alert.addButton(withTitle: "Open Shortcuts")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn,
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.shortcuts")
        else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
