import AlarmKit
import SwiftUI
import UserNotifications

/// AlarmKit needs a metadata type, even if we have nothing extra to store.
struct WeeAlarmMetadata: AlarmMetadata {}

/// Puts the next wee break on the device.
///
/// AlarmKit is the main path: a real alarm that rings through silent mode and Focus.
/// If alarms aren't allowed, it falls back to a normal local notification.
@MainActor
final class AlarmScheduler: AlarmScheduling {
    static let shared = AlarmScheduler()

    static let notificationID = "wee-reminder"
    static let categoryID = "WEE_REMINDER"
    static let letOutActionID = "LET_OUT"
    static let snoozeActionID = "SNOOZE"

    private var pending: Task<Void, Never>?

    // MARK: Permissions

    func requestPermissions() async {
        let manager = AlarmManager.shared
        if manager.authorizationState == .notDetermined {
            _ = try? await manager.requestAuthorization()
        }
        if manager.authorizationState != .authorized {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    /// True if we can alert the user in some way.
    func canAlert() async -> Bool {
        if AlarmManager.shared.authorizationState == .authorized { return true }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    static func registerNotificationCategory() {
        let letOut = UNNotificationAction(identifier: letOutActionID, title: "Let out ✓", options: [])
        let snooze = UNNotificationAction(identifier: snoozeActionID, title: "Snooze 15 min", options: [])
        let category = UNNotificationCategory(identifier: categoryID,
                                              actions: [letOut, snooze],
                                              intentIdentifiers: [],
                                              options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: Scheduling

    func reschedule(at date: Date?, dogName: String) {
        // Chain work so a quick tap-tap can't leave two alarms behind.
        let previous = pending
        pending = Task { [weak self] in
            await previous?.value
            await self?.apply(date: date, dogName: dogName)
        }
    }

    private func apply(date: Date?, dogName: String) async {
        cancelAll()
        guard let date, date > Date() else { return }

        if AlarmManager.shared.authorizationState == .authorized {
            do {
                try await scheduleAlarm(at: date, dogName: dogName)
                return
            } catch {
                print("AlarmKit scheduling failed, falling back to a notification: \(error)")
            }
        }
        await scheduleNotification(at: date, dogName: dogName)
    }

    private func scheduleAlarm(at date: Date, dogName: String) async throws {
        let title = dogName.isEmpty ? "Wee time!" : "\(dogName) needs a wee"
        let letOutButton = AlarmButton(text: "Let out",
                                       textColor: .black,
                                       systemImageName: "pawprint.fill")
        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: title),
                                            secondaryButton: letOutButton,
                                            secondaryButtonBehavior: .custom)
        let attributes = AlarmAttributes<WeeAlarmMetadata>(presentation: AlarmPresentation(alert: alert),
                                                           metadata: WeeAlarmMetadata(),
                                                           tintColor: Theme.yellow)
        let configuration = AlarmManager.AlarmConfiguration<WeeAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: LetOutIntent(),
            sound: .default
        )
        _ = try await AlarmManager.shared.schedule(id: UUID(), configuration: configuration)
    }

    private func scheduleNotification(at date: Date, dogName: String) async {
        let content = UNMutableNotificationContent()
        content.title = dogName.isEmpty ? "Wee time! 🐶" : "\(dogName) needs a wee 🐶"
        content.body = "Time to let them out."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow),
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func cancelAll() {
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] {
            try? manager.cancel(id: alarm.id)
        }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.notificationID])
    }
}
