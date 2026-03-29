//
//  ContentView.swift
//  clippd
//
//  Created by Ashish Jangra on 28/3/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage(AppSettings.Keys.hasSeenOnboarding, store: AppSettings.store)
    private var hasSeenOnboarding = AppSettings.Defaults.hasSeenOnboarding

    var body: some View {
        if hasSeenOnboarding {
            HomeView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClipboardItem.self, inMemory: true)
}
