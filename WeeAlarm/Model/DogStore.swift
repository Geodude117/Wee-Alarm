import Foundation
import Observation

/// Anything that can put the next wee alarm on the device.
@MainActor
protocol AlarmScheduling: AnyObject {
    /// Replace any pending alarm with one at `date`. `nil` clears everything.
    func reschedule(at date: Date?, dogName: String)
}

/// Single source of truth for the dog, the last trip outside and the next alarm.
@MainActor
@Observable
final class DogStore {
    static let shared = DogStore(scheduler: AlarmScheduler.shared)

    private(set) var profile: DogProfile? = nil
    private(set) var lastLetOut: Date? = nil
    private(set) var snoozedUntil: Date? = nil

    private let defaults: UserDefaults
    private let scheduler: AlarmScheduling?
    private let storageKey = "weeAlarm.state.v1"

    private struct Snapshot: Codable {
        var profile: DogProfile?
        var lastLetOut: Date?
        var snoozedUntil: Date?
    }

    init(defaults: UserDefaults = .standard, scheduler: AlarmScheduling?) {
        self.defaults = defaults
        self.scheduler = scheduler
        load()
    }

    // MARK: Derived state

    var nextDue: Date? {
        guard let profile, let lastLetOut else { return nil }
        if let snoozedUntil { return snoozedUntil }
        return WeeSchedule.nextDue(after: lastLetOut,
                                   intervalMinutes: profile.intervalMinutes,
                                   quietHours: profile.quietHoursEnabled ? profile.quietHours : nil)
    }

    /// 0 = just been out, 1 = due now. Clamped.
    func progress(at now: Date) -> Double {
        guard let lastLetOut, let nextDue else { return 0 }
        let total = nextDue.timeIntervalSince(lastLetOut)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(lastLetOut) / total))
    }

    // MARK: Actions

    func completeSetup(_ profile: DogProfile, now: Date = Date()) {
        self.profile = profile
        lastLetOut = now
        snoozedUntil = nil
        commit()
    }

    func letOut(at now: Date = Date()) {
        guard profile != nil else { return }
        lastLetOut = now
        snoozedUntil = nil
        commit()
    }

    func snooze(minutes: Int = 15, now: Date = Date()) {
        guard profile != nil else { return }
        // Snoozing early should push the alarm later, never pull it forward.
        let from = max(now, nextDue ?? now)
        snoozedUntil = from.addingTimeInterval(TimeInterval(minutes * 60))
        commit()
    }

    func update(_ profile: DogProfile) {
        self.profile = profile
        snoozedUntil = nil
        commit()
    }

    func reset() {
        profile = nil
        lastLetOut = nil
        snoozedUntil = nil
        commit()
    }

    /// Re-sync the device alarm with what we have saved (e.g. on launch).
    func refreshAlarm() {
        scheduler?.reschedule(at: nextDue, dogName: profile?.name ?? "")
    }

    #if DEBUG
    /// A store with a sample dog for SwiftUI previews. Never touches real alarms.
    static var preview: DogStore {
        let defaults = UserDefaults(suiteName: "preview.\(UUID().uuidString)") ?? .standard
        let store = DogStore(defaults: defaults, scheduler: nil)
        store.completeSetup(DogProfile(name: "Biscuit", age: .adult, size: .small, intervalMinutes: 180),
                            now: Date().addingTimeInterval(-2 * 3600))
        return store
    }
    #endif

    // MARK: Persistence

    private func commit() {
        save()
        refreshAlarm()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        profile = snapshot.profile
        lastLetOut = snapshot.lastLetOut
        snoozedUntil = snapshot.snoozedUntil
    }

    private func save() {
        let snapshot = Snapshot(profile: profile, lastLetOut: lastLetOut, snoozedUntil: snoozedUntil)
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
