import AppKit

/// Floating panel for Locus dialogs (start confirmation, exit confirmation).
///
/// It is non-activating and joins every Space, including another app's full-screen
/// Space. Showing it doesn't activate Locus, so the user's app stays frontmost and
/// macOS doesn't switch Spaces.
final class PromptPanel: NSPanel {
    /// Called on Esc.
    var onCancel: (() -> Void)?

    init(width: CGFloat) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 10),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        title = "Locus"
        level = .modalPanel
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    /// Lays out the app icon on the left and `content` on the right, like a macOS alert (PRD-0006).
    func setContent(_ content: NSView) {
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let layout = NSStackView(views: [icon, content])
        layout.orientation = .horizontal
        layout.alignment = .top
        layout.spacing = 16
        layout.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        contentView = layout
    }

    func present() {
        if !isVisible {
            center()
        }
        orderFrontRegardless()
        makeKey()
    }
}
