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
        HomeView()
            .sheet(isPresented: .constant(!hasSeenOnboarding)) {
                OnboardingView { hasSeenOnboarding = true }
            }
            .tint(.indigo)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClipboardItem.self, inMemory: true)
}
