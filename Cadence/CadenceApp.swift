import SwiftUI
import SwiftData

@main
struct CadenceApp: App {
    // A single on-device store. No account, no network, no sync service.
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([PlannerItem.self])
            // Persist locally only; nothing leaves the device.
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create the local data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Ask once for permission to post local reminders.
                    await NotificationManager.shared.requestAuthorizationIfNeeded()
                }
        }
        .modelContainer(container)
    }
}
