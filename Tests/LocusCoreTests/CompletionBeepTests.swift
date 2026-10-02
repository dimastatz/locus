import LocusCore
import Testing

struct CompletionBeepTests {
    @Test func standardIsTwoShortBeeps() {
        let beep = CompletionBeep.standard
        #expect(beep.soundName == "Morse")
        #expect(beep.offsets == [0, 0.3])
    }

    @Test func offsetsAreSpacedByInterval() {
        #expect(CompletionBeep(soundName: "Tink", count: 3, interval: 0.5).offsets == [0, 0.5, 1])
        #expect(CompletionBeep(soundName: "Tink", count: 0, interval: 0.5).offsets.isEmpty)
        #expect(CompletionBeep(soundName: "Tink", count: -1, interval: 0.5).offsets.isEmpty)
    }

    @Test func beepsOnlyWhenTheTimerRunsOut() {
        #expect(CompletionBeep.plays(for: .completed))
        #expect(!CompletionBeep.plays(for: .exitedEarly))
        #expect(!CompletionBeep.plays(for: .targetTerminated))
    }
}
