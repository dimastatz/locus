import Foundation

public enum Countdown {
    /// Formats remaining time as `mm:ss`, or `h:mm:ss` from one hour up.
    ///
    /// Rounds up, so a fresh 25-minute session shows `25:00` and the display
    /// only reaches `00:00` when the session is actually over.
    public static func format(_ seconds: TimeInterval) -> String {
        // Shave off a millisecond so floating-point noise (1500.0000001) doesn't round up to 25:01.
        let total = max(0, Int((seconds - 0.001).rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
