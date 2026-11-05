import AlarmKit
import SwiftUI

/// AlarmKit needs a metadata type, even if we have nothing extra to store.
@available(iOS 26.1, *)
struct WeeAlarmMetadata: AlarmMetadata {}

/// Real alarms that ring through silent mode and Focus. iOS 26.1 and later only.
/// Everything AlarmKit-specific lives here so the rest of the app runs on iOS 17.
@available(iOS 26.1, *)
@MainActor
enum AlarmKitBackend {
    static var isDenied: Bool {
        AlarmManager.shared.authorizationState == .denied
    }

    static var isAuthorized: Bool {
        AlarmManager.shared.authorizationState == .authorized
    }

    /// Asks for alarm permission if it hasn't been asked yet. Returns true if allowed.
    static func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        var state = manager.authorizationState
        print("[WeeAlarm] AlarmKit authorization before request: \(state)")
        if state == .notDetermined {
            do {
                state = try await manager.requestAuthorization()
                print("[WeeAlarm] AlarmKit authorization result: \(state)")
            } catch {
                print("[WeeAlarm] AlarmKit authorization request failed: \(error)")
            }
        }
        return state == .authorized || manager.authorizationState == .authorized
    }

    static func schedule(at date: Date, title: String) async throws -> UUID {
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

    /// Cancels every scheduled alarm except `keeping` (the pending test alarm).
    static func cancelAll(keeping: UUID?) {
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] where alarm.id != keeping {
            try? manager.cancel(id: alarm.id)
        }
    }

    static func stop(id: UUID) {
        try? AlarmManager.shared.stop(id: id)
    }
}
