import SwiftUI

/// A circle that fills up with a wobbling yellow liquid as wee time approaches.
/// Waves get choppier the more urgent it is, and the whole thing jiggles when overdue.
struct BladderView: View {
    /// 0 = just been out, 1 = due now.
    var level: Double
    var overdue: Bool

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let urgency = overdue ? 1 : level
            let speed = 1.2 + urgency * 3
            let amplitude = 4 + urgency * 6 + (overdue ? 4 : 0)

            ZStack {
                Circle()
                    .fill(Theme.yellow.opacity(0.12))
                Wave(level: shownLevel, phase: t * speed + 1.7, amplitude: amplitude * 0.8)
                    .fill(Theme.yellow.opacity(0.45))
                Wave(level: shownLevel, phase: t * speed * 1.25, amplitude: amplitude)
                    .fill(LinearGradient(colors: [Theme.yellow, Theme.deepYellow],
                                         startPoint: .top,
                                         endPoint: .bottom))
                bubbles(t: t)
            }
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Theme.yellow, lineWidth: 5))
            .rotationEffect(.degrees(overdue ? sin(t * 18) * 2.5 : 0))
            .scaleEffect(overdue ? 1 + sin(t * 6) * 0.015 : 1)
        }
        .accessibilityHidden(true)
    }

    /// Always show a little liquid at the bottom, and never quite fill to the brim.
    private var shownLevel: Double { 0.06 + min(1, max(0, level)) * 0.84 }

    /// A few bubbles drifting up through the liquid.
    private func bubbles(t: Double) -> some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let surface = h * (1 - shownLevel)
            ForEach(0..<5, id: \.self) { i in
                let seed = Double(i)
                let cycle = (t * (0.18 + seed * 0.04) + seed * 0.37).truncatingRemainder(dividingBy: 1)
                let y = h - cycle * (h - surface)
                let x = w * (0.2 + 0.15 * seed) + sin(t * 2 + seed) * 6
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6 + seed * 2, height: 6 + seed * 2)
                    .position(x: x, y: y)
                    .opacity(shownLevel > 0.15 ? 1 - cycle * 0.6 : 0)
            }
        }
    }
}

/// The liquid surface. `level` animates, so draining after "Let out" is smooth.
struct Wave: Shape {
    var level: Double
    var phase: Double
    var amplitude: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(level, amplitude) }
        set {
            level = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.height * (1 - level)
        let steps = 60

        path.move(to: CGPoint(x: 0, y: rect.height))
        for i in 0...steps {
            let relative = Double(i) / Double(steps)
            let x = rect.width * relative
            let y = baseline + sin(relative * 2 * Double.pi * 1.5 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// Paw prints that burst outwards when the dog has been let out.
struct PawBurst: View {
    var trigger: Int

    @State private var paws: [Paw] = []

    private struct Paw: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: Double
        let spin: Double
        let size: CGFloat
        var launched = false
    }

    var body: some View {
        ZStack {
            ForEach(paws) { paw in
                Image(systemName: "pawprint.fill")
                    .font(.system(size: paw.size))
                    .foregroundStyle(Theme.deepYellow)
                    .rotationEffect(.degrees(paw.launched ? paw.spin : 0))
                    .scaleEffect(paw.launched ? 1.1 : 0.2)
                    .offset(x: paw.launched ? cos(paw.angle) * paw.distance : 0,
                            y: paw.launched ? sin(paw.angle) * paw.distance : 0)
                    .opacity(paw.launched ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            fire()
        }
    }

    private func fire() {
        let batch = (0..<16).map { _ in
            Paw(angle: Double.random(in: 0..<(2 * Double.pi)),
                distance: Double.random(in: 110...220),
                spin: Double.random(in: -120...120),
                size: CGFloat.random(in: 16...30))
        }
        paws = batch
        Task { @MainActor in
            // Let the paws appear at the centre first, then fling them out.
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.easeOut(duration: 1.1)) {
                for index in paws.indices { paws[index].launched = true }
            }
            try? await Task.sleep(for: .milliseconds(1200))
            if paws.first?.id == batch.first?.id { paws = [] }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        BladderView(level: 0.3, overdue: false).frame(width: 200, height: 200)
        BladderView(level: 1, overdue: true).frame(width: 200, height: 200)
    }
}
