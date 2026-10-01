import AppKit
import LocusCore

/// "Are you sure you want to start a focus session?" dialog shown before locking (PRD-0007).
final class StartPrompt: NSObject {
    var onStart: (() -> Void)?
    var onCancel: (() -> Void)?

    private let panel = PromptPanel(width: 500)

    init(appName: String, duration: TimeInterval, exitHoldDuration: TimeInterval = HoldToConfirm.defaultDuration) {
        super.init()

        let titleLabel = NSTextField(labelWithString: "Are you sure you want to start a focus session?")
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        let message = NSTextField(
            wrappingLabelWithString: """
                \(appName) will go full screen and stay locked for \(Int(duration / 60)) minutes. \
                To leave early, you'll have to hold Exit for \(Int(exitHoldDuration)) seconds.
                """)
        message.preferredMaxLayoutWidth = 380

        // Start is the default: Return starts, Esc cancels.
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        let start = NSButton(title: "Start", target: self, action: #selector(start))
        start.keyEquivalent = "\r"
        panel.onCancel = { [weak self] in self?.cancel() }

        // Right-aligned, like macOS alert buttons.
        let buttons = NSStackView()
        buttons.setViews([cancel, start], in: .trailing)
        buttons.spacing = 12

        let content = NSStackView(views: [titleLabel, message, buttons])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 10
        content.setCustomSpacing(20, after: message)
        buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true

        panel.setContent(content)
    }

    var isVisible: Bool { panel.isVisible }

    func show() {
        panel.present()
    }

    func close() {
        panel.orderOut(nil)
    }

    @objc private func start() {
        close()
        onStart?()
    }

    @objc private func cancel() {
        close()
        onCancel?()
    }
}
