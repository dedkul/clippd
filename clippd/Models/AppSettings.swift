import Foundation

enum AppSettings {
    static let suiteName = "group.com.ashish.clippd"
    static let store = UserDefaults(suiteName: suiteName)!

    enum Keys {
        static let historyLimit = "historyLimit"
        static let linkPreviewsEnabled = "linkPreviewsEnabled"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let layout = "layout"
    }

    enum Defaults {
        static let historyLimit = 50
        static let linkPreviewsEnabled = true
        static let hasSeenOnboarding = false
        static let layout = "list"
    }

    static func registerDefaults() {
        store.register(defaults: [
            Keys.historyLimit: Defaults.historyLimit,
            Keys.linkPreviewsEnabled: Defaults.linkPreviewsEnabled,
            Keys.hasSeenOnboarding: Defaults.hasSeenOnboarding,
            Keys.layout: Defaults.layout
        ])
    }
}
