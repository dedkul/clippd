import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @AppStorage(AppSettings.Keys.historyLimit, store: AppSettings.store)
    private var historyLimit = AppSettings.Defaults.historyLimit

    @AppStorage(AppSettings.Keys.linkPreviewsEnabled, store: AppSettings.store)
    private var linkPreviewsEnabled = AppSettings.Defaults.linkPreviewsEnabled

    @Query(sort: \ClipboardItem.dateSaved, order: .reverse) private var items: [ClipboardItem]

    @State private var showClearConfirm = false
    @State private var storageUsed = "…"

    private static let limits = [20, 50, 100, 200]

    var body: some View {
        Form {
            Section {
                SettingsLabel("Everything stays on this iPhone",
                              subtitle: "No accounts, no analytics, no servers.",
                              symbol: "lock.fill", color: .green)
            }

            Section {
                Picker(selection: $historyLimit) {
                    ForEach(Self.limits, id: \.self) { Text("\($0) clips").tag($0) }
                } label: {
                    SettingsLabel("Keep Last", symbol: "clock", color: .blue)
                }
                .pickerStyle(.navigationLink)

                Toggle(isOn: $linkPreviewsEnabled) {
                    SettingsLabel("Link Previews", symbol: "link", color: .indigo)
                }
            } header: {
                Text("History")
            } footer: {
                Text("Previews fetch a title and thumbnail once per link. That’s the only time Clippd uses the internet.")
            }

            Section("Storage") {
                LabeledContent {
                    Text(storageUsed)
                } label: {
                    SettingsLabel("Using", symbol: "internaldrive", color: .gray)
                }
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    SettingsLabel("Clear All Clips", symbol: "trash", color: .red)
                        .foregroundStyle(.red)
                }
                .disabled(items.isEmpty)
            }

            Section {
                Link(destination: URL(string: "https://x.com/feat_ashish")!) {
                    SettingsLabel("Feedback & Feature Requests",
                                  subtitle: "DM @feat_ashish on X",
                                  symbol: "bubble.left.fill", color: .black)
                }
                Button {
                    requestReview()
                } label: {
                    SettingsLabel("Rate Clippd", symbol: "star.fill", color: .orange)
                }
            } header: {
                Text("About")
            } footer: {
                Text("Clippd \(Bundle.main.version) · Made by Ashish")
            }
        }
        .foregroundStyle(.primary)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") { dismiss() }
            }
        }
        .onAppear(perform: calculateStorage)
        .onChange(of: historyLimit) { enforceHistoryLimit() }
        .alert("Delete all clips?", isPresented: $showClearConfirm) {
            Button("Delete All", role: .destructive, action: clearAllData)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They’ll be removed from this iPhone. This can’t be undone.")
        }
    }

    private func enforceHistoryLimit() {
        let unpinned = items.filter { !$0.isPinned }
        guard unpinned.count > historyLimit else { return }
        for item in unpinned.suffix(unpinned.count - historyLimit) {
            modelContext.delete(item)
        }
        try? modelContext.save()
        calculateStorage()
    }

    private func clearAllData() {
        try? modelContext.delete(model: ClipboardItem.self)
        try? modelContext.save()
        calculateStorage()
    }

    private func calculateStorage() {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppSettings.suiteName
        ) else {
            storageUsed = "Unknown"
            return
        }
        Task {
            storageUsed = await Self.formattedSize(of: groupURL)
        }
    }

    @concurrent
    private static func formattedSize(of directory: URL) async -> String {
        let urls = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )?.allObjects as? [URL] ?? []
        let total = urls.reduce(Int64(0)) { sum, url in
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true, let size = values.fileSize else { return sum }
            return sum + Int64(size)
        }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}

/// Settings-style row label: a small tinted icon tile, a title and an optional subtitle.
private struct SettingsLabel: View {
    let title: String
    var subtitle: String?
    let symbol: String
    let color: Color

    init(_ title: String, subtitle: String? = nil, symbol: String, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(color, in: .rect(cornerRadius: 7))
        }
    }
}

private extension Bundle {
    var version: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: ClipboardItem.self, inMemory: true)
}
