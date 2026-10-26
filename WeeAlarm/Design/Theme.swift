import SwiftUI

enum Theme {
    static let yellow = Color(red: 1.00, green: 0.80, blue: 0.20)
    static let deepYellow = Color(red: 0.96, green: 0.64, blue: 0.08)

    // Dog colours
    static let fur = Color(red: 0.88, green: 0.66, blue: 0.42)
    static let ear = Color(red: 0.56, green: 0.36, blue: 0.22)
    static let muzzle = Color(red: 0.99, green: 0.93, blue: 0.84)
    static let ink = Color(red: 0.13, green: 0.11, blue: 0.10)
    static let tongue = Color(red: 0.98, green: 0.47, blue: 0.55)
    static let blush = Color(red: 1.00, green: 0.55, blue: 0.55)
    static let sweat = Color(red: 0.45, green: 0.76, blue: 1.00)
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// The big yellow, squishy button used across the app.
struct BigButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(20, .bold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Capsule().fill(Theme.yellow))
            .shadow(color: Theme.deepYellow.opacity(isEnabled ? 0.35 : 0),
                    radius: configuration.isPressed ? 4 : 12,
                    y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.spring(duration: 0.25, bounce: 0.5), value: configuration.isPressed)
    }
}

enum ClockFormat {
    /// "2:14:05" or "14:05"
    static func text(seconds: Int) -> String {
        let seconds = max(0, seconds)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
