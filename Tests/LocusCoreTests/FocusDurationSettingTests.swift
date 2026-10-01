import Foundation
import LocusCore
import Testing

struct FocusDurationSettingTests {
    /// Runs `body` with a throwaway defaults domain that is deleted afterwards,
    /// so tests never touch or leave behind real settings.
    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suite = "LocusTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @Test func defaultsTo25Minutes() throws {
        try withDefaults { defaults in
            let setting = FocusDurationSetting(defaults: defaults)
            #expect(setting.minutes == 25)
            #expect(setting.duration == 25 * 60)
            #expect(!setting.isCustom)
        }
    }

    @Test func storesPresetAndCustomDurations() throws {
        try withDefaults { defaults in
            let setting = FocusDurationSetting(defaults: defaults)
            #expect(setting.set(minutes: 50))
            #expect(setting.minutes == 50)
            #expect(setting.duration == 3000)
            #expect(setting.isCustom)

            setting.set(minutes: 90)
            #expect(setting.minutes == 90)
            #expect(!setting.isCustom)
        }
    }

    @Test(arguments: [0, 4, 241, -10])
    func rejectsOutOfRangeDuration(minutes: Int) throws {
        try withDefaults { defaults in
            let setting = FocusDurationSetting(defaults: defaults)
            setting.set(minutes: 45)
            #expect(!setting.set(minutes: minutes))
            #expect(setting.minutes == 45)
        }
    }

    @Test func acceptsRangeBounds() throws {
        try withDefaults { defaults in
            let setting = FocusDurationSetting(defaults: defaults)
            #expect(setting.set(minutes: 5))
            #expect(setting.minutes == 5)
            #expect(setting.set(minutes: 240))
            #expect(setting.minutes == 240)
        }
    }

    @Test func persistsAcrossInstances() throws {
        try withDefaults { defaults in
            FocusDurationSetting(defaults: defaults).set(minutes: 60)
            #expect(FocusDurationSetting(defaults: defaults).minutes == 60)
        }
    }

    @Test func ignoresInvalidStoredValue() throws {
        try withDefaults { defaults in
            defaults.set(9999, forKey: "focusDurationMinutes")
            #expect(FocusDurationSetting(defaults: defaults).minutes == 25)
        }
    }

    @Test(
        arguments: [
            ("50", 50), (" 50 ", 50), ("50 min", 50), ("50min", 50), ("50 minutes", 50),
            ("5", 5), ("240", 240), ("1 minute", nil), ("4", nil), ("241", nil),
            ("", nil), ("abc", nil), ("2.5", nil), ("-30", nil),
        ] as [(String, Int?)])
    func parsesUserInput(text: String, expected: Int?) {
        #expect(FocusDurationSetting.parse(text) == expected)
    }

    @Test func presetsAreAllowed() {
        for preset in FocusDurationSetting.presetMinutes {
            #expect(FocusDurationSetting.allowedMinutes.contains(preset))
        }
        #expect(FocusDurationSetting.presetMinutes.contains(FocusDurationSetting.defaultMinutes))
    }
}
