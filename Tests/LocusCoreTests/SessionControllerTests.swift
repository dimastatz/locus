import Foundation
import LocusCore
import Testing

struct SessionControllerTests {
    @Test func startRequiresPassword() {
        let controller = SessionController(vault: PasswordVault(store: InMemorySecretStore()))
        #expect(throws: SessionError.passwordNotSet) {
            try controller.start(target: xcode, now: start)
        }
        #expect(!controller.isActive)
    }

    @Test func startUsesDefaultDuration() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        let session = try controller.start(target: xcode, now: start)
        #expect(session.duration == FocusSession.defaultDuration)
        #expect(controller.session == session)
    }

    @Test func cannotStartTwice() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        try controller.start(target: xcode, now: start)
        #expect(throws: SessionError.alreadyActive) {
            try controller.start(target: xcode, now: start)
        }
    }

    @Test func rejectsNonPositiveDuration() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        #expect(throws: SessionError.invalidDuration) {
            try controller.start(target: xcode, duration: 0, now: start)
        }
    }

    @Test func tickCompletesSessionAtEndTime() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        let session = try controller.start(target: xcode, duration: 60, now: start)

        #expect(controller.tick(now: start.addingTimeInterval(59)) == nil)
        #expect(controller.isActive)

        #expect(controller.tick(now: start.addingTimeInterval(60)) == session)
        #expect(!controller.isActive)
    }

    @Test func tickAfterSleepCompletesImmediately() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        try controller.start(target: xcode, duration: 60, now: start)
        #expect(controller.tick(now: start.addingTimeInterval(3600)) != nil)
    }

    @Test func wrongPasswordKeepsSessionLocked() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        try controller.start(target: xcode, now: start)
        #expect(controller.unlock(password: "nope") == .wrongPassword)
        #expect(controller.isActive)
    }

    @Test func correctPasswordEndsSession() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        let session = try controller.start(target: xcode, now: start)
        #expect(controller.unlock(password: longPassword) == .unlocked(session))
        #expect(!controller.isActive)
    }

    @Test func unlockWithoutSession() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        #expect(controller.unlock(password: longPassword) == .noActiveSession)
    }

    @Test func terminationOfLockedAppEndsSession() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        let session = try controller.start(target: xcode, now: start)

        #expect(controller.targetDidTerminate(processID: 7) == nil)
        #expect(controller.isActive)

        #expect(controller.targetDidTerminate(processID: xcode.processID) == session)
        #expect(!controller.isActive)
    }

    @Test func reclaimsFocusFromOtherAppsOnly() throws {
        let controller = SessionController(vault: try vaultWithPassword())
        let own: pid_t = 1
        #expect(!controller.shouldReclaimFocus(activatedProcessID: 99, ownProcessID: own))

        try controller.start(target: xcode, now: start)
        #expect(controller.shouldReclaimFocus(activatedProcessID: 99, ownProcessID: own))
        #expect(!controller.shouldReclaimFocus(activatedProcessID: xcode.processID, ownProcessID: own))
        #expect(!controller.shouldReclaimFocus(activatedProcessID: own, ownProcessID: own))
    }
}
