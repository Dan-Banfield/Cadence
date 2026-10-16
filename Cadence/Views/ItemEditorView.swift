import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let existing: PlannerItem?

    @State private var title: String
    @State private var notes: String
    @State private var kind: ItemKind
    @State private var startDate: Date
    @State private var durationMinutes: Int
    @State private var recurrence: Recurrence
    @State private var reminderEnabled: Bool
    @State private var reminderMinutesBefore: Int

    private let durationChoices = [15, 30, 45, 60, 90, 120, 180]
    private let reminderChoices = [0, 5, 10, 15, 30, 60]

    /// Create a new item on the given day (defaults to the next round hour).
    init(defaultDay: Date) {
        self.existing = nil
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())
        let base = cal.date(bySettingHour: min(hour + 1, 23), minute: 0, second: 0, of: defaultDay)
            ?? defaultDay
        _title = State(initialValue: "")
        _notes = State(initialValue: "")
        _kind = State(initialValue: .task)
        _startDate = State(initialValue: base)
        _durationMinutes = State(initialValue: 30)
        _recurrence = State(initialValue: .none)
        _reminderEnabled = State(initialValue: false)
        _reminderMinutesBefore = State(initialValue: 10)
    }

    /// Edit an existing item.
    init(existing: PlannerItem) {
        self.existing = existing
        _title = State(initialValue: existing.title)
        _notes = State(initialValue: existing.notes)
        _kind = State(initialValue: existing.kind)
        _startDate = State(initialValue: existing.startDate)
        _durationMinutes = State(initialValue: existing.durationMinutes)
        _recurrence = State(initialValue: existing.recurrence)
        _reminderEnabled = State(initialValue: existing.reminderMinutesBefore != nil)
        _reminderMinutesBefore = State(initialValue: existing.reminderMinutesBefore ?? 10)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(ItemKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("When") {
                    DatePicker("Starts", selection: $startDate)
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(durationChoices, id: \.self) { Text(durationLabel($0)).tag($0) }
                    }
                    Picker("Repeats", selection: $recurrence) {
                        ForEach(Recurrence.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $reminderEnabled)
                    if reminderEnabled {
                        Picker("Before start", selection: $reminderMinutesBefore) {
                            ForEach(reminderChoices, id: \.self) { Text(reminderLabel($0)).tag($0) }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if existing != nil {
                    Section {
                        Button("Delete", role: .destructive, action: deleteItem)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes) min"
            : (minutes % 60 == 0 ? "\(minutes / 60) hr" : "\(minutes / 60) hr \(minutes % 60) min")
    }

    private func reminderLabel(_ minutes: Int) -> String {
        minutes == 0 ? "At start time" : "\(minutes) min before"
    }

    private func save() {
        let item: PlannerItem
        if let existing {
            item = existing
        } else {
            item = PlannerItem(title: title, startDate: startDate)
            context.insert(item)
        }

        item.title = title.trimmingCharacters(in: .whitespaces)
        item.notes = notes
        item.kind = kind
        item.startDate = startDate
        item.durationMinutes = durationMinutes
        item.recurrence = recurrence
        item.reminderMinutesBefore = reminderEnabled ? reminderMinutesBefore : nil

        NotificationManager.shared.reschedule(for: item)
        dismiss()
    }

    private func deleteItem() {
        guard let existing else { return }
        NotificationManager.shared.cancel(for: existing)
        context.delete(existing)
        dismiss()
    }
}
