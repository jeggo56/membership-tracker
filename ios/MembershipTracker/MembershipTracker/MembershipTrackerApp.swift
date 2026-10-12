import SwiftUI
import SwiftData

@main
struct MembershipTrackerApp: App {
    /// SwiftData 容器
    let container: ModelContainer

    init() {
        let schema = Schema([Membership.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("无法创建 SwiftData 容器: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
