import Foundation
import Testing
@testable import WeeAlarm

// MARK: Helpers

private let gmt: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "GMT")!
    return calendar
}()

private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    gmt.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
}

@MainActor
private final class FakeScheduler: AlarmScheduling {
    var calls: [(date: Date?, name: String)] = []
    func reschedule(at date: Date?, dogName: String) {
        calls.append((date, dogName))
    }
}

private func freshDefaults() -> UserDefaults {
    let name = "WeeAlarmTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

// MARK: Recommendation

@Suite("Recommendation")
struct RecommendationTests {
    @Test(arguments: [
        (AgeGroup.puppy, DogSize.medium, 120),
        (AgeGroup.puppy, DogSize.small, 60),
        (AgeGroup.adult, DogSize.medium, 240),
        (AgeGroup.adult, DogSize.small, 180),
        (AgeGroup.adult, DogSize.large, 240),
        (AgeGroup.senior, DogSize.large, 180),
        (AgeGroup.senior, DogSize.small, 120),
    ])
    func interval(age: AgeGroup, size: DogSize, expected: Int) {
        #expect(Recommendation.intervalMinutes(age: age, size: size) == expected)
    }

    @Test func recommendationsStayInsideTheAllowedRange() {
        for age in AgeGroup.allCases {
            for size in DogSize.allCases {
                #expect(DogProfile.intervalRange.contains(Recommendation.intervalMinutes(age: age, size: size)))
            }
        }
    }
}

// MARK: Quiet hours & schedule

@Suite("Schedule")
struct ScheduleTests {
    let quiet = QuietHours.standard // 23:00 – 07:00

    @Test func overnightWindowContainsLateAndEarlyTimes() {
        #expect(quiet.contains(date(26, 23, 30), calendar: gmt))
        #expect(quiet.contains(date(27, 2), calendar: gmt))
        #expect(!quiet.contains(date(27, 7), calendar: gmt))
        #expect(!quiet.contains(date(26, 14), calendar: gmt))
    }

    @Test func daytimeWindowWorksToo() {
        let nap = QuietHours(startMinutes: 13 * 60, endMinutes: 15 * 60)
        #expect(nap.contains(date(26, 14), calendar: gmt))
        #expect(!nap.contains(date(26, 16), calendar: gmt))
    }

    @Test func equalStartAndEndMeansNoQuietHours() {
        let none = QuietHours(startMinutes: 600, endMinutes: 600)
        #expect(!none.contains(date(26, 10), calendar: gmt))
    }

    @Test func normalDueTimeIsLastPlusInterval() {
        let due = WeeSchedule.nextDue(after: date(26, 9), intervalMinutes: 180, quietHours: quiet, calendar: gmt)
        #expect(due == date(26, 12))
    }

    @Test func dueTimeInQuietHoursMovesToMorning() {
        let due = WeeSchedule.nextDue(after: date(26, 21), intervalMinutes: 180, quietHours: quiet, calendar: gmt)
        #expect(due == date(27, 7))
    }

    @Test func dueTimeAfterMidnightInQuietHoursMovesToSameMorning() {
        let due = WeeSchedule.nextDue(after: date(26, 23, 30), intervalMinutes: 120, quietHours: quiet, calendar: gmt)
        #expect(due == date(27, 7))
    }

    @Test func noQuietHoursMeansNoAdjustment() {
        let due = WeeSchedule.nextDue(after: date(26, 21), intervalMinutes: 180, quietHours: nil, calendar: gmt)
        #expect(due == date(27, 0))
    }
}

// MARK: Formatting

@Suite("Formatting")
struct FormattingTests {
    @Test func intervalText() {
        #expect(IntervalFormat.text(minutes: 60) == "1 hour")
        #expect(IntervalFormat.text(minutes: 180) == "3 hours")
        #expect(IntervalFormat.text(minutes: 150) == "2½ hours")
        #expect(IntervalFormat.text(minutes: 45) == "45 min")
    }

    @Test func clockText() {
        #expect(ClockFormat.text(seconds: 8045) == "2:14:05")
        #expect(ClockFormat.text(seconds: 125) == "2:05")
        #expect(ClockFormat.text(seconds: -5) == "0:00")
    }
}

// MARK: Store

@MainActor
@Suite("DogStore")
struct DogStoreTests {
    let profile = DogProfile(name: "Biscuit", age: .adult, size: .small, intervalMinutes: 180,
                             quietHoursEnabled: false)

    @Test func setupStartsTheTimerAndSchedulesAnAlarm() {
        let scheduler = FakeScheduler()
        let store = DogStore(defaults: freshDefaults(), scheduler: scheduler)
        let now = Date()

        store.completeSetup(profile, now: now)

        #expect(store.profile == profile)
        #expect(store.nextDue == now.addingTimeInterval(3 * 3600))
        #expect(scheduler.calls.last?.date == store.nextDue)
        #expect(scheduler.calls.last?.name == "Biscuit")
    }

    @Test func letOutRestartsTheTimerAndClearsSnooze() {
        let scheduler = FakeScheduler()
        let store = DogStore(defaults: freshDefaults(), scheduler: scheduler)
        let start = Date().addingTimeInterval(-4 * 3600)
        store.completeSetup(profile, now: start)
        store.snooze(minutes: 15)
        #expect(store.snoozedUntil != nil)

        let now = Date()
        store.letOut(at: now)

        #expect(store.snoozedUntil == nil)
        #expect(store.lastLetOut == now)
        #expect(store.nextDue == now.addingTimeInterval(3 * 3600))
    }

    @Test func snoozeOverridesTheDueTime() {
        let store = DogStore(defaults: freshDefaults(), scheduler: nil)
        let now = Date()
        store.completeSetup(profile, now: now.addingTimeInterval(-3 * 3600))
        store.snooze(minutes: 15, now: now)
        #expect(store.nextDue == now.addingTimeInterval(15 * 60))
    }

    @Test func snoozingEarlyNeverBringsTheAlarmForward() {
        let store = DogStore(defaults: freshDefaults(), scheduler: nil)
        let start = Date()
        store.completeSetup(profile, now: start)
        let originalDue = store.nextDue!
        store.snooze(minutes: 15, now: start.addingTimeInterval(60 * 60))
        #expect(store.nextDue == originalDue.addingTimeInterval(15 * 60))
    }

    @Test func progressGoesFromZeroToOne() {
        let store = DogStore(defaults: freshDefaults(), scheduler: nil)
        let start = Date()
        store.completeSetup(profile, now: start)
        #expect(store.progress(at: start) == 0)
        #expect(abs(store.progress(at: start.addingTimeInterval(90 * 60)) - 0.5) < 0.001)
        #expect(store.progress(at: start.addingTimeInterval(5 * 3600)) == 1)
    }

    @Test func stateSurvivesARelaunch() {
        let defaults = freshDefaults()
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        DogStore(defaults: defaults, scheduler: nil).completeSetup(profile, now: start)

        let reopened = DogStore(defaults: defaults, scheduler: nil)
        #expect(reopened.profile == profile)
        #expect(reopened.lastLetOut == start)
    }

    @Test func resetClearsEverythingAndCancelsTheAlarm() {
        let scheduler = FakeScheduler()
        let store = DogStore(defaults: freshDefaults(), scheduler: scheduler)
        store.completeSetup(profile)
        store.reset()
        #expect(store.profile == nil)
        #expect(store.nextDue == nil)
        #expect(scheduler.calls.last?.date == nil)
    }
}
