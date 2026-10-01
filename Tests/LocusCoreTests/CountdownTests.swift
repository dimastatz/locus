import LocusCore
import Testing

struct CountdownTests {
    @Test(arguments: [
        (1500.0, "25:00"),
        (1500.0000001, "25:00"),
        (1499.2, "25:00"),
        (1498.9, "24:59"),
        (59.5, "01:00"),
        (0.4, "00:01"),
        (0, "00:00"),
        (-5, "00:00"),
        (3600, "1:00:00"),
        (5400, "1:30:00"),
    ])
    func formats(seconds: Double, expected: String) {
        #expect(Countdown.format(seconds) == expected)
    }
}
