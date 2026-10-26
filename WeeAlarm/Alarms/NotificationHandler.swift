import Foundation
import UserNotifications

/// Handles the "Let out ✓" and "Snooze" buttons on the fallback notification.
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        Task { @MainActor in
            switch action {
            case AlarmScheduler.letOutActionID:
                DogStore.shared.letOut()
            case AlarmScheduler.snoozeActionID:
                DogStore.shared.snooze(minutes: 15)
            default:
                break
            }
            completionHandler()
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
