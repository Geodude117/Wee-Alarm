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
    static let testNotificationID = "wee-test"
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

    /// A one-off alarm in a minute, so people (and App Review) can check it rings on silent.
    /// It's kept separate from the real alarm, so rescheduling doesn't cancel it.
    func scheduleTest(dogName: String) {
        let previous = pending
        pending = Task { [weak self] in
            await previous?.value
            await self?.applyTest(dogName: dogName)
        }
    }

    private var testAlarmID: UUID?

    private func applyTest(dogName: String) async {
        let date = Date().addingTimeInterval(60)
        if AlarmManager.shared.authorizationState == .authorized {
            do {
                testAlarmID = try await scheduleAlarm(at: date, dogName: dogName, isTest: true)
                return
            } catch {
                print("AlarmKit test alarm failed, falling back to a notification: \(error)")
            }
        }
        await scheduleNotification(at: date, dogName: dogName, isTest: true)
    }

    private func apply(date: Date?, dogName: String) async {
        cancelAll()
        guard let date, date > Date() else { return }

        if AlarmManager.shared.authorizationState == .authorized {
            do {
                try await scheduleAlarm(at: date, dogName: dogName, isTest: false)
                return
            } catch {
                print("AlarmKit scheduling failed, falling back to a notification: \(error)")
            }
        }
        await scheduleNotification(at: date, dogName: dogName, isTest: false)
    }

    @discardableResult
    private func scheduleAlarm(at date: Date, dogName: String, isTest: Bool) async throws -> UUID {
        let base = dogName.isEmpty ? "Wee time!" : "\(dogName) needs a wee"
        let title = isTest ? "Test alarm: \(base)" : base
        let letOutButton = AlarmButton(text: "Let out",
                                       textColor: .black,
                                       systemImageName: "pawprint.fill")
        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: title),
                                            secondaryButton: letOutButton,
                                            secondaryButtonBehavior: .custom)
        let attributes = AlarmAttributes<WeeAlarmMetadata>(presentation: AlarmPresentation(alert: alert),
                                                           metadata: WeeAlarmMetadata(),
                                                           tintColor: Theme.yellow)
        let id = UUID()
        let configuration = AlarmManager.AlarmConfiguration<WeeAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: LetOutIntent(alarmID: id.uuidString),
            sound: .default
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
        return id
    }

    private func scheduleNotification(at date: Date, dogName: String, isTest: Bool) async {
        let content = UNMutableNotificationContent()
        let base = dogName.isEmpty ? "Wee time! 🐶" : "\(dogName) needs a wee 🐶"
        content.title = isTest ? "Test alarm: \(base)" : base
        content.body = "Time to let them out."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow),
                                                        repeats: false)
        let identifier = isTest ? Self.testNotificationID : Self.notificationID
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Cancels the real alarm. Leaves a pending test alarm alone.
    private func cancelAll() {
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] where alarm.id != testAlarmID {
            try? manager.cancel(id: alarm.id)
        }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.notificationID])
    }
}
