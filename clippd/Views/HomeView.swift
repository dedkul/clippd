import SwiftUI
import SwiftData

enum ClipboardFilter: String, CaseIterable {
    case all = "All"
    case text = "Text"
    case image = "Image"
    case link = "Link"
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.dateSaved, order: .reverse) private var items: [ClipboardItem]

    @AppStorage(AppSettings.Keys.historyLimit, store: AppSettings.store)
    private var historyLimit = AppSettings.Defaults.historyLimit

    @AppStorage(AppSettings.Keys.linkPreviewsEnabled, store: AppSettings.store)
    private var linkPreviewsEnabled = AppSettings.Defaults.linkPreviewsEnabled

    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""
    @State private var selectedFilter: ClipboardFilter = .all
    @State private var isSelectMode = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var showSaveError = false
    @State private var showCopyError = false
    @State private var showDeleteError = false
    @State private var showBulkDeleteConfirm = false
    @State private var showCopiedToast = false

    private var filteredItems: [ClipboardItem] {
        var result = items

        switch selectedFilter {
        case .all: break
        case .text: result = result.filter { $0.type == .text }
        case .image: result = result.filter { $0.type == .image }
        case .link: result = result.filter { $0.type == .link }
        }

        guard !searchText.isEmpty else { return result }

        let query = searchText.localizedLowercase
        return result.filter { item in
            switch item.type {
            case .text:
                return item.textContent?.localizedCaseInsensitiveContains(query) == true
            case .link:
                return item.urlString?.localizedCaseInsensitiveContains(query) == true
                    || item.linkPreviewTitle?.localizedCaseInsensitiveContains(query) == true
            case .image:
                return true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                if items.isEmpty {
                    emptyState
                } else if filteredItems.isEmpty && !searchText.isEmpty {
                    searchEmptyState
                } else if filteredItems.isEmpty {
                    filteredEmptyState
                } else {
                    if isSelectMode {
                        selectModeBar
                    }
                    List {
                        ForEach(filteredItems) { item in
                            if isSelectMode {
                                Button {
                                    toggleSelection(item)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.accentColor : .secondary)
                                            .font(.title3)
                                        ClipboardItemRow(item: item)
                                    }
                                }
                                .buttonStyle(.plain)
                            } else if item.isPending {
                                Button {
                                    saveItem(item)
                                } label: {
                                    ClipboardItemRow(item: item)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            } else {
                                Button {
                                    copyToClipboard(item)
                                } label: {
                                    ClipboardItemRow(item: item)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)

                    if isSelectMode {
                        bulkDeleteBar
                    }
                }
            }
            .navigationTitle("Clippd")
            .searchable(text: $searchText, prompt: "Search clips")
            .onAppear {
                ClipboardReader.readAndInsertPending(context: modelContext)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    ClipboardReader.readAndInsertPending(context: modelContext)
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    ToastView(message: "Copied!")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 32)
                }
            }
            .alert("Could not save item. Try freeing up some space.", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            }
            .alert("Could not copy. Please try again.", isPresented: $showCopyError) {
                Button("OK", role: .cancel) {}
            }
            .alert("Could not delete. Please try again.", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            }
            .alert("Delete \(selectedItemIDs.count) items? This cannot be undone.", isPresented: $showBulkDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteSelectedItems()
                }
                Button("Cancel", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelectMode ? "Done" : "Select") {
                        withAnimation {
                            isSelectMode.toggle()
                            if !isSelectMode {
                                selectedItemIDs.removeAll()
                            }
                        }
                    }
                    .disabled(items.isEmpty)
                }
            }
        }
    }

    private func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = UIPasteboard.general
        switch item.type {
        case .text:
            guard let text = item.textContent else { showCopyError = true; return }
            pasteboard.string = text
        case .image:
            guard let data = item.imageData, let image = UIImage(data: data) else { showCopyError = true; return }
            pasteboard.image = image
        case .link:
            guard let urlString = item.urlString, let url = URL(string: urlString) else { showCopyError = true; return }
            pasteboard.url = url
        }
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }

    private func toggleSelection(_ item: ClipboardItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func selectAll() {
        selectedItemIDs = Set(filteredItems.map(\.id))
    }

    private func deleteSelectedItems() {
        do {
            for item in items where selectedItemIDs.contains(item.id) {
                modelContext.delete(item)
            }
            try modelContext.save()
            selectedItemIDs.removeAll()
            withAnimation {
                isSelectMode = false
            }
        } catch {
            showDeleteError = true
        }
    }

    private func deleteItem(_ item: ClipboardItem) {
        do {
            modelContext.delete(item)
            try modelContext.save()
        } catch {
            showDeleteError = true
        }
    }

    private func saveItem(_ item: ClipboardItem) {
        do {
            item.isPending = false
            item.dateSaved = .now
            try modelContext.save()
            enforceHistoryLimit()
            if linkPreviewsEnabled && item.type == .link {
                LinkPreviewFetcher.fetchIfNeeded(for: item, context: modelContext)
            }
        } catch {
            showSaveError = true
        }
    }

    private func enforceHistoryLimit() {
        let saved = items.filter { !$0.isPending }
        guard saved.count > historyLimit else { return }
        let overflow = saved.suffix(saved.count - historyLimit)
        for item in overflow {
            modelContext.delete(item)
        }
    }

    private var selectModeBar: some View {
        HStack {
            Button(selectedItemIDs.count == filteredItems.count ? "Deselect All" : "Select All") {
                if selectedItemIDs.count == filteredItems.count {
                    selectedItemIDs.removeAll()
                } else {
                    selectAll()
                }
            }
            .font(.subheadline)
            Spacer()
            Text("\(selectedItemIDs.count) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var bulkDeleteBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                Button(role: .destructive) {
                    if !selectedItemIDs.isEmpty {
                        showBulkDeleteConfirm = true
                    }
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(selectedItemIDs.isEmpty)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                FilterPill(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter
                ) {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedFilter = filter
                    }
                }
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing saved yet", systemImage: "clipboard")
        } description: {
            Text("Copy something and come back!")
        }
    }

    private var filteredEmptyState: some View {
        ContentUnavailableView {
            Label("No \(selectedFilter.rawValue.lowercased()) items", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("Try a different filter.")
        }
    }

    private var searchEmptyState: some View {
        ContentUnavailableView.search(text: searchText)
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: Capsule())
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: ClipboardItem.self, inMemory: true)
}
