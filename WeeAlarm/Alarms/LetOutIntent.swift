import AlarmKit
import AppIntents
import Foundation

/// Runs when the "Let out" button is tapped on a ringing alarm.
/// Stops the alarm, logs the trip and sets the next alarm without opening the app.
struct LetOutIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Let the dog out"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        // A custom alarm button doesn't dismiss the alarm by itself, so stop it here.
        if let id = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: id)
        }
        await MainActor.run {
            DogStore.shared.letOut()
        }
        return .result()
    }
}
