import Foundation

public enum SessionError: Error, Equatable {
    case alreadyActive
    case invalidDuration
}

public enum SessionEndReason: Equatable, Sendable {
    /// The timer ran out (PRD-0004).
    case completed
    /// The user held Exit to end the session early (PRD-0005).
    case exitedEarly
    /// The locked app quit or crashed, so there is nothing left to lock.
    case targetTerminated
}

/// Owns the session lifecycle: idle → active → idle. Holds no UI or AppKit state.
public final class SessionController {
    public private(set) var session: FocusSession?

    public init() {}

    public var isActive: Bool { session != nil }

    @discardableResult
    public func start(
        target: LockTarget,
        duration: TimeInterval = FocusSession.defaultDuration,
        now: Date
    ) throws -> FocusSession {
        guard session == nil else { throw SessionError.alreadyActive }
        guard duration > 0 else { throw SessionError.invalidDuration }
        let started = FocusSession(target: target, startedAt: now, duration: duration)
        session = started
        return started
    }

    /// Advances the clock. Returns the session if it completed at `now`.
    public func tick(now: Date) -> FocusSession? {
        guard let current = session, current.isComplete(at: now) else { return nil }
        session = nil
        return current
    }

    /// Ends the session early. The caller confirms the exit first (hold to exit, PRD-0005).
    public func exitEarly() -> FocusSession? {
        defer { session = nil }
        return session
    }

    /// Ends the session if `processID` is the locked app. Returns the ended session.
    public func targetDidTerminate(processID: pid_t) -> FocusSession? {
        guard let current = session, current.target.processID == processID else { return nil }
        session = nil
        return current
    }

    /// Whether activating `activatedProcessID` counts as leaving the locked app.
    /// Locus itself is exempt, since it shows the exit dialog.
    public func shouldReclaimFocus(activatedProcessID: pid_t, ownProcessID: pid_t) -> Bool {
        guard let current = session else { return false }
        return activatedProcessID != current.target.processID && activatedProcessID != ownProcessID
    }
}
