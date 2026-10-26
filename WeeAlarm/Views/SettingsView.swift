import SwiftUI

struct SettingsView: View {
    @Environment(DogStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var draft: DogProfile?
    @State private var confirmReset = false
    @State private var testScheduled = false

    var body: some View {
        NavigationStack {
            Form {
                if let profile = Binding($draft) {
                    sections(profile)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if var draft {
                            draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if draft.name.isEmpty { draft.name = store.profile?.name ?? "" }
                            store.update(draft)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .confirmationDialog("Start over?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Start over", role: .destructive) {
                    dismiss()
                    store.reset()
                }
            } message: {
                Text("This removes your dog and cancels the alarm.")
            }
        }
        .onAppear { draft = store.profile }
    }

    @ViewBuilder
    private func sections(_ profile: Binding<DogProfile>) -> some View {
        let recommended = Recommendation.intervalMinutes(age: profile.wrappedValue.age,
                                                         size: profile.wrappedValue.size)

        Section("Dog") {
            TextField("Name", text: profile.name)
                .textInputAutocapitalization(.words)
            Picker("Age", selection: profile.age) {
                ForEach(AgeGroup.allCases) { Text($0.label).tag($0) }
            }
            Picker("Size", selection: profile.size) {
                ForEach(DogSize.allCases) { Text($0.label).tag($0) }
            }
        }

        Section {
            Stepper(value: profile.intervalMinutes,
                    in: DogProfile.intervalRange,
                    step: DogProfile.intervalStep) {
                HStack {
                    Text("Every")
                    Spacer()
                    Text(IntervalFormat.text(minutes: profile.wrappedValue.intervalMinutes))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            if profile.wrappedValue.intervalMinutes != recommended {
                Button("Use recommended (\(IntervalFormat.text(minutes: recommended)))") {
                    profile.wrappedValue.intervalMinutes = recommended
                }
            }
        } header: {
            Text("Wee breaks")
        } footer: {
            Text(Recommendation.reason(age: profile.wrappedValue.age, size: profile.wrappedValue.size)
                 + " " + Recommendation.disclaimer)
        }

        Section {
            Toggle("No alarms overnight", isOn: profile.quietHoursEnabled)
            if profile.wrappedValue.quietHoursEnabled {
                DatePicker("From", selection: time(profile.quietHours.startMinutes), displayedComponents: .hourAndMinute)
                DatePicker("Until", selection: time(profile.quietHours.endMinutes), displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Quiet hours")
        } footer: {
            Text("If a wee break lands in quiet hours, the alarm waits until the morning.")
        }

        Section {
            Button {
                Task {
                    await AlarmScheduler.shared.requestPermissions()
                    AlarmScheduler.shared.scheduleTest(dogName: profile.wrappedValue.name)
                    withAnimation { testScheduled = true }
                }
            } label: {
                Label(testScheduled ? "Test alarm rings in 1 minute" : "Test the alarm",
                      systemImage: testScheduled ? "checkmark.circle.fill" : "alarm")
            }
            .disabled(testScheduled)
            Button("Alarm & notification permissions") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } header: {
            Text("Alarm")
        } footer: {
            Text("Try it with your phone on silent and locked to check you'll hear it.")
        }

        Section("About") {
            Link("Privacy policy", destination: AppLinks.privacyPolicy)
            Link("Help & support", destination: AppLinks.support)
            LabeledContent("Version", value: AppLinks.version)
        }

        Section {
            Button("Start over", role: .destructive) { confirmReset = true }
        }
    }

    /// Bridges "minutes since midnight" to a Date for the time pickers.
    private func time(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: minutes.wrappedValue / 60,
                                      minute: minutes.wrappedValue % 60,
                                      second: 0,
                                      of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}

#Preview {
    SettingsView()
        .environment(DogStore.preview)
}
