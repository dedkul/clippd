import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppSettings.Keys.historyLimit, store: AppSettings.store)
    private var historyLimit = AppSettings.Defaults.historyLimit

    @AppStorage(AppSettings.Keys.linkPreviewsEnabled, store: AppSettings.store)
    private var linkPreviewsEnabled = AppSettings.Defaults.linkPreviewsEnabled

    @Query(sort: \ClipboardItem.dateSaved, order: .reverse) private var items: [ClipboardItem]

    @State private var showClearConfirm = false
    @State private var storageUsed: String = "Calculating…"

    var body: some View {
        Form {
            Section("History") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Limit")
                        Spacer()
                        Text("\(historyLimit)")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: historyLimitBinding, in: 5...100, step: 1)
                }
            }

            Section("Link Previews") {
                Toggle("Fetch Link Previews", isOn: $linkPreviewsEnabled)
                if linkPreviewsEnabled {
                    Text("When saving a link, Clippd will fetch the page title and thumbnail once. Requires internet for that single request.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Storage") {
                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text(storageUsed)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Clear All Data")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateStorage()
        }
        .alert("Delete all saved items? This cannot be undone.", isPresented: $showClearConfirm) {
            Button("Delete All", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var historyLimitBinding: Binding<Double> {
        Binding(
            get: { Double(historyLimit) },
            set: { newValue in
                historyLimit = Int(newValue)
                enforceHistoryLimit()
            }
        )
    }

    private func enforceHistoryLimit() {
        let saved = items.filter { !$0.isPending }
        guard saved.count > historyLimit else { return }
        for item in saved.suffix(saved.count - historyLimit) {
            modelContext.delete(item)
        }
        try? modelContext.save()
        calculateStorage()
    }

    private func clearAllData() {
        do {
            try modelContext.delete(model: ClipboardItem.self)
            try modelContext.save()
            calculateStorage()
        } catch {
            // silent — store will reconcile on next launch
        }
    }

    private func calculateStorage() {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppSettings.suiteName
        ) else {
            storageUsed = "Unknown"
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let fm = FileManager.default
            var totalSize: Int64 = 0

            if let enumerator = fm.enumerator(
                at: groupURL,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                          values.isRegularFile == true,
                          let size = values.fileSize else { continue }
                    totalSize += Int64(size)
                }
            }

            let formatted = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

            DispatchQueue.main.async {
                storageUsed = "Using \(formatted)"
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: ClipboardItem.self, inMemory: true)
}
