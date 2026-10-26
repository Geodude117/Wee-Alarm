import Foundation

enum AgeGroup: String, Codable, CaseIterable, Identifiable {
    case puppy, adult, senior

    var id: String { rawValue }

    var label: String {
        switch self {
        case .puppy: return "Puppy"
        case .adult: return "Adult"
        case .senior: return "Senior"
        }
    }
}

enum DogSize: String, Codable, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

/// Quiet hours, stored as minutes since midnight (e.g. 23:00 = 1380).
/// When start > end the window runs overnight.
struct QuietHours: Codable, Equatable {
    var startMinutes: Int
    var endMinutes: Int

    static let standard = QuietHours(startMinutes: 23 * 60, endMinutes: 7 * 60)

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard startMinutes != endMinutes else { return false }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if startMinutes < endMinutes {
            return minute >= startMinutes && minute < endMinutes
        } else {
            return minute >= startMinutes || minute < endMinutes
        }
    }

    /// The next time quiet hours finish, strictly after `date`.
    func end(after date: Date, calendar: Calendar = .current) -> Date {
        let target = DateComponents(hour: endMinutes / 60, minute: endMinutes % 60)
        return calendar.nextDate(after: date, matching: target, matchingPolicy: .nextTime) ?? date
    }
}

struct DogProfile: Codable, Equatable {
    var name: String
    var age: AgeGroup
    var size: DogSize
    var intervalMinutes: Int
    var quietHoursEnabled: Bool = true
    var quietHours: QuietHours = .standard

    static let intervalRange = 60...480
    static let intervalStep = 30
}

enum Recommendation {
    /// Simple rule of thumb: puppy 2h, adult 4h, senior 3h, small dogs 1h less. Never below 1h.
    static func intervalMinutes(age: AgeGroup, size: DogSize) -> Int {
        let baseHours: Int
        switch age {
        case .puppy: baseHours = 2
        case .adult: baseHours = 4
        case .senior: baseHours = 3
        }
        let hours = size == .small ? baseHours - 1 : baseHours
        return max(1, hours) * 60
    }

    static func reason(age: AgeGroup, size: DogSize) -> String {
        var reason: String
        switch age {
        case .puppy: reason = "Puppies have tiny bladders and need to go often."
        case .adult: reason = "Most adult dogs are comfortable every 4 hours or so."
        case .senior: reason = "Older dogs usually need to go a bit more often."
        }
        if size == .small {
            reason += " Small dogs need to go a little sooner."
        }
        return reason
    }
}

enum WeeSchedule {
    /// When the next wee break is due: last trip + interval, pushed to the end of quiet hours if it lands inside them.
    static func nextDue(after last: Date,
                        intervalMinutes: Int,
                        quietHours: QuietHours?,
                        calendar: Calendar = .current) -> Date {
        let due = last.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        if let quietHours, quietHours.contains(due, calendar: calendar) {
            return quietHours.end(after: due, calendar: calendar)
        }
        return due
    }
}

enum IntervalFormat {
    static func text(minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (1, 0): return "1 hour"
        case (_, 0): return "\(hours) hours"
        case (_, 30): return "\(hours)½ hours"
        default: return "\(hours) hr \(rest) min"
        }
    }
}
