import SwiftUI
import SwiftData
import TipKit

@main
struct clippdApp: App {
    let modelContainer: ModelContainer

    init() {
        AppSettings.registerDefaults()
        try? Tips.configure()
        let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ashish.clippd")!
            .appending(path: "clippd.store")
        let config = ModelConfiguration(url: containerURL)
        do {
            modelContainer = try ModelContainer(for: ClipboardItem.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        #if DEBUG
        SampleData.seedIfRequested(modelContainer.mainContext)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
