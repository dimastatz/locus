import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Menu bar only: no Dock icon, no ⌘Tab entry (PRD-0001). The bundle also sets LSUIElement.
app.setActivationPolicy(.accessory)
app.run()
