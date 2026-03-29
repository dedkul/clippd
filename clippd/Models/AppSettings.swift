import Foundation

enum AppSettings {
    static let suiteName = "group.com.ashish.clippd"
    static let store = UserDefaults(suiteName: suiteName)!

    enum Keys {
        static let historyLimit = "historyLimit"
        static let linkPreviewsEnabled = "linkPreviewsEnabled"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    enum Defaults {
        static let historyLimit = 20
        static let linkPreviewsEnabled = false
        static let hasSeenOnboarding = false
    }

    static func registerDefaults() {
        store.register(defaults: [
            Keys.historyLimit: Defaults.historyLimit,
            Keys.linkPreviewsEnabled: Defaults.linkPreviewsEnabled,
            Keys.hasSeenOnboarding: Defaults.hasSeenOnboarding
        ])
    }
}
