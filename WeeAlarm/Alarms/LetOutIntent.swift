import AppIntents
import Foundation

/// Runs when the "Let out" button is tapped on a ringing alarm.
/// Logs the trip and sets the next alarm without opening the app.
struct LetOutIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Let the dog out"
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            DogStore.shared.letOut()
        }
        return .result()
    }
}
