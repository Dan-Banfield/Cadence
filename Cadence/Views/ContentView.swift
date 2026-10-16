import SwiftUI

struct ContentView: View {
    var body: some View {
        DayTimelineView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PlannerItem.self, inMemory: true)
}
