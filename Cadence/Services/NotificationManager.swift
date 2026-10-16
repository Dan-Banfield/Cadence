import Foundation
import UserNotifications

/// Schedules local reminders only. There is no push server and no network
/// involvement: everything runs through the on-device notification center.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Identifier scheme keeps one pending request per item so rescheduling is
    /// just "cancel then add".
    private func identifier(for item: PlannerItem) -> String {
        "cadence.reminder.\(item.id.uuidString)"
    }

    func reschedule(for item: PlannerItem) {
        cancel(for: item)

        guard let minutesBefore = item.reminderMinutesBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = item.title.isEmpty ? "Reminder" : item.title
        content.body = item.kind == .event ? "Starting soon" : "Time to start"
        content.sound = .default

        let calendar = Calendar.current
        let fireDate = item.startDate.addingTimeInterval(TimeInterval(-minutesBefore * 60))

        let trigger: UNNotificationTrigger
        switch item.recurrence {
        case .none:
            // One-off: fire at an absolute moment (skip if already in the past).
            guard fireDate > Date() else { return }
            let comps = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        case .daily, .weekdays:
            // Repeat every day at the fire time. (Weekdays-only filtering is a
            // known simplification; see README.)
            let comps = calendar.dateComponents([.hour, .minute], from: fireDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .weekly:
            var comps = calendar.dateComponents([.hour, .minute], from: fireDate)
            comps.weekday = calendar.component(.weekday, from: item.startDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .monthly:
            var comps = calendar.dateComponents([.hour, .minute], from: fireDate)
            comps.day = calendar.component(.day, from: item.startDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: identifier(for: item), content: content, trigger: trigger)
        center.add(request)
    }

    func cancel(for item: PlannerItem) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
    }
}
