import Foundation

/// The user's chosen focus-session length (PRD-0008), persisted in `UserDefaults`.
public final class FocusDurationSetting {
    public static let defaultMinutes = Int(FocusSession.defaultDuration / 60)
    /// Offered in the menu; any other value in `allowedMinutes` is a custom duration.
    public static let presetMinutes = [15, 25, 45, 60, 90]
    public static let allowedMinutes = 5...240

    private static let key = "focusDurationMinutes"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The stored duration, or the default if nothing valid is stored.
    public var minutes: Int {
        let stored = defaults.integer(forKey: Self.key)
        return Self.allowedMinutes.contains(stored) ? stored : Self.defaultMinutes
    }

    public var duration: TimeInterval { TimeInterval(minutes * 60) }

    public var isCustom: Bool { !Self.presetMinutes.contains(minutes) }

    /// Stores `minutes` if it's in `allowedMinutes`. Returns whether it was stored.
    @discardableResult
    public func set(minutes: Int) -> Bool {
        guard Self.allowedMinutes.contains(minutes) else { return false }
        defaults.set(minutes, forKey: Self.key)
        return true
    }

    /// Parses user input like "50" or " 50 min" into whole minutes within `allowedMinutes`.
    public static func parse(_ text: String) -> Int? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for suffix in ["minutes", "minute", "mins", "min", "m"] where trimmed.hasSuffix(suffix) {
            trimmed = String(trimmed.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            break
        }
        guard let minutes = Int(trimmed), allowedMinutes.contains(minutes) else { return nil }
        return minutes
    }
}
