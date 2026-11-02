import SwiftUI
import SwiftData
import TipKit
import UniformTypeIdentifiers

/// Smart chips. A chip only appears when at least one clip matches it.
enum ClipFilter: CaseIterable, Hashable {
    case all, youTube, links, text, colors, images

    var title: String {
        switch self {
        case .all: "All"
        case .youTube: "YouTube"
        case .links: "Links"
        case .text: "Text"
        case .colors: "Colors"
        case .images: "Images"
        }
    }

    func matches(_ item: ClipboardItem) -> Bool {
        switch self {
        case .all: true
        case .youTube: item.kind == .youTube
        case .links: item.type == .link
        case .text: item.kind == .text
        case .colors: item.kind == .color
        case .images: item.kind == .image
        }
    }
}

private struct ClipSection: Identifiable {
    let id: String
    let title: String
    let items: [ClipboardItem]
}

private struct Toast: Equatable {
    let title: String
    var detail: String?
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \ClipboardItem.dateSaved, order: .reverse) private var items: [ClipboardItem]

    @AppStorage(AppSettings.Keys.historyLimit, store: AppSettings.store)
    private var historyLimit = AppSettings.Defaults.historyLimit
    @AppStorage(AppSettings.Keys.linkPreviewsEnabled, store: AppSettings.store)
    private var linkPreviewsEnabled = AppSettings.Defaults.linkPreviewsEnabled
    @AppStorage(AppSettings.Keys.layout, store: AppSettings.store)
    private var layout = AppSettings.Defaults.layout
    @AppStorage(AppSettings.Keys.hasSeenOnboarding, store: AppSettings.store)
    private var hasSeenOnboarding = AppSettings.Defaults.hasSeenOnboarding

    @State private var searchText = ""
    @State private var filter: ClipFilter = .all
    @State private var isSelecting = false
    @State private var selection: Set<UUID> = []
    @State private var showSettings = false
    @State private var showDeleteConfirm = false
    @State private var shareItems: [Any]?
    @State private var toast: Toast?
    @State private var toastTask: Task<Void, Never>?
    @State private var savedCount = 0

    private let pasteTip = PasteTip()

    // MARK: Derived data

    private var availableFilters: [ClipFilter] {
        ClipFilter.allCases.filter { f in f == .all || items.contains(where: f.matches) }
    }

    private var visibleItems: [ClipboardItem] {
        let filtered = items.filter(filter.matches)
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter { item in
            [item.title, item.textContent, item.urlString, item.host]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var sections: [ClipSection] {
        let visible = visibleItems
        let pinned = visible.filter(\.isPinned)
        var result = pinned.isEmpty ? [] : [ClipSection(id: "pinned", title: "Pinned", items: pinned)]
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: visible.filter { !$0.isPinned }) { calendar.startOfDay(for: $0.dateSaved) }
        for day in byDay.keys.sorted(by: >) {
            result.append(ClipSection(id: day.formatted(.iso8601), title: Self.title(for: day), items: byDay[day] ?? []))
        }
        return result
    }

    private var selectedItems: [ClipboardItem] {
        items.filter { selection.contains($0.id) }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            content
                .background { HomeBackground() }
                .navigationTitle(isSelecting ? selectionTitle : "Clippd")
                .toolbarTitleDisplayMode(.inlineLarge)
                .searchable(text: $searchText, prompt: "Search clips")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showSettings) {
                    NavigationStack { SettingsView() }
                }
                .sheet(isPresented: Binding(get: { shareItems != nil }, set: { if !$0 { shareItems = nil } })) {
                    ActivityView(items: shareItems ?? [])
                        .presentationDetents([.medium, .large])
                }
                .alert(selection.count == 1 ? "Delete 1 clip?" : "Delete \(selection.count) clips?",
                       isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive, action: deleteSelected)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("They’ll be removed from this iPhone. This can’t be undone.")
                }
                .overlay(alignment: .bottom) { toastView }
                .sensoryFeedback(.success, trigger: savedCount)
                .onChange(of: availableFilters) { _, filters in
                    if !filters.contains(filter) { filter = .all }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        enforceHistoryLimit()
                        backfillLinkPreviews()
                    }
                }
                .onAppear(perform: backfillLinkPreviews)
        }
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label("No clips yet", systemImage: "doc.on.clipboard")
            } description: {
                Text("Copy something in any app,\nthen come back and tap Paste.")
            }
        } else if visibleItems.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if layout == "board" && !isSelecting {
            board
        } else {
            list
        }
    }

    private var selectionTitle: String {
        selection.isEmpty ? "Select Clips" : "\(selection.count) Selected"
    }

    // MARK: List

    private var list: some View {
        List(selection: isSelecting ? $selection : nil) {
            if !isSelecting && availableFilters.count > 1 {
                Section {
                    chips
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listSectionSpacing(4)
            }
            ForEach(sections) { section in
                Section("\(section.title) · \(section.items.count)") {
                    ForEach(section.items) { item in
                        row(item)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 4, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
    }

    @ViewBuilder
    private func row(_ item: ClipboardItem) -> some View {
        if isSelecting {
            ClipboardItemRow(item: item)
                .tag(item.id)
        } else {
            Button { copy(item) } label: {
                ClipboardItemRow(item: item)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive) { delete([item]) }
                Button(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") {
                    setPinned(!item.isPinned, [item])
                }
                .tint(.orange)
            }
            .contextMenu { menu(for: item) }
        }
    }

    // MARK: Board

    private var board: some View {
        let ordered = visibleItems.filter(\.isPinned) + visibleItems.filter { !$0.isPinned }
        let columns = [0, 1].map { column in ordered.enumerated().filter { $0.offset % 2 == column }.map(\.element) }
        return ScrollView {
            if availableFilters.count > 1 {
                chips.padding(.bottom, 8)
            }
            HStack(alignment: .top, spacing: 12) {
                ForEach(columns.indices, id: \.self) { index in
                    LazyVStack(spacing: 12) {
                        ForEach(columns[index]) { item in
                            Button { copy(item) } label: { ClipCard(item: item) }
                                .buttonStyle(.plain)
                                .contextMenu { menu(for: item) }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: Pieces

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(availableFilters, id: \.self) { chip in
                    let isOn = chip == filter
                    Button {
                        withAnimation(.snappy) { filter = chip }
                    } label: {
                        HStack(spacing: 5) {
                            if chip == .youTube { YouTubeMark() }
                            Text(chip.title)
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(isOn ? Color.accentColor : .gray)
                    .foregroundStyle(isOn ? .white : .primary)
                    .background(isOn ? Color.accentColor : .clear, in: .capsule)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func menu(for item: ClipboardItem) -> some View {
        Button("Copy", systemImage: "doc.on.doc") { copy(item) }
        Button(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") {
            setPinned(!item.isPinned, [item])
        }
        Button("Share", systemImage: "square.and.arrow.up") { shareItems = Self.shareable([item]) }
        Button("Delete", systemImage: "trash", role: .destructive) { delete([item]) }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
                    withAnimation { isSelecting = false; selection.removeAll() }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                let allPinned = !selectedItems.isEmpty && selectedItems.allSatisfy(\.isPinned)
                Button("Copy", systemImage: "doc.on.doc") { copySelected() }
                Button(allPinned ? "Unpin" : "Pin", systemImage: allPinned ? "pin.slash" : "pin") {
                    setPinned(!allPinned, selectedItems)
                }
                Spacer()
                Button("Share", systemImage: "square.and.arrow.up") { shareItems = Self.shareable(selectedItems) }
                Button("Delete", systemImage: "trash", role: .destructive) { showDeleteConfirm = true }
                    .tint(.red)
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) { moreMenu }
            if #available(iOS 26, *) {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }
            ToolbarItem(placement: .bottomBar) { pasteButton }
        }
    }

    private var moreMenu: some View {
        Menu("More", systemImage: "ellipsis") {
            Picker("Layout", selection: $layout) {
                Label("List", systemImage: "list.bullet").tag("list")
                Label("Board", systemImage: "square.grid.2x2").tag("board")
            }
            Section {
                Button("Select", systemImage: "checkmark.circle") {
                    withAnimation { isSelecting = true }
                }
                .disabled(items.isEmpty)
            }
            Section {
                Button("Settings", systemImage: "gear") { showSettings = true }
            }
        }
        .tint(.primary)
    }

    private var pasteButton: some View {
        PasteButton(supportedContentTypes: [.url, .image, .plainText]) { providers in
            paste(providers)
        }
        .labelStyle(.titleAndIcon)
        .buttonBorderShape(.capsule)
        .popoverTip(items.isEmpty && hasSeenOnboarding ? pasteTip : nil, arrowEdge: .bottom)
    }

    @ViewBuilder
    private var toastView: some View {
        Group {
            if let toast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(toast.title).font(.subheadline.weight(.semibold))
                        if let detail = toast.detail {
                            Text(detail).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 20)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: .capsule)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .combine)
            }
        }
        .animation(.snappy, value: toast)
    }

    // MARK: Actions

    private func paste(_ providers: [NSItemProvider]) {
        Task {
            let outcome = await ClipboardReader.handlePaste(providers: providers, context: modelContext)
            switch outcome {
            case .saved(let item):
                try? modelContext.save()
                enforceHistoryLimit()
                if linkPreviewsEnabled && item.type == .link {
                    LinkPreviewFetcher.fetchIfNeeded(for: item, context: modelContext)
                }
                savedCount += 1
                pasteTip.invalidate(reason: .actionPerformed)
                let detail = item.type == .link ? "Link · \(item.host ?? "")" : item.detail
                show(Toast(title: "Saved", detail: detail))
            case .duplicate:
                show(Toast(title: "Already saved", detail: "It’s already in your list"))
            case .empty:
                show(Toast(title: "Nothing to paste"))
            }
        }
    }

    private func copy(_ item: ClipboardItem) {
        guard let value = Self.pasteboardValue(item) else { return }
        UIPasteboard.general.setItems([value])
        show(Toast(title: "Copied", detail: item.detail))
    }

    private func copySelected() {
        UIPasteboard.general.setItems(selectedItems.compactMap { Self.pasteboardValue($0) })
        show(Toast(title: "Copied", detail: selection.count == 1 ? nil : "\(selection.count) clips"))
    }

    private func setPinned(_ pinned: Bool, _ targets: [ClipboardItem]) {
        withAnimation {
            for item in targets { item.isPinned = pinned }
            try? modelContext.save()
        }
    }

    private func delete(_ targets: [ClipboardItem]) {
        withAnimation {
            for item in targets { modelContext.delete(item) }
            try? modelContext.save()
        }
    }

    private func deleteSelected() {
        delete(selectedItems)
        selection.removeAll()
        withAnimation { isSelecting = false }
    }

    private func show(_ newToast: Toast) {
        toastTask?.cancel()
        toast = newToast
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    /// Pinned clips never count towards the history limit.
    private func enforceHistoryLimit() {
        let unpinned = items.filter { !$0.isPinned }
        guard unpinned.count > historyLimit else { return }
        for item in unpinned.suffix(unpinned.count - historyLimit) {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func backfillLinkPreviews() {
        guard linkPreviewsEnabled else { return }
        for item in items where item.type == .link && item.linkPreviewTitle == nil && item.urlString != nil {
            LinkPreviewFetcher.fetchIfNeeded(for: item, context: modelContext)
        }
    }

    // MARK: Helpers

    private static func title(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: day, to: .now).day, days < 7 {
            return day.formatted(.dateTime.weekday(.wide))
        }
        return day.formatted(.dateTime.month(.abbreviated).day())
    }

    private static func pasteboardValue(_ item: ClipboardItem) -> [String: Any]? {
        switch item.type {
        case .text:
            item.textContent.map { [UTType.plainText.identifier: $0] }
        case .link:
            item.urlString.flatMap(URL.init(string:)).map { [UTType.url.identifier: $0] }
        case .image:
            item.imageData.flatMap(UIImage.init(data:)).map { [UTType.image.identifier: $0] }
        }
    }

    private static func shareable(_ targets: [ClipboardItem]) -> [Any] {
        targets.compactMap { item -> Any? in
            switch item.type {
            case .text: item.textContent
            case .link: item.urlString.flatMap(URL.init(string:))
            case .image: item.imageData.flatMap(UIImage.init(data:))
            }
        }
    }
}

/// Grouped background with a faint indigo glow at the top (the "8D" look).
private struct HomeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Color(.systemGroupedBackground)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.indigo.opacity(colorScheme == .dark ? 0.32 : 0.2), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 420)
            }
            .ignoresSafeArea()
    }
}

/// Small YouTube mark for the YouTube chip.
/// TODO before release: replace with the official icon from YouTube's brand resources.
private struct YouTubeMark: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3.5)
            .fill(Color(red: 1, green: 0, blue: 0.2))
            .frame(width: 17, height: 12)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    HomeView()
        .modelContainer(for: ClipboardItem.self, inMemory: true)
}
