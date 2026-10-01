import Foundation

/// The app whose window is locked for the duration of a session.
public struct LockTarget: Equatable, Sendable {
    public let processID: pid_t
    public let bundleIdentifier: String?
    public let appName: String

    public init(processID: pid_t, bundleIdentifier: String?, appName: String) {
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
    }
}

/// A running focus session. Timing is based on a wall-clock end time,
/// so it stays correct across sleep/wake (PRD-0002, PRD-0004).
public struct FocusSession: Equatable, Sendable {
    public static let defaultDuration: TimeInterval = 25 * 60

    public let target: LockTarget
    public let startedAt: Date
    public let endsAt: Date

    public init(target: LockTarget, startedAt: Date, duration: TimeInterval) {
        self.target = target
        self.startedAt = startedAt
        self.endsAt = startedAt.addingTimeInterval(duration)
    }

    public var duration: TimeInterval { endsAt.timeIntervalSince(startedAt) }

    public func remaining(at now: Date) -> TimeInterval {
        max(0, endsAt.timeIntervalSince(now))
    }

    public func isComplete(at now: Date) -> Bool {
        now >= endsAt
    }
}
