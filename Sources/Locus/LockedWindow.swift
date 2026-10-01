import AppKit
import ApplicationServices

enum Accessibility {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system "allow Accessibility" prompt if Locus isn't trusted yet.
    static func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func openSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

/// The window a session locks, controlled through the Accessibility API (PRD-0002, PRD-0003).
final class LockedWindow {
    private static let fullScreenAttribute = "AXFullScreen" as CFString

    let app: NSRunningApplication
    private let appElement: AXUIElement
    private var window: AXUIElement

    /// Fails if the app has no focused window Locus can reach.
    init?(app: NSRunningApplication) {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        guard let window = Self.focusedWindow(of: appElement) else { return nil }
        self.app = app
        self.appElement = appElement
        self.window = window
    }

    var supportsFullScreen: Bool {
        var settable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(window, Self.fullScreenAttribute, &settable)
        return result == .success && settable.boolValue
    }

    var isFullScreen: Bool { bool(Self.fullScreenAttribute) }

    /// True when the user has got out of the lock: left full screen, minimized,
    /// hid the app, closed the window, or switched to another app.
    var hasEscaped: Bool {
        !isAlive || bool(kAXMinimizedAttribute as CFString) || !isFullScreen || app.isHidden || !app.isActive
    }

    /// Brings the locked window back to the front and into full screen.
    func reclaim() {
        // If the locked window was closed, follow whichever window the app focuses now.
        if !isAlive, let replacement = Self.focusedWindow(of: appElement) {
            window = replacement
        }
        if app.isHidden { app.unhide() }
        set(kAXMinimizedAttribute as CFString, false)
        focus()
        if !isFullScreen { set(Self.fullScreenAttribute, true) }
    }

    /// Makes the locked app frontmost and raises its window, without changing full screen.
    func focus() {
        // Since macOS 14, activate() from a background app may be ignored,
        // so also set AXFrontmost, which Accessibility access permits.
        AXUIElementSetAttributeValue(appElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        app.activate(options: [])
    }

    private var isAlive: Bool {
        var role: CFTypeRef?
        return AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &role) == .success
    }

    private func bool(_ attribute: CFString) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, attribute, &value) == .success else { return false }
        return (value as? Bool) ?? false
    }

    private func set(_ attribute: CFString, _ value: Bool) {
        AXUIElementSetAttributeValue(window, attribute, (value ? kCFBooleanTrue : kCFBooleanFalse) as CFTypeRef)
    }

    private static func focusedWindow(of appElement: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }
}
