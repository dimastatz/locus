import Foundation

public enum SessionError: Error, Equatable {
    case alreadyActive
    case invalidDuration
    /// A session can't start until there is a password to end it early with.
    case passwordNotSet
}

public enum SessionEndReason: Equatable, Sendable {
    /// The timer ran out (PRD-0004).
    case completed
    /// The user typed the unlock password (PRD-0003).
    case unlocked
    /// The locked app quit or crashed, so there is nothing left to lock.
    case targetTerminated
}

public enum UnlockResult: Equatable {
    case unlocked(FocusSession)
    case wrongPassword
    case noActiveSession
}

/// Owns the session lifecycle: idle → active → idle. Holds no UI or AppKit state.
public final class SessionController {
    public private(set) var session: FocusSession?
    private let vault: PasswordVault

    public init(vault: PasswordVault) {
        self.vault = vault
    }

    public var isActive: Bool { session != nil }

    @discardableResult
    public func start(
        target: LockTarget,
        duration: TimeInterval = FocusSession.defaultDuration,
        now: Date
    ) throws -> FocusSession {
        guard session == nil else { throw SessionError.alreadyActive }
        guard duration > 0 else { throw SessionError.invalidDuration }
        guard vault.hasPassword else { throw SessionError.passwordNotSet }
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

    public func unlock(password: String) -> UnlockResult {
        guard let current = session else { return .noActiveSession }
        guard vault.verify(password) else { return .wrongPassword }
        session = nil
        return .unlocked(current)
    }

    /// Ends the session if `processID` is the locked app. Returns the ended session.
    public func targetDidTerminate(processID: pid_t) -> FocusSession? {
        guard let current = session, current.target.processID == processID else { return nil }
        session = nil
        return current
    }

    /// Whether activating `activatedProcessID` counts as leaving the locked app.
    /// Locus itself is exempt, since it shows the unlock prompt.
    public func shouldReclaimFocus(activatedProcessID: pid_t, ownProcessID: pid_t) -> Bool {
        guard let current = session else { return false }
        return activatedProcessID != current.target.processID && activatedProcessID != ownProcessID
    }
}
