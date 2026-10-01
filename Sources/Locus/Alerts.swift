import AppKit

/// Modal alerts shown while idle. Never used during a session, where activating
/// Locus would pull the user out of the locked app's full-screen Space.
enum Alerts {
    static func showAccessibilityRequired() {
        let alert = NSAlert()
        alert.messageText = "Locus needs Accessibility access"
        alert.informativeText = """
            Locus uses Accessibility to put the app you're focusing on into full screen and keep it there. \
            Turn on Locus in System Settings → Privacy & Security → Accessibility, then try again.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            Accessibility.openSettings()
        }
    }

    static func showError(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
