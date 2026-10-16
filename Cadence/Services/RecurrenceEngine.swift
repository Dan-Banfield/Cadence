import Foundation

/// Computes whether (and when) a planner item occurs on a given day.
/// Recurring items are stored once as a template; occurrences are derived here
/// so there is no table of expanded rows to keep in sync.
enum RecurrenceEngine {

    /// Returns the start `Date` of the item's occurrence on `day`, or nil if it
    /// does not occur that day. The time-of-day is taken from `startDate`.
    static func occurrence(of item: PlannerItem, on day: Date, calendar: Calendar = .current) -> Date? {
        let startDay = calendar.startOfDay(for: item.startDate)
        let targetDay = calendar.startOfDay(for: day)

        // Nothing occurs before the template's first date.
        guard targetDay >= startDay else { return nil }

        let occursToday: Bool
        switch item.recurrence {
        case .none:
            occursToday = calendar.isDate(startDay, inSameDayAs: targetDay)
        case .daily:
            occursToday = true
        case .weekdays:
            let weekday = calendar.component(.weekday, from: targetDay)
            // In Gregorian calendars 1 = Sunday, 7 = Saturday.
            occursToday = (weekday >= 2 && weekday <= 6)
        case .weekly:
            occursToday = calendar.component(.weekday, from: targetDay)
                == calendar.component(.weekday, from: startDay)
        case .monthly:
            occursToday = calendar.component(.day, from: targetDay)
                == calendar.component(.day, from: startDay)
        }

        guard occursToday else { return nil }

        // Re-apply the template's time-of-day to the target day.
        let time = calendar.dateComponents([.hour, .minute], from: item.startDate)
        return calendar.date(bySettingHour: time.hour ?? 0,
                             minute: time.minute ?? 0,
                             second: 0,
                             of: targetDay)
    }

    /// All items that occur on `day`, paired with their concrete start time,
    /// sorted chronologically.
    static func items(_ items: [PlannerItem], on day: Date, calendar: Calendar = .current)
        -> [(item: PlannerItem, start: Date)]
    {
        items.compactMap { item in
            guard let start = occurrence(of: item, on: day, calendar: calendar) else { return nil }
            return (item, start)
        }
        .sorted { $0.start < $1.start }
    }
}
