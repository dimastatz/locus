import Foundation
import LocusCore
import Testing

struct FocusModeTests {
    @Test func shortcutNames() {
        #expect(FocusShortcut.turnOn.name == "Locus Focus On")
        #expect(FocusShortcut.turnOff.name == "Locus Focus Off")
    }

    @Test func findsMissingShortcuts() {
        #expect(FocusShortcut.missing(installed: []) == [.turnOn, .turnOff])
        #expect(FocusShortcut.missing(installed: ["Locus Focus On", "Other"]) == [.turnOff])
        #expect(FocusShortcut.missing(installed: ["Locus Focus Off ", "Locus Focus On"]).isEmpty)
        #expect(FocusShortcut.missing(installed: ["locus focus on", "Locus Focus Off"]) == [.turnOn])
    }

    @Test func settingIsOffByDefaultAndPersists() throws {
        let suite = "LocusTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(!FocusModeSetting(defaults: defaults).isEnabled)
        FocusModeSetting(defaults: defaults).isEnabled = true
        #expect(FocusModeSetting(defaults: defaults).isEnabled)
        FocusModeSetting(defaults: defaults).isEnabled = false
        #expect(!FocusModeSetting(defaults: defaults).isEnabled)
    }

    @Test func turnsOnAtStartAndOffAtEnd() {
        var sync = FocusModeSync()
        #expect(sync.sessionStarted(enabled: true) == .turnOn)
        #expect(sync.isOn)
        #expect(sync.sessionEnded() == .turnOff)
        #expect(!sync.isOn)
    }

    @Test func doesNothingWhenDisabled() {
        var sync = FocusModeSync()
        #expect(sync.sessionStarted(enabled: false) == nil)
        #expect(sync.sessionEnded() == nil)
    }

    @Test func turnsOffOnlyOnce() {
        var sync = FocusModeSync()
        _ = sync.sessionStarted(enabled: true)
        #expect(sync.sessionStarted(enabled: true) == nil)
        #expect(sync.sessionEnded() == .turnOff)
        #expect(sync.sessionEnded() == nil)
    }

    @Test func doesNotTurnOffAfterFailedTurnOn() {
        var sync = FocusModeSync()
        _ = sync.sessionStarted(enabled: true)
        sync.turnOnFailed()
        #expect(sync.sessionEnded() == nil)
    }
}
