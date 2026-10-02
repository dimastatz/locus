import Foundation

/// The two Shortcuts that turn macOS Focus on and off (PRD-0011). macOS has no public API
/// to change Focus, so Locus runs shortcuts the user creates with the Set Focus action.
public enum FocusShortcut: String, CaseIterable, Sendable {
    case turnOn = "Locus Focus On"
    case turnOff = "Locus Focus Off"

    public var name: String { rawValue }

    /// The shortcuts not in `installed`, a list of shortcut names (as `shortcuts list` prints them).
    public static func missing(installed: [String]) -> [FocusShortcut] {
        let names = Set(installed.map { $0.trimmingCharacters(in: .whitespaces) })
        return allCases.filter { !names.contains($0.name) }
    }
}

/// Whether to turn on Do Not Disturb during sessions (PRD-0011). Off by default.
public final class FocusModeSetting {
    private static let key = "turnOnFocusDuringSessions"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var isEnabled: Bool {
        get { defaults.bool(forKey: Self.key) }
        set { defaults.set(newValue, forKey: Self.key) }
    }
}

/// Decides when to run the Focus shortcuts, so Locus only turns off a Focus it turned on.
public struct FocusModeSync: Equatable, Sendable {
    /// Whether Locus turned Focus on and hasn't turned it off yet.
    public private(set) var isOn = false

    public init() {}

    /// The shortcut to run when a session starts, if any.
    public mutating func sessionStarted(enabled: Bool) -> FocusShortcut? {
        guard enabled, !isOn else { return nil }
        isOn = true
        return .turnOn
    }

    /// The turn-on shortcut failed, so there is nothing to turn off later.
    public mutating func turnOnFailed() {
        isOn = false
    }

    /// The shortcut to run when a session ends (however it ends) or Locus quits, if any.
    public mutating func sessionEnded() -> FocusShortcut? {
        guard isOn else { return nil }
        isOn = false
        return .turnOff
    }
}
