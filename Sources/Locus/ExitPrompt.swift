import AppKit
import LocusCore

/// "Are you sure you want to exit?" dialog with Go Back and hold-to-confirm Exit (PRD-0005).
///
/// It is a non-activating panel that joins every Space, including the locked app's
/// full-screen Space. Showing it doesn't activate Locus, so the locked app stays
/// frontmost and macOS doesn't switch Spaces.
final class ExitPrompt: NSObject {
    var onGoBack: (() -> Void)?
    var onExit: (() -> Void)?

    private let panel: PromptPanel
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private let hintLabel = NSTextField(labelWithString: "")
    private let exitButton: HoldButton

    init(message: String, holdDuration: TimeInterval = HoldToConfirm.defaultDuration) {
        panel = PromptPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 10),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        exitButton = HoldButton(title: "Exit", duration: holdDuration)
        super.init()

        panel.title = "Locus"
        panel.level = .modalPanel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isReleasedWhenClosed = false

        let titleLabel = NSTextField(labelWithString: "Are you sure you want to exit?")
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        messageLabel.stringValue = message
        messageLabel.preferredMaxLayoutWidth = 380
        hintLabel.stringValue = "Hold Exit for \(Int(holdDuration)) seconds to end the session."
        hintLabel.textColor = .secondaryLabelColor

        // Go Back is the default: Return and Esc both choose it.
        let goBack = NSButton(title: "Go Back", target: self, action: #selector(goBack))
        goBack.keyEquivalent = "\r"
        goBack.controlSize = .large
        panel.onCancel = { [weak self] in self?.goBack() }

        exitButton.onComplete = { [weak self] in
            self?.close()
            self?.onExit?()
        }
        exitButton.onInterrupted = { [weak self] in
            self?.hintLabel.stringValue =
                "Released too early. Hold Exit for \(Int(holdDuration)) seconds to end the session."
        }

        let buttons = NSStackView(views: [exitButton, goBack])
        buttons.spacing = 12

        let stack = NSStackView(views: [titleLabel, messageLabel, hintLabel, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(20, after: hintLabel)
        buttons.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -20).isActive = true

        panel.contentView = stack
    }

    var isVisible: Bool { panel.isVisible }

    func update(message: String) {
        messageLabel.stringValue = message
    }

    func show() {
        if !panel.isVisible {
            panel.center()
        }
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func close() {
        exitButton.interrupt()
        panel.orderOut(nil)
    }

    @objc private func goBack() {
        close()
        onGoBack?()
    }
}

private final class PromptPanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { true }

    /// Esc.
    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
