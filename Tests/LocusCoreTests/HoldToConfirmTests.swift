import Foundation
import LocusCore
import Testing

struct HoldToConfirmTests {
    @Test func defaultDurationIs25Seconds() {
        #expect(HoldToConfirm.defaultDuration == 25)
        #expect(HoldToConfirm().duration == 25)
    }

    @Test func noProgressBeforePress() {
        let hold = HoldToConfirm()
        #expect(!hold.isHolding)
        #expect(hold.elapsed(at: start) == 0)
        #expect(hold.fraction(at: start) == 0)
        #expect(hold.remaining(at: start) == 25)
        #expect(!hold.isComplete(at: start.addingTimeInterval(100)))
    }

    @Test func progressesWhileHeld() {
        var hold = HoldToConfirm()
        hold.press(at: start)
        let later = start.addingTimeInterval(10)
        #expect(hold.isHolding)
        #expect(hold.elapsed(at: later) == 10)
        #expect(hold.fraction(at: later) == 0.4)
        #expect(hold.remaining(at: later) == 15)
    }

    @Test func completesOnlyAfterFullDuration() {
        var hold = HoldToConfirm()
        hold.press(at: start)
        #expect(!hold.isComplete(at: start.addingTimeInterval(24.9)))
        #expect(hold.isComplete(at: start.addingTimeInterval(25)))
    }

    @Test func clampsProgress() {
        var hold = HoldToConfirm()
        hold.press(at: start)
        #expect(hold.fraction(at: start.addingTimeInterval(60)) == 1)
        #expect(hold.remaining(at: start.addingTimeInterval(60)) == 0)
        #expect(hold.elapsed(at: start.addingTimeInterval(-5)) == 0)
    }

    @Test func releasingResetsInsteadOfPausing() {
        var hold = HoldToConfirm()
        hold.press(at: start)
        hold.reset()
        #expect(!hold.isHolding)
        #expect(hold.elapsed(at: start.addingTimeInterval(24)) == 0)

        // A new press starts over from zero.
        hold.press(at: start.addingTimeInterval(24))
        #expect(!hold.isComplete(at: start.addingTimeInterval(25)))
        #expect(hold.isComplete(at: start.addingTimeInterval(49)))
    }

    @Test func repeatedPressKeepsOriginalStart() {
        var hold = HoldToConfirm()
        hold.press(at: start)
        hold.press(at: start.addingTimeInterval(20))
        #expect(hold.isComplete(at: start.addingTimeInterval(25)))
    }

    @Test func supportsCustomDuration() {
        var hold = HoldToConfirm(duration: 60)
        hold.press(at: start)
        #expect(!hold.isComplete(at: start.addingTimeInterval(59)))
        #expect(hold.isComplete(at: start.addingTimeInterval(60)))
    }
}
