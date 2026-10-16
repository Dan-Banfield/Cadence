import Foundation

/// How often an item repeats. Stored as a raw string on the model so SwiftData
/// persistence stays simple and stable across versions.
enum Recurrence: String, CaseIterable, Identifiable, Codable {
    case none
    case daily
    case weekdays   // Monday–Friday
    case weekly
    case monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Does not repeat"
        case .daily: return "Every day"
        case .weekdays: return "Weekdays"
        case .weekly: return "Every week"
        case .monthly: return "Every month"
        }
    }
}

/// Whether an entry is a flexible task (can be checked off) or a fixed event.
enum ItemKind: String, CaseIterable, Identifiable, Codable {
    case task
    case event

    var id: String { rawValue }

    var label: String { self == .task ? "Task" : "Event" }
}
