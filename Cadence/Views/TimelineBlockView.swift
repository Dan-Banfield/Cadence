import SwiftUI

struct TimelineBlockView: View {
    let item: PlannerItem
    let start: Date
    let day: Date
    let hourHeight: CGFloat
    let onToggleComplete: () -> Void
    let onEdit: () -> Void

    private var calendar: Calendar { .current }

    private var isCompleted: Bool {
        item.isCompleted(on: day, calendar: calendar)
    }

    private var blockHeight: CGFloat {
        max(28, CGFloat(item.durationMinutes) / 60 * hourHeight - 4)
    }

    private var accent: Color {
        item.kind == .event ? .indigo : .teal
    }

    var body: some View {
        HStack(spacing: 8) {
            if item.kind == .task {
                Button(action: onToggleComplete) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? accent : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                Text(timeRange)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: blockHeight, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(isCompleted ? 0.06 : 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }

    private var timeRange: String {
        let end = start.addingTimeInterval(TimeInterval(item.durationMinutes * 60))
        let f = Date.FormatStyle.dateTime.hour().minute()
        return "\(start.formatted(f)) – \(end.formatted(f))"
    }
}
