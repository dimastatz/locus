import AppKit
import LocusCore
import UserNotifications

/// Tells the user a session has ended (PRD-0004).
final class SessionNotifier {
    /// UNUserNotificationCenter needs an app bundle; a bare `swift run` binary has none.
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier == nil ? nil : .current()
    }

    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sessionEnded(_ session: FocusSession, reason: SessionEndReason) {
        let app = session.target.appName
        let title: String
        let body: String
        switch reason {
        case .completed:
            let minutes = Int((session.duration / 60).rounded())
            title = "Focus session complete"
            body = "\(minutes) minutes of focus on \(app). The lock is released."
        case .targetTerminated:
            title = "Focus session ended"
            body = "\(app) quit, so the lock was released."
        case .unlocked:
            return
        }

        guard let center else {
            NSSound(named: "Glass")?.play()
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
