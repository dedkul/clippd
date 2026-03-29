//
//  clippdApp.swift
//  clippd
//
//  Created by Ashish Jangra on 28/3/2026.
//

import SwiftUI
import SwiftData

@main
struct clippdApp: App {
    let modelContainer: ModelContainer

    init() {
        AppSettings.registerDefaults()
        let schema = Schema([ClipboardItem.self])
        let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ashish.clippd"
        )!
        let storeURL = groupURL.appendingPathComponent("clippd.store")
        let config = ModelConfiguration("Clippd", url: storeURL)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
