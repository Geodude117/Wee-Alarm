import SwiftUI
import UserNotifications

@main
struct WeeAlarmApp: App {
    @State private var store = DogStore.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
        AlarmScheduler.registerNotificationCategory()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .fontDesign(.rounded)
                .tint(Theme.deepYellow)
        }
    }
}
