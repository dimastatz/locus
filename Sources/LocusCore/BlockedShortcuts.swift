public struct KeyModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let command = KeyModifiers(rawValue: 1 << 0)
    public static let control = KeyModifiers(rawValue: 1 << 1)
    public static let option = KeyModifiers(rawValue: 1 << 2)
    public static let shift = KeyModifiers(rawValue: 1 << 3)
}

public struct KeyChord: Hashable, Sendable {
    public let keyCode: UInt16
    public let modifiers: KeyModifiers

    public init(_ keyCode: UInt16, _ modifiers: KeyModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

/// Shortcuts that would take the user out of the locked window (PRD-0003).
/// They are swallowed during a session and trigger the unlock prompt instead.
///
/// Key codes are physical positions (`kVK_*` from Carbon's Events.h).
public enum BlockedShortcuts {
    private enum Key {
        static let q: UInt16 = 0x0C
        static let h: UInt16 = 0x04
        static let m: UInt16 = 0x2E
        static let f: UInt16 = 0x03
        static let tab: UInt16 = 0x30
        static let leftArrow: UInt16 = 0x7B
        static let rightArrow: UInt16 = 0x7C
        static let downArrow: UInt16 = 0x7D
        static let upArrow: UInt16 = 0x7E
    }

    public static let chords: Set<KeyChord> = [
        KeyChord(Key.q, .command),                   // Quit
        KeyChord(Key.h, .command),                   // Hide
        KeyChord(Key.m, .command),                   // Minimize
        KeyChord(Key.m, [.command, .option]),        // Minimize all
        KeyChord(Key.f, [.command, .control]),       // Toggle full screen
        KeyChord(Key.tab, .command),                 // App switcher
        KeyChord(Key.tab, [.command, .shift]),       // App switcher, reversed
        KeyChord(Key.leftArrow, .control),           // Previous Space
        KeyChord(Key.rightArrow, .control),          // Next Space
        KeyChord(Key.upArrow, .control),             // Mission Control
        KeyChord(Key.downArrow, .control),           // App Exposé
    ]

    public static func isBlocked(keyCode: UInt16, modifiers: KeyModifiers) -> Bool {
        chords.contains(KeyChord(keyCode, modifiers))
    }
}
