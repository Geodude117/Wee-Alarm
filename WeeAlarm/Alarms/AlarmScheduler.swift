import SwiftUI
import UserNotifications

/// Puts the next wee break on the device.
///
/// On iOS 26.1 and later the main path is AlarmKit: a real alarm that rings through
/// silent mode and Focus. On older iOS, or if alarms aren't allowed, it falls back
/// to a time-sensitive local notification.
@MainActor
final class AlarmScheduler: AlarmScheduling {
    static let shared = AlarmScheduler()

    static let notificationID = "wee-reminder"
    static let testNotificationID = "wee-test"
    static let categoryID = "WEE_REMINDER"
    static let letOutActionID = "LET_OUT"
    static let snoozeActionID = "SNOOZE"

    private var pending: Task<Void, Never>?
    private var testAlarmID: UUID?

    /// True when this iPhone can use real alarms (iOS 26.1+). Used for wording in the UI.
    static var supportsRealAlarms: Bool {
        if #available(iOS 26.1, *) { return true }
        return false
    }

    // MARK: Permissions

    func requestPermissions() async {
        if #available(iOS 26.1, *) {
            if await AlarmKitBackend.requestAuthorization() { return }
        }
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// True if we can alert the user in some way.
    func canAlert() async -> Bool {
        if #available(iOS 26.1, *), AlarmKitBackend.isAuthorized { return true }
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

    /// A one-off alarm in a minute, so people (and App Review) can check it rings.
    /// It's kept separate from the real alarm, so rescheduling doesn't cancel it.
    func scheduleTest(dogName: String) {
        let previous = pending
        pending = Task { [weak self] in
            await previous?.value
            await self?.applyTest(dogName: dogName)
        }
    }

    private func applyTest(dogName: String) async {
        let date = Date().addingTimeInterval(60)
        if let id = await tryAlarmKit(at: date, dogName: dogName, isTest: true) {
            testAlarmID = id
            return
        }
        await scheduleNotification(at: date, dogName: dogName, isTest: true)
    }

    private func apply(date: Date?, dogName: String) async {
        cancelAll()
        guard let date, date > Date() else { return }
        if await tryAlarmKit(at: date, dogName: dogName, isTest: false) != nil { return }
        await scheduleNotification(at: date, dogName: dogName, isTest: false)
    }

    /// Schedules a real alarm when the OS supports it and alarms aren't turned off.
    /// If permission hasn't been asked yet, scheduling makes iOS show the prompt itself.
    /// Returns nil when the notification fallback should be used instead.
    private func tryAlarmKit(at date: Date, dogName: String, isTest: Bool) async -> UUID? {
        guard #available(iOS 26.1, *), !AlarmKitBackend.isDenied else { return nil }
        do {
            return try await AlarmKitBackend.schedule(at: date, title: Self.title(dogName: dogName, isTest: isTest))
        } catch {
            print("[WeeAlarm] AlarmKit scheduling failed, falling back to a notification: \(error)")
            return nil
        }
    }

    private static func title(dogName: String, isTest: Bool) -> String {
        let base = dogName.isEmpty ? "Wee time!" : "\(dogName) needs a wee"
        return isTest ? "Test alarm: \(base)" : base
    }

    private func scheduleNotification(at date: Date, dogName: String, isTest: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = Self.title(dogName: dogName, isTest: isTest) + " 🐶"
        content.body = "Time to let them out."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        // Breaks through Focus (with the Time Sensitive Notifications capability).
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow),
                                                        repeats: false)
        let identifier = isTest ? Self.testNotificationID : Self.notificationID
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Cancels the real alarm. Leaves a pending test alarm alone.
    private func cancelAll() {
        if #available(iOS 26.1, *) {
            AlarmKitBackend.cancelAll(keeping: testAlarmID)
        }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.notificationID])
    }
}
