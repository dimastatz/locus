import Foundation
import LocusCore
import Testing

struct SessionControllerTests {

    @Test func startUsesDefaultDuration() throws {
        let controller = SessionController()
        let session = try controller.start(target: xcode, now: start)
        #expect(session.duration == FocusSession.defaultDuration)
        #expect(controller.session == session)
    }

    @Test func cannotStartTwice() throws {
        let controller = SessionController()
        try controller.start(target: xcode, now: start)
        #expect(throws: SessionError.alreadyActive) {
            try controller.start(target: xcode, now: start)
        }
    }

    @Test func rejectsNonPositiveDuration() throws {
        let controller = SessionController()
        #expect(throws: SessionError.invalidDuration) {
            try controller.start(target: xcode, duration: 0, now: start)
        }
    }

    @Test func tickCompletesSessionAtEndTime() throws {
        let controller = SessionController()
        let session = try controller.start(target: xcode, duration: 60, now: start)

        #expect(controller.tick(now: start.addingTimeInterval(59)) == nil)
        #expect(controller.isActive)

        #expect(controller.tick(now: start.addingTimeInterval(60)) == session)
        #expect(!controller.isActive)
    }

    @Test func exitEarlyEndsSession() throws {
        let controller = SessionController()
        let session = try controller.start(target: xcode, now: start)
        #expect(controller.exitEarly() == session)
        #expect(!controller.isActive)
    }

    @Test func exitEarlyWithoutSession() {
        #expect(SessionController().exitEarly() == nil)
    }

    @Test func tickAfterSleepCompletesImmediately() throws {
        let controller = SessionController()
        try controller.start(target: xcode, duration: 60, now: start)
        #expect(controller.tick(now: start.addingTimeInterval(3600)) != nil)
    }

    @Test func terminationOfLockedAppEndsSession() throws {
        let controller = SessionController()
        let session = try controller.start(target: xcode, now: start)

        #expect(controller.targetDidTerminate(processID: 7) == nil)
        #expect(controller.isActive)

        #expect(controller.targetDidTerminate(processID: xcode.processID) == session)
        #expect(!controller.isActive)
    }

    @Test func reclaimsFocusFromOtherAppsOnly() throws {
        let controller = SessionController()
        let own: pid_t = 1
        #expect(!controller.shouldReclaimFocus(activatedProcessID: 99, ownProcessID: own))

        try controller.start(target: xcode, now: start)
        #expect(controller.shouldReclaimFocus(activatedProcessID: 99, ownProcessID: own))
        #expect(!controller.shouldReclaimFocus(activatedProcessID: xcode.processID, ownProcessID: own))
        #expect(!controller.shouldReclaimFocus(activatedProcessID: own, ownProcessID: own))
    }
}
