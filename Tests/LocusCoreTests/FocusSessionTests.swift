import Foundation
import LocusCore
import Testing

struct FocusSessionTests {
    @Test func defaultDurationIs25Minutes() {
        #expect(FocusSession.defaultDuration == 25 * 60)
    }

    @Test func remainingCountsDownToZero() {
        let session = FocusSession(target: xcode, startedAt: start, duration: 1500)
        #expect(session.remaining(at: start) == 1500)
        #expect(session.remaining(at: start.addingTimeInterval(300)) == 1200)
        #expect(session.remaining(at: start.addingTimeInterval(9999)) == 0)
    }

    @Test func completesAtEndTime() {
        let session = FocusSession(target: xcode, startedAt: start, duration: 1500)
        #expect(!session.isComplete(at: start.addingTimeInterval(1499)))
        #expect(session.isComplete(at: start.addingTimeInterval(1500)))
    }
}
