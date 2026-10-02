import AppKit
import LocusCore

/// "Are you sure you want to exit?" dialog with Go Back and hold-to-confirm Exit (PRD-0005).
final class ExitPrompt: NSObject {
    var onGoBack: (() -> Void)?
    var onExit: (() -> Void)?

    private let panel: PromptPanel
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private let hintLabel = NSTextField(labelWithString: "")
    private let exitButton: HoldButton

    init(message: String, holdDuration: TimeInterval = HoldToConfirm.defaultDuration) {
        panel = PromptPanel(width: 500)
        exitButton = HoldButton(title: "Exit", duration: holdDuration)
        super.init()

        let titleLabel = NSTextField(labelWithString: "Are you sure you want to exit?")
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        messageLabel.stringValue = message
        messageLabel.preferredMaxLayoutWidth = 360
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
            self?.panel.fitToContent()
        }

        let buttons = NSStackView(views: [exitButton, goBack])
        buttons.spacing = 12

        let content = NSStackView(views: [titleLabel, messageLabel, hintLabel, buttons])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 10
        content.setCustomSpacing(20, after: hintLabel)
        buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true

        panel.setContent(content)
    }

    var isVisible: Bool { panel.isVisible }

    func update(message: String) {
        messageLabel.stringValue = message
        panel.fitToContent()
    }

    func show() {
        panel.present()
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
