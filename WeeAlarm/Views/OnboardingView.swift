import SwiftUI

/// Three quick screens: name → about → schedule.
struct OnboardingView: View {
    @Environment(DogStore.self) private var store

    @State private var step = 0
    @State private var goingForward = true
    @State private var name = ""
    @State private var age: AgeGroup = .adult
    @State private var size: DogSize = .medium
    @State private var interval = Recommendation.intervalMinutes(age: .adult, size: .medium)
    @State private var starting = false
    @FocusState private var nameFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var dogName: String { trimmedName.isEmpty ? "your dog" : trimmedName }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 8)

            ZStack {
                currentStep
                    .id(step)
                    .transition(stepTransition)
            }
            .frame(maxHeight: .infinity)

            Button(action: advance) {
                Text(step == 2 ? "Start" : "Next")
            }
            .buttonStyle(BigButtonStyle())
            .disabled(step == 0 && trimmedName.isEmpty || starting)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .onAppear { nameFocused = true }
    }

    // MARK: Steps

    @ViewBuilder
    private var currentStep: some View {
        switch step {
        case 0: nameStep
        case 1: aboutStep
        default: scheduleStep
        }
    }

    private var nameStep: some View {
        VStack(spacing: 28) {
            DogFace(mood: trimmedName.isEmpty ? .curious : .happy,
                    size: 150,
                    tilt: trimmedName.isEmpty ? 0 : -12)

            Text("What's your dog called?")
                .font(.rounded(30, .heavy))
                .multilineTextAlignment(.center)

            VStack(spacing: 6) {
                TextField("Name", text: $name)
                    .font(.rounded(34, .bold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($nameFocused)
                    .onSubmit(advance)
                Capsule()
                    .fill(trimmedName.isEmpty ? Color.secondary.opacity(0.3) : Theme.yellow)
                    .frame(width: trimmedName.isEmpty ? 120 : 220, height: 4)
                    .animation(.spring(duration: 0.4, bounce: 0.4), value: trimmedName.isEmpty)
            }
        }
    }

    private var aboutStep: some View {
        VStack(spacing: 28) {
            DogFace(mood: .happy, size: 150)
                .scaleEffect(faceScale)
                .animation(.spring(duration: 0.5, bounce: 0.5), value: faceScale)
                .frame(height: 170)

            Text("Tell us about \(dogName)")
                .font(.rounded(30, .heavy))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                Text("Age")
                    .font(.rounded(15, .semibold))
                    .foregroundStyle(.secondary)
                ChoiceRow(options: AgeGroup.allCases, label: { $0.label }, selection: $age)

                Text("Size")
                    .font(.rounded(15, .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                ChoiceRow(options: DogSize.allCases, label: { $0.label }, selection: $size)
            }
        }
    }

    private var scheduleStep: some View {
        let recommended = Recommendation.intervalMinutes(age: age, size: size)

        return VStack(spacing: 24) {
            DogFace(mood: .happy, size: 120)

            Text("\(dogName) needs a wee every")
                .font(.rounded(24, .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                roundButton("minus", disabled: interval <= DogProfile.intervalRange.lowerBound) {
                    interval -= DogProfile.intervalStep
                }
                Text(IntervalFormat.text(minutes: interval))
                    .font(.rounded(46, .heavy))
                    .contentTransition(.numericText(value: Double(interval)))
                    .animation(.spring(duration: 0.35, bounce: 0.3), value: interval)
                    .frame(minWidth: 170)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                roundButton("plus", disabled: interval >= DogProfile.intervalRange.upperBound) {
                    interval += DogProfile.intervalStep
                }
            }

            Group {
                if interval == recommended {
                    Label("Recommended", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.deepYellow)
                } else {
                    Button("Use recommended (\(IntervalFormat.text(minutes: recommended)))") {
                        interval = recommended
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .font(.rounded(15, .semibold))
            .animation(.spring, value: interval == recommended)

            Text(Recommendation.reason(age: age, size: size))
                .font(.rounded(15, .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .sensoryFeedback(.selection, trigger: interval)
    }

    private func roundButton(_ symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Theme.yellow))
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.3 : 1)
        .disabled(disabled)
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack {
            Button {
                go(to: step - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .opacity(step > 0 ? 1 : 0)
            .disabled(step == 0)
            .accessibilityLabel("Back")

            Spacer()

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(index <= step ? Theme.deepYellow : Color.secondary.opacity(0.25))
                        .scaleEffect(index == step ? 1.25 : 1)
                        .symbolEffect(.bounce, value: index == step)
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.5), value: step)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var faceScale: CGFloat {
        let base: CGFloat
        switch size {
        case .small: base = 0.72
        case .medium: base = 0.9
        case .large: base = 1.1
        }
        return age == .puppy ? base * 0.9 : base
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: Navigation

    private func advance() {
        switch step {
        case 0:
            guard !trimmedName.isEmpty else { return }
            nameFocused = false
            go(to: 1)
        case 1:
            interval = Recommendation.intervalMinutes(age: age, size: size)
            go(to: 2)
        default:
            start()
        }
    }

    private func go(to newStep: Int) {
        guard (0...2).contains(newStep) else { return }
        goingForward = newStep > step
        withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
            step = newStep
        }
        if newStep == 0 { nameFocused = true }
    }

    private func start() {
        starting = true
        let profile = DogProfile(name: trimmedName, age: age, size: size, intervalMinutes: interval)
        Task {
            await AlarmScheduler.shared.requestPermissions()
            store.completeSetup(profile)
        }
    }
}

/// A row of options with a yellow pill that slides to the selected one.
struct ChoiceRow<Option: Hashable & Identifiable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.rounded(17, .semibold))
                        .foregroundStyle(option == selection ? Color.black : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if option == selection {
                                Capsule()
                                    .fill(Theme.yellow)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Capsule().fill(Color.secondary.opacity(0.1)))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    OnboardingView()
        .environment(DogStore(defaults: UserDefaults(suiteName: "onboarding-preview")!, scheduler: nil))
}
