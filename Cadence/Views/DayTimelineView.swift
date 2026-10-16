import SwiftUI
import SwiftData

struct DayTimelineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PlannerItem.startDate) private var allItems: [PlannerItem]

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var editorItem: PlannerItem?
    @State private var isPresentingNew = false

    private let hourHeight: CGFloat = 60
    private var calendar: Calendar { .current }

    private var todaysItems: [(item: PlannerItem, start: Date)] {
        RecurrenceEngine.items(allItems, on: selectedDay, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayHeader
                Divider()
                timeline
            }
            .navigationTitle("Cadence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                }
            }
            .sheet(isPresented: $isPresentingNew) {
                ItemEditorView(defaultDay: selectedDay)
            }
            .sheet(item: $editorItem) { item in
                ItemEditorView(existing: item)
            }
        }
    }

    // MARK: - Header

    private var dayHeader: some View {
        HStack {
            Button {
                shiftDay(by: -1)
            } label: { Image(systemName: "chevron.left") }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDay, format: .dateTime.weekday(.wide))
                    .font(.headline)
                Text(selectedDay, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .onTapGesture { selectedDay = calendar.startOfDay(for: Date()) }

            Spacer()

            Button {
                shiftDay(by: 1)
            } label: { Image(systemName: "chevron.right") }
        }
        .font(.title3)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func shiftDay(by days: Int) {
        if let next = calendar.date(byAdding: .day, value: days, to: selectedDay) {
            selectedDay = calendar.startOfDay(for: next)
        }
    }

    // MARK: - Timeline

    private var timeline: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                hourGrid
                ForEach(todaysItems, id: \.item.id) { entry in
                    TimelineBlockView(
                        item: entry.item,
                        start: entry.start,
                        day: selectedDay,
                        hourHeight: hourHeight,
                        onToggleComplete: { toggleComplete(entry.item) },
                        onEdit: { editorItem = entry.item }
                    )
                    .offset(x: 56, y: yOffset(for: entry.start))
                    .padding(.trailing, 12)
                }
            }
            .frame(height: hourHeight * 24, alignment: .top)
        }
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(hourLabel(hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                    Spacer(minLength: 0)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour
        let date = calendar.date(from: comps) ?? Date()
        return date.formatted(.dateTime.hour())
    }

    private func yOffset(for start: Date) -> CGFloat {
        let minutes = calendar.component(.hour, from: start) * 60
            + calendar.component(.minute, from: start)
        return CGFloat(minutes) / 60 * hourHeight
    }

    private func toggleComplete(_ item: PlannerItem) {
        let now = item.isCompleted(on: selectedDay, calendar: calendar)
        item.setCompleted(!now, on: selectedDay, calendar: calendar)
    }
}

#Preview {
    DayTimelineView()
        .modelContainer(for: PlannerItem.self, inMemory: true)
}
