import Foundation

/// The "beep beep" played when the focus time is over (PRD-0010). Playback lives in the app target.
public struct CompletionBeep: Equatable, Sendable {
    /// A short tone that ships with macOS (`/System/Library/Sounds`).
    public static let standard = CompletionBeep(soundName: "Morse", count: 2, interval: 0.3)

    public let soundName: String
    public let count: Int
    public let interval: TimeInterval

    public init(soundName: String, count: Int, interval: TimeInterval) {
        self.soundName = soundName
        self.count = count
        self.interval = interval
    }

    /// When each beep starts, relative to the first.
    public var offsets: [TimeInterval] {
        (0..<max(count, 0)).map { TimeInterval($0) * interval }
    }

    /// Only a session that ran its full time beeps; early exits and a quit locked app don't.
    public static func plays(for reason: SessionEndReason) -> Bool {
        reason == .completed
    }
}
