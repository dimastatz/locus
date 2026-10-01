import AppKit
import LocusCore

/// The "Focus Duration" submenu: presets with a checkmark, plus "Custom…" (PRD-0008).
final class DurationMenu: NSObject {
    private let setting: FocusDurationSetting
    private var prompt: DurationPrompt?

    init(setting: FocusDurationSetting) {
        self.setting = setting
    }

    func makeItem() -> NSMenuItem {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        for minutes in FocusDurationSetting.presetMinutes {
            let item = NSMenuItem(title: "\(minutes) min", action: #selector(choosePreset), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            item.state = setting.minutes == minutes ? .on : .off
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        let customTitle = setting.isCustom ? "Custom (\(setting.minutes) min)…" : "Custom…"
        let custom = NSMenuItem(title: customTitle, action: #selector(chooseCustom), keyEquivalent: "")
        custom.target = self
        custom.state = setting.isCustom ? .on : .off
        submenu.addItem(custom)

        let item = NSMenuItem(title: "Focus Duration", action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    @objc private func choosePreset(_ sender: NSMenuItem) {
        setting.set(minutes: sender.tag)
    }

    @objc private func chooseCustom() {
        if let prompt, prompt.isVisible {
            prompt.show()
            return
        }
        let prompt = DurationPrompt(currentMinutes: setting.minutes)
        prompt.onSave = { [weak self] minutes in
            self?.setting.set(minutes: minutes)
            self?.prompt = nil
        }
        prompt.onCancel = { [weak self] in self?.prompt = nil }
        self.prompt = prompt
        prompt.show()
    }
}

/// Asks for a custom focus duration in minutes.
private final class DurationPrompt: NSObject {
    var onSave: ((Int) -> Void)?
    var onCancel: (() -> Void)?

    private let panel = PromptPanel(width: 420)
    private let field = NSTextField()
    private let errorLabel = NSTextField(labelWithString: "")

    init(currentMinutes: Int) {
        super.init()
        let range = FocusDurationSetting.allowedMinutes

        let titleLabel = NSTextField(labelWithString: "Focus Duration")
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        let message = NSTextField(
            wrappingLabelWithString:
                "How many minutes should a focus session last? (\(range.lowerBound)–\(range.upperBound))")
        message.preferredMaxLayoutWidth = 300

        field.stringValue = "\(currentMinutes)"
        field.placeholderString = "Minutes"
        field.widthAnchor.constraint(equalToConstant: 120).isActive = true
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        let save = NSButton(title: "Save", target: self, action: #selector(save))
        save.keyEquivalent = "\r"
        panel.onCancel = { [weak self] in self?.cancel() }

        let buttons = NSStackView()
        buttons.setViews([cancel, save], in: .trailing)
        buttons.spacing = 12

        let content = NSStackView(views: [titleLabel, message, field, errorLabel, buttons])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 10
        content.setCustomSpacing(20, after: errorLabel)
        buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true

        panel.setContent(content)
    }

    var isVisible: Bool { panel.isVisible }

    func show() {
        panel.present()
        panel.makeFirstResponder(field)
    }

    @objc private func save() {
        guard let minutes = FocusDurationSetting.parse(field.stringValue) else {
            let range = FocusDurationSetting.allowedMinutes
            errorLabel.stringValue = "Enter a whole number of minutes from \(range.lowerBound) to \(range.upperBound)."
            errorLabel.isHidden = false
            return
        }
        panel.orderOut(nil)
        onSave?(minutes)
    }

    @objc private func cancel() {
        panel.orderOut(nil)
        onCancel?()
    }
}
