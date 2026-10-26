import SwiftUI

struct RootView: View {
    @Environment(DogStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if store.profile == nil {
                OnboardingView()
                    .transition(.asymmetric(insertion: .opacity,
                                            removal: .opacity.combined(with: .scale(scale: 1.05))))
            } else {
                HomeView()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.92)),
                                            removal: .opacity))
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.25), value: store.profile == nil)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshAlarm() }
        }
    }
}
