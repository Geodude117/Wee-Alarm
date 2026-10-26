import SwiftUI

enum DogMood: Equatable {
    case happy      // plenty of time
    case curious    // used during setup
    case antsy      // getting close
    case desperate  // overdue — the potty dance
    case relieved   // just been out
}

/// A little animated dog drawn entirely in SwiftUI.
/// It blinks, wags its ears and gets more fidgety as wee time gets closer.
struct DogFace: View {
    var mood: DogMood = .happy
    var size: CGFloat = 140
    var tilt: Double = 0

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            face(t: t)
                .offset(bodyOffset(t: t))
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(tilt))
        .animation(.spring(duration: 0.5, bounce: 0.45), value: tilt)
        .animation(.spring(duration: 0.4, bounce: 0.4), value: mood)
        .accessibilityHidden(true)
    }

    // MARK: Parts

    private func face(t: Double) -> some View {
        let s = size
        let swing = sin(t * earSpeed) * earWiggle

        return ZStack {
            ear
                .rotationEffect(.degrees(20 + swing), anchor: .top)
                .offset(x: -s * 0.32, y: -s * 0.08)
            ear
                .rotationEffect(.degrees(-20 - swing), anchor: .top)
                .offset(x: s * 0.32, y: -s * 0.08)

            Circle()
                .fill(Theme.fur)
                .frame(width: s * 0.78, height: s * 0.78)

            // Eye patch
            Ellipse()
                .fill(Theme.ear.opacity(0.55))
                .frame(width: s * 0.22, height: s * 0.2)
                .offset(x: s * 0.15, y: -s * 0.07)

            // Cheeks
            HStack(spacing: s * 0.36) {
                Circle()
                    .fill(Theme.blush.opacity(mood == .desperate ? 0.6 : 0.35))
                    .frame(width: s * 0.09, height: s * 0.09)
                Circle()
                    .fill(Theme.blush.opacity(mood == .desperate ? 0.6 : 0.35))
                    .frame(width: s * 0.09, height: s * 0.09)
            }
            .offset(y: s * 0.1)

            Ellipse()
                .fill(Theme.muzzle)
                .frame(width: s * 0.46, height: s * 0.32)
                .offset(y: s * 0.16)

            eyes(blinking: isBlinking(t))
                .offset(y: -s * 0.06)

            Ellipse()
                .fill(Theme.ink)
                .frame(width: s * 0.15, height: s * 0.1)
                .offset(y: s * 0.07)

            mouth
                .offset(y: s * 0.19)

            if mood == .desperate {
                sweatDrop(t: t)
            }
        }
    }

    private var ear: some View {
        Ellipse()
            .fill(Theme.ear)
            .frame(width: size * 0.24, height: size * 0.42)
    }

    @ViewBuilder
    private func eyes(blinking: Bool) -> some View {
        let s = size
        if mood == .relieved {
            // Happy closed eyes: ^ ^
            HStack(spacing: s * 0.18) {
                Smile(curve: -1)
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                    .frame(width: s * 0.11, height: s * 0.05)
                Smile(curve: -1)
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                    .frame(width: s * 0.11, height: s * 0.05)
            }
        } else {
            let d = mood == .desperate ? s * 0.115 : s * 0.085
            HStack(spacing: s * 0.2) {
                eye(diameter: d, blinking: blinking)
                eye(diameter: d, blinking: blinking)
            }
        }
    }

    private func eye(diameter d: CGFloat, blinking: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(Theme.ink)
                .frame(width: d, height: blinking ? d * 0.15 : d)
            Circle()
                .fill(Color.white)
                .frame(width: d * 0.35, height: d * 0.35)
                .offset(x: d * 0.17, y: -d * 0.17)
                .opacity(blinking ? 0 : 1)
        }
        .frame(width: d, height: d)
    }

    private var mouth: some View {
        let s = size
        return ZStack(alignment: .top) {
            if mood == .relieved {
                Capsule()
                    .fill(Theme.tongue)
                    .frame(width: s * 0.09, height: s * 0.12)
                    .offset(y: s * 0.04)
                    .transition(.scale(scale: 0.1, anchor: .top))
            }
            Smile(curve: mouthCurve)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
                .frame(width: s * 0.2, height: s * 0.08)
        }
    }

    private func sweatDrop(t: Double) -> some View {
        let fall = (t * 0.9).truncatingRemainder(dividingBy: 1)
        return Image(systemName: "drop.fill")
            .font(.system(size: size * 0.12))
            .foregroundStyle(Theme.sweat)
            .offset(x: size * 0.36, y: -size * 0.28 + fall * size * 0.18)
            .opacity(1 - fall)
    }

    // MARK: Behaviour per mood

    private var mouthCurve: CGFloat {
        switch mood {
        case .happy: return 1
        case .curious: return 0.6
        case .antsy: return 0.15
        case .desperate: return -0.7
        case .relieved: return 1.3
        }
    }

    private var earWiggle: Double {
        switch mood {
        case .happy: return 3
        case .curious: return 6
        case .antsy: return 9
        case .desperate: return 16
        case .relieved: return 12
        }
    }

    private var earSpeed: Double {
        switch mood {
        case .happy: return 1.5
        case .curious: return 3
        case .antsy: return 8
        case .desperate: return 14
        case .relieved: return 10
        }
    }

    private func isBlinking(_ t: Double) -> Bool {
        guard mood != .desperate else { return false }
        return t.truncatingRemainder(dividingBy: 4.2) < 0.14
    }

    private func bodyOffset(t: Double) -> CGSize {
        let s = Double(size)
        switch mood {
        case .happy, .curious:
            return CGSize(width: 0, height: sin(t * 2) * s * 0.015)
        case .antsy:
            return CGSize(width: sin(t * 14) * s * 0.02, height: sin(t * 2.5) * s * 0.015)
        case .desperate:
            return CGSize(width: sin(t * 22) * s * 0.015, height: -abs(sin(t * 7)) * s * 0.08)
        case .relieved:
            return CGSize(width: 0, height: -abs(sin(t * 5)) * s * 0.05)
        }
    }
}

/// A curved line: positive curve smiles, negative curve frowns.
struct Smile: Shape {
    var curve: CGFloat

    var animatableData: CGFloat {
        get { curve }
        set { curve = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                          control: CGPoint(x: rect.midX, y: rect.midY + rect.height * curve))
        return path
    }
}

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            DogFace(mood: .happy, size: 100)
            DogFace(mood: .antsy, size: 100)
        }
        HStack(spacing: 20) {
            DogFace(mood: .desperate, size: 100)
            DogFace(mood: .relieved, size: 100)
        }
    }
}
