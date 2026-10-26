import SwiftUI

struct HomeView: View {
    @Environment(DogStore.self) private var store
    @Environment(\.openURL) private var openURL

    @State private var showSettings = false
    @State private var burst = 0
    @State private var celebrateUntil = Date.distantPast
    @State private var canAlert = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            canAlert = await AlarmScheduler.shared.canAlert()
        }
        .sensoryFeedback(.success, trigger: burst)
    }

    // MARK: Layout

    private func content(now: Date) -> some View {
        let name = store.profile?.name ?? "Your dog"
        let due = store.nextDue ?? now
        let remaining = Int(due.timeIntervalSince(now).rounded(.up))
        let overdue = remaining <= 0
        let progress = store.progress(at: now)
        let mood = mood(now: now, progress: progress, overdue: overdue)

        return VStack(spacing: 0) {
            header

            Spacer(minLength: 8)

            Text(name.uppercased())
                .font(.rounded(15, .semibold))
                .tracking(3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            ZStack(alignment: .top) {
                BladderView(level: progress, overdue: overdue)
                    .frame(width: 260, height: 260)
                    .overlay(alignment: .center) {
                        countdown(remaining: remaining, overdue: overdue)
                            .offset(y: 34)
                    }
                    .padding(.top, 78)

                DogFace(mood: mood, size: 130)

                PawBurst(trigger: burst)
                    .offset(y: 200)
            }

            Text(statusLine(due: due, overdue: overdue))
                .font(.rounded(15, .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 20)
                .contentTransition(.opacity)

            Spacer(minLength: 16)

            if !canAlert {
                alertsOffBanner
                    .padding(.bottom, 12)
            }

            Button(action: letOut) {
                Label("Let out", systemImage: "pawprint.fill")
            }
            .buttonStyle(BigButtonStyle())

            snoozeButton(visible: overdue || progress > 0.75)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
        }
    }

    private func countdown(remaining: Int, overdue: Bool) -> some View {
        VStack(spacing: 2) {
            Text(overdue ? "WEE TIME!" : "next wee in")
                .font(.rounded(13, .heavy))
                .tracking(overdue ? 2 : 0.5)
                .foregroundStyle(Theme.ink.opacity(0.6))
            Text(overdue ? "+" + ClockFormat.text(seconds: -remaining) : ClockFormat.text(seconds: remaining))
                .font(.rounded(46, .heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(countsDown: !overdue))
                .animation(.snappy, value: remaining)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func snoozeButton(visible: Bool) -> some View {
        Button("Snooze 15 min") {
            withAnimation(.spring) { store.snooze(minutes: 15) }
        }
        .font(.rounded(16, .semibold))
        .foregroundStyle(.secondary)
        .frame(height: 44)
        .opacity(visible ? 1 : 0)
        .disabled(!visible)
        .animation(.easeInOut, value: visible)
    }

    private var alertsOffBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        } label: {
            Label("Alarms are off. Tap to turn them on.", systemImage: "bell.slash.fill")
                .font(.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Capsule().fill(Theme.yellow.opacity(0.25)))
        }
    }

    // MARK: Logic

    private func letOut() {
        withAnimation(.spring(duration: 1.0, bounce: 0.35)) {
            store.letOut()
            celebrateUntil = Date().addingTimeInterval(3)
        }
        burst += 1
    }

    private func mood(now: Date, progress: Double, overdue: Bool) -> DogMood {
        if now < celebrateUntil { return .relieved }
        if overdue { return .desperate }
        if progress > 0.75 { return .antsy }
        return .happy
    }

    private func statusLine(due: Date, overdue: Bool) -> String {
        if overdue { return "Tap Let out when they've been" }
        let time = due.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(due) { return "Alarm at \(time)" }
        if Calendar.current.isDateInTomorrow(due) { return "Alarm tomorrow at \(time)" }
        return "Alarm at \(due.formatted(date: .abbreviated, time: .shortened))"
    }
}

#Preview {
    HomeView()
        .environment(DogStore.preview)
}
