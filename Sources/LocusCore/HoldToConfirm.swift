import Foundation

/// Progress of a press-and-hold confirmation (PRD-0005).
///
/// The hold has to be continuous: any interruption resets progress to zero
/// rather than pausing it. Time is passed in, so the logic is testable without a clock.
public struct HoldToConfirm: Equatable, Sendable {
    public static let defaultDuration: TimeInterval = 25

    public let duration: TimeInterval
    public private(set) var pressedAt: Date?

    public init(duration: TimeInterval = HoldToConfirm.defaultDuration) {
        precondition(duration > 0, "Hold duration must be positive")
        self.duration = duration
    }

    public var isHolding: Bool { pressedAt != nil }

    /// Starts a hold. Pressing again while already holding keeps the original start.
    public mutating func press(at now: Date) {
        if pressedAt == nil {
            pressedAt = now
        }
    }

    /// Ends the hold and discards all progress: release, pointer leaving the button, or focus loss.
    public mutating func reset() {
        pressedAt = nil
    }

    public func elapsed(at now: Date) -> TimeInterval {
        guard let pressedAt else { return 0 }
        return min(duration, max(0, now.timeIntervalSince(pressedAt)))
    }

    /// Progress from 0 to 1.
    public func fraction(at now: Date) -> Double {
        elapsed(at: now) / duration
    }

    public func remaining(at now: Date) -> TimeInterval {
        duration - elapsed(at: now)
    }

    public func isComplete(at now: Date) -> Bool {
        isHolding && elapsed(at: now) >= duration
    }
}
