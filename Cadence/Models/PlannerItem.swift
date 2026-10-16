import Foundation
import SwiftData

/// A single planner entry. For recurring entries this acts as the template:
/// individual occurrences are computed on the fly by `RecurrenceEngine`, and
/// per-day completion is tracked by the set of completed day keys.
@Model
final class PlannerItem {
    var id: UUID
    var title: String
    var notes: String

    /// Backing raw values so SwiftData stores plain strings.
    private var kindRaw: String
    private var recurrenceRaw: String

    /// The first occurrence's start time. For recurring items, the time-of-day
    /// here is reused for every occurrence.
    var startDate: Date
    var durationMinutes: Int

    /// For a one-off item: simple completion flag.
    var isCompleted: Bool

    /// For a recurring item: day keys ("yyyy-MM-dd") that have been completed.
    var completedDayKeys: [String]

    /// Minutes before the start to fire a local reminder; nil = no reminder.
    var reminderMinutesBefore: Int?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        kind: ItemKind = .task,
        startDate: Date,
        durationMinutes: Int = 30,
        recurrence: Recurrence = .none,
        reminderMinutesBefore: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.kindRaw = kind.rawValue
        self.startDate = startDate
        self.durationMinutes = durationMinutes
        self.recurrenceRaw = recurrence.rawValue
        self.isCompleted = false
        self.completedDayKeys = []
        self.reminderMinutesBefore = reminderMinutesBefore
    }

    var kind: ItemKind {
        get { ItemKind(rawValue: kindRaw) ?? .task }
        set { kindRaw = newValue.rawValue }
    }

    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    var endDateFromStart: Date {
        startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    // MARK: - Completion helpers

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func isCompleted(on day: Date, calendar: Calendar = .current) -> Bool {
        if recurrence == .none { return isCompleted }
        return completedDayKeys.contains(Self.dayKey(for: day, calendar: calendar))
    }

    func setCompleted(_ completed: Bool, on day: Date, calendar: Calendar = .current) {
        if recurrence == .none {
            isCompleted = completed
            return
        }
        let key = Self.dayKey(for: day, calendar: calendar)
        if completed {
            if !completedDayKeys.contains(key) { completedDayKeys.append(key) }
        } else {
            completedDayKeys.removeAll { $0 == key }
        }
    }
}
