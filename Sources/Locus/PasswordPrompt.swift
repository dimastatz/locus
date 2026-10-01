import AppKit

/// A floating password panel used both to set the unlock password and to unlock a session.
///
/// It is a non-activating panel that joins every Space, including the locked app's
/// full-screen Space. Showing it doesn't activate Locus, so the locked app stays
/// frontmost and macOS doesn't switch Spaces.
final class PasswordPrompt: NSObject, NSTextFieldDelegate {
    /// Called with the field values. Return an error message to keep the panel open, or nil to close it.
    var onSubmit: (([String]) -> String?)?
    var onClose: (() -> Void)?

    private let panel: PromptPanel
    private let fields: [NSSecureTextField]
    private let errorLabel = NSTextField(labelWithString: "")
    private var previousLengths: [Int]

    init(title: String, message: String, placeholders: [String], confirmTitle: String) {
        panel = PromptPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 10),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        fields = placeholders.map { placeholder in
            let field = NSSecureTextField()
            field.placeholderString = placeholder
            return field
        }
        previousLengths = Array(repeating: 0, count: placeholders.count)
        super.init()

        panel.title = title
        panel.level = .modalPanel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isReleasedWhenClosed = false

        let messageLabel = NSTextField(wrappingLabelWithString: message)
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancel.keyEquivalent = "\u{1b}"
        let confirm = NSButton(title: confirmTitle, target: self, action: #selector(submit))
        confirm.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, confirm])

        for field in fields {
            field.delegate = self
            field.widthAnchor.constraint(equalToConstant: 400).isActive = true
        }

        let stack = NSStackView(views: [messageLabel] + fields + [errorLabel, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(20, after: errorLabel)
        messageLabel.preferredMaxLayoutWidth = 400
        buttons.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -20).isActive = true

        panel.contentView = stack
    }

    var isVisible: Bool { panel.isVisible }

    func show() {
        panel.center()
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(fields.first)
    }

    func close() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        onClose?()
    }

    @objc private func submit() {
        guard let error = onSubmit?(fields.map(\.stringValue)) else {
            close()
            return
        }
        showError(error)
        for index in fields.indices {
            fields[index].stringValue = ""
            previousLengths[index] = 0
        }
        panel.makeFirstResponder(fields.first)
    }

    @objc private func cancel() {
        close()
    }

    private func showError(_ message: String) {
        errorLabel.stringValue = message
        errorLabel.isHidden = false
    }

    // MARK: NSTextFieldDelegate

    /// Pasting is disabled (PRD-0003): the password has to be typed. Any edit that
    /// adds more than one character at once is treated as a paste and cleared.
    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSSecureTextField,
              let index = fields.firstIndex(of: field)
        else { return }
        let length = field.stringValue.count
        if length - previousLengths[index] > 1 {
            field.stringValue = ""
            previousLengths[index] = 0
            showError("Pasting is disabled. Type the password.")
            return
        }
        previousLengths[index] = length
    }
}

private final class PromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
