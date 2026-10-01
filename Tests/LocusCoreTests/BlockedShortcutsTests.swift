import LocusCore
import Testing

private let escapeShortcuts: [(UInt16, KeyModifiers)] = [
    (0x0C, .command),  // ⌘Q
    (0x04, .command),  // ⌘H
    (0x2E, .command),  // ⌘M
    (0x03, [.command, .control]),  // ⌃⌘F
    (0x30, .command),  // ⌘Tab
    (0x30, [.command, .shift]),  // ⇧⌘Tab
    (0x7B, .control),  // ⌃←
    (0x7E, .control),  // ⌃↑
]

private let everydayShortcuts: [(UInt16, KeyModifiers)] = [
    (0x0C, []),  // plain Q while typing
    (0x03, .command),  // ⌘F (Find)
    (0x0D, .command),  // ⌘W (close tab)
    (0x30, []),  // Tab
    (0x7B, []),  // ←
    (0x7B, .option),  // ⌥← (word left)
]

struct BlockedShortcutsTests {
    @Test(arguments: escapeShortcuts)
    func blocksEscapeShortcuts(keyCode: UInt16, modifiers: KeyModifiers) {
        #expect(BlockedShortcuts.isBlocked(keyCode: keyCode, modifiers: modifiers))
    }

    @Test(arguments: everydayShortcuts)
    func allowsEverydayShortcuts(keyCode: UInt16, modifiers: KeyModifiers) {
        #expect(!BlockedShortcuts.isBlocked(keyCode: keyCode, modifiers: modifiers))
    }
}
