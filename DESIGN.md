# Clippd — Technical Design Document

> A working reference for anyone picking up the Clippd codebase cold.
> Generated 2026-04-26.

---

## 1. App Overview

**Clippd** is an iOS clipboard-history app. It captures text, images, and links from the system pasteboard and shows them in a single, searchable list so the user can recall and re-copy anything they've pasted recently. There are two ways content lands in Clippd:

1. **Foreground capture** — when the app comes to the foreground, it reads `UIPasteboard.general` once and surfaces whatever it finds as a "pending" item the user can confirm with a tap.
2. **Share Extension** — from any app's share sheet, the user picks "Save to Clippd" and the content is written straight into the shared store; no UI is shown.

The product values are explicit: **local-only storage, no analytics, no account, no sync**. The only network call the app ever makes is the optional `LPMetadataProvider` fetch when the "Link previews" toggle is on, and that's per-link, off by default. Target user: someone who wants a lightweight, private alternative to copy-and-forget — designers, writers, developers who paste a lot.

iOS does not allow background pasteboard polling, so capture is bounded to the two events above. This is a platform constraint, not a missing feature.

---

## 2. Project Structure

```
clippd/                                  ← Xcode project root (also the git repo root)
├── DESIGN.md                            ← this document
├── README.md                            ← short marketing-style overview
├── buildServer.json                     ← SourceKit-LSP build server config
├── clippd.xcodeproj/                    ← Xcode project package
│   ├── project.pbxproj                  ← target / build-setting definitions
│   ├── project.xcworkspace/             ← workspace metadata
│   └── xcshareddata/                    ← shared schemes
│
├── clippd/                              ← MAIN APP TARGET (com.ashish.clippd)
│   ├── clippdApp.swift                  ← @main entry; builds SwiftData ModelContainer against the App Group URL
│   ├── ContentView.swift                ← root view; routes Onboarding ↔ Home off `hasSeenOnboarding`
│   ├── ClippdAppIcon.icon/              ← icon source (Icon Composer format)
│   ├── Assets.xcassets/                 ← color sets, AppIcon
│   ├── Info.plist                       ← main-app bundle plist
│   ├── clippd.entitlements              ← App Group entitlement (`group.com.ashish.clippd`)
│   ├── Instructions/
│   │   └── REQUIREMENTS.md              ← original product spec (feature IDs F-001…, screen IDs S-001…)
│   ├── Models/
│   │   ├── ClipboardItem.swift          ← SwiftData @Model for a clipboard entry + ClipboardItemType enum
│   │   └── AppSettings.swift            ← UserDefaults keys/defaults wrapper bound to the shared App Group suite
│   ├── Services/
│   │   ├── ClipboardReader.swift        ← reads UIPasteboard, classifies, dedups, inserts as `isPending: true`
│   │   └── LinkPreviewFetcher.swift     ← LPMetadataProvider wrapper that backfills title + thumbnail
│   └── Views/
│       ├── HomeView.swift               ← main screen: list, search, filter pills, multi-select, toast, settings nav
│       ├── ClipboardItemRow.swift       ← row UI + `RelativeTimeView` (auto-refreshing timestamp)
│       ├── OnboardingView.swift         ← single-screen first-run welcome + privacy note
│       └── SettingsView.swift           ← history-limit slider, link-previews toggle, storage usage, clear-all
│
└── ClippdShare/                         ← SHARE EXTENSION TARGET (com.ashish.clippd.ClippdShare)
    ├── ShareViewController.swift        ← headless UIViewController; reads NSItemProviders, writes to shared store
    ├── ClipboardItem.swift              ← duplicate of the main-app @Model so the extension can compile standalone
    ├── Info.plist                       ← NSExtension config; declares supported share types and activation rules
    └── ClippdShare.entitlements         ← App Group entitlement (must match main app)
```

---

## 3. Architecture

### Pattern

SwiftUI data-driven, **MVVM-adjacent without view models**. Views consume `@Query` (SwiftData), `@AppStorage` (UserDefaults), and `@Environment(\.modelContext)` directly. Services (`ClipboardReader`, `LinkPreviewFetcher`) are stateless `struct`s with `static` methods — they're invoked imperatively from views and write back through the model context. There is no Combine-based observable layer, no `ObservableObject`, no Coordinator/Router.

### Data flow

```
┌─────────────────────┐     ┌──────────────────────┐
│ UIPasteboard.general│     │ Share Sheet (any app)│
└──────────┬──────────┘     └──────────┬───────────┘
           │ on .active scenePhase     │ user picks "Save to Clippd"
           ▼                           ▼
┌─────────────────────┐     ┌──────────────────────┐
│  ClipboardReader    │     │  ShareViewController │
│  .readAndInsertPending│   │  saveAndDismiss()    │
└──────────┬──────────┘     └──────────┬───────────┘
           │ insert(ClipboardItem, isPending: true)  │ insert(ClipboardItem, isPending: false)
           ▼                           ▼
        ┌──────────────────────────────────────┐
        │ SwiftData ModelContainer             │
        │ store: <App Group>/clippd.store      │
        │ App Group: group.com.ashish.clippd   │
        └──────────────────┬───────────────────┘
                           │ @Query in HomeView
                           ▼
                  ┌──────────────────┐
                  │ HomeView → Row   │
                  └────────┬─────────┘
                           │ tap
                  ┌────────┴─────────┐
                  ▼                  ▼
           saveItem()          copyToClipboard()
       (commit pending,      (write back to
        run preview fetch)    UIPasteboard)
```

### Key decisions

- **One shared store, two processes.** Both the app and the share extension open the same SwiftData store inside the App Group container. There is no IPC, message bus, or Darwin notification — the share extension just inserts and exits, and the next time the app reads `@Query` it sees the new row.
- **Pending-item review flow.** Foreground capture inserts as `isPending: true`. Pending items render distinctively and are wiped on the next foreground read (`removePendingItems`) unless the user committed them via tap. This avoids polluting history with every transient paste.
- **Settings co-located with data.** `AppSettings.store` is `UserDefaults(suiteName: "group.com.ashish.clippd")`, so the share extension reads the same `historyLimit` the user configured in the main app.
- **No view models.** Acceptable at this size. The cost would be paid back if business logic grows, but today there's almost none — `ClipboardReader` and `LinkPreviewFetcher` carry it all.

---

## 4. Core Features

| ID (REQUIREMENTS.md) | Feature | Implementation |
|---|---|---|
| F-001 | Foreground clipboard capture | `HomeView.onChange(of: scenePhase)` → `ClipboardReader.readAndInsertPending(context:)`. New row inserted with `isPending: true`. |
| F-002 | History list | `HomeView` `List` over `@Query(sort: \ClipboardItem.dateSaved, order: .reverse)` → `ClipboardItemRow`. |
| F-003 | Share Extension capture | `ShareViewController.saveAndDismiss()` walks `extensionContext.inputItems`, classifies each `NSItemProvider` via `hasItemConformingToTypeIdentifier`, inserts saved items, then enforces the history limit and calls `completeRequest`. |
| F-004 | Copy back to clipboard | Tap on a saved row → `HomeView.copyToClipboard(_:)` writes to `UIPasteboard.general` (per-type) and shows the "Copied!" `ToastView` for 1.5 s. |
| F-005 | Swipe to delete one item | `.swipeActions(edge: .trailing)` on each row in `HomeView`; calls `modelContext.delete(item)`. |
| F-006 | Multi-select & bulk delete | "Select" toggles `isSelectMode`; row taps add to `selectedItemIDs: Set<UUID>`; bottom action bar reveals a destructive "Delete Selected" button gated by a confirmation alert. |
| F-007 | Filter by type | `ClipboardFilter` enum (`all`, `text`, `image`, `link`) drives a horizontal `FilterPill` row; filtering is in-memory via a computed `filteredItems`. |
| F-008 | Search | Native `.searchable(text:)`; matches against `textContent` and `urlString`. |
| F-010 | Link preview metadata | After `saveItem` commits a `.link` row, if `linkPreviewsEnabled`, `LinkPreviewFetcher.fetchIfNeeded(for:context:)` calls `LPMetadataProvider.startFetchingMetadata`, then writes title + JPEG thumbnail back on the main thread. |
| F-009, S-003 | Settings | `SettingsView`: slider for `historyLimit` (5–100), toggle for link previews, async storage-size readout, and "Clear All Data" with confirmation. Slider changes call `enforceHistoryLimit()` immediately. |
| F-011, S-002 | Onboarding | `OnboardingView` with privacy copy + "Get Started" button that flips `hasSeenOnboarding`. Shown once via `ContentView` conditional. |
| — | Pending-item commit | Tap a pending row → `HomeView.saveItem(_:)` flips `isPending = false`, refreshes `dateSaved`, optionally fires the link-preview fetch, and enforces the history limit. |
| — | Auto-refreshing timestamps | `RelativeTimeView` in `ClipboardItemRow.swift` subscribes to `Timer.publish(every: 60, on: .main, in: .common).autoconnect()` and re-renders the relative-time string. |

---

## 5. Key Components

| Type | File | Responsibility |
|---|---|---|
| `clippdApp` (`@main` struct) | `clippd/clippdApp.swift` | Calls `AppSettings.registerDefaults()`, builds the `ModelContainer` against the App Group container URL, injects it into the scene. |
| `ContentView` | `clippd/ContentView.swift` | Reads `hasSeenOnboarding` via `@AppStorage(store:)`, conditionally shows `OnboardingView` or `HomeView` with `.easeInOut(0.4)` opacity transitions. |
| `ClipboardItem` (`@Model final class`) | `clippd/Models/ClipboardItem.swift` (and a duplicate at `ClippdShare/ClipboardItem.swift`) | The persisted row. Fields: `id` (`@Attribute(.unique) UUID`), `type`, `textContent`, `imageData` (`@Attribute(.externalStorage)`), `urlString`, `linkPreviewTitle`, `linkPreviewThumbnail` (`@Attribute(.externalStorage)`), `dateSaved`, `isPending`. |
| `ClipboardItemType` (enum) | same file | `text` / `image` / `link`. |
| `AppSettings` (enum namespace) | `clippd/Models/AppSettings.swift` | Holds `suiteName = "group.com.ashish.clippd"`, the `UserDefaults` store, key constants, defaults, and `registerDefaults()`. |
| `ClipboardReader` (struct, static API) | `clippd/Services/ClipboardReader.swift` | `readAndInsertPending(context:)` clears existing pending rows then classifies the pasteboard (image > URL > text-that-looks-like-URL > plain text). Includes `isDuplicateText`, `isDuplicateImage` (compares against the **single most-recent saved row only**), `compressedImageData` (PNG ≤ 10 MB, else JPEG quality ladder 0.8 → 0.1), `looksLikeURL` (NSDataDetector full-range match). |
| `LinkPreviewFetcher` (struct, static API) | `clippd/Services/LinkPreviewFetcher.swift` | `fetchIfNeeded(for:context:)` runs `LPMetadataProvider`, loads the optional thumbnail as a `UIImage`, JPEG-compresses to 0.6 quality, and writes back via `applyPreview` on `DispatchQueue.main`. Re-fetches the row by `id` to avoid mutating across contexts. |
| `HomeView` | `clippd/Views/HomeView.swift` | Owns the search/filter/select state, the `@Query`, the toast, the scroll-driven header hide, and the actions: `saveItem`, `copyToClipboard`, single-delete, bulk-delete, history-limit enforcement. |
| `ClipboardFilter` (enum) | `clippd/Views/HomeView.swift` | `all`, `text`, `image`, `link`. |
| `FilterPill` | `clippd/Views/HomeView.swift` | Pill button used in the filter row. |
| `ToastView` | `clippd/Views/HomeView.swift` | Bottom-right "Copied!" overlay. |
| `ScrollOffsetPreferenceKey` | `clippd/Views/HomeView.swift` | Custom `PreferenceKey<CGFloat>` used to drive `hasScrolled`. |
| `ClipboardItemRow` | `clippd/Views/ClipboardItemRow.swift` | Renders the row: type icon badge, content preview, optional thumbnail, pending tint + "New — tap to save" badge. |
| `RelativeTimeView` | `clippd/Views/ClipboardItemRow.swift` | `Text` driven by a 60-second `Timer.publish` so timestamps stay current without re-rendering the whole list. |
| `OnboardingView` | `clippd/Views/OnboardingView.swift` | Welcome screen; flips `hasSeenOnboarding`. |
| `SettingsView` | `clippd/Views/SettingsView.swift` | History-limit slider (with immediate trim), link-previews toggle, async storage-usage calculator, "Clear All Data" destructive action. |
| `ShareViewController` (`UIViewController`) | `ClippdShare/ShareViewController.swift` | Opens its own `ModelContainer` against the App Group URL, decodes attachments via `NSItemProvider` (URL → `.link`, image with up to 10 MB JPEG fallback → `.image`, plainText → `.text`), saves, runs `enforceHistoryLimit()`, calls `extensionContext.completeRequest`. Headless — no UI. |

---

## 6. Data & Persistence

### Schema (SwiftData)

```swift
@Model final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var type: ClipboardItemType                              // .text | .image | .link
    var textContent: String?
    @Attribute(.externalStorage) var imageData: Data?        // off-row blob
    var urlString: String?
    var linkPreviewTitle: String?
    @Attribute(.externalStorage) var linkPreviewThumbnail: Data?
    var dateSaved: Date
    var isPending: Bool
}
```

`@Attribute(.externalStorage)` keeps the database file lean by spilling the raw bytes to a sibling directory; only a reference lives in the row.

### Where the store lives

```swift
let containerURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ashish.clippd")!
    .appending(path: "clippd.store")
let config = ModelConfiguration(url: containerURL)
```

This URL is identical in `clippd/clippdApp.swift:10-13` and `ClippdShare/ShareViewController.swift`, which is why both processes see the same data.

### Settings storage

`UserDefaults(suiteName: "group.com.ashish.clippd")`, exposed via `AppSettings.store`. Three keys, all registered with defaults at launch:

| Key | Default | Range |
|---|---|---|
| `historyLimit` | 20 | 5–100 |
| `linkPreviewsEnabled` | `false` | bool |
| `hasSeenOnboarding` | `false` | bool |

Views consume these with `@AppStorage(_:store:)` pointing at the same suite — never the standard suite — so the share extension stays in sync.

### Image handling

Images go through `ClipboardReader.compressedImageData(_:)`:

1. Try `pngData()`; if it's ≤ 10 MB, keep it.
2. Otherwise step JPEG quality from 0.8 down to 0.2 in 0.1 increments and return the first encoding under the cap.
3. Worst case, return JPEG at quality 0.1 (or `Data()` if even that fails — see *Known Limitations*).

The share extension applies the same 10 MB cap with its own `compressIfNeeded(_:)` helper.

### History-limit enforcement

The cap is enforced at three call sites — there is no centralized "trimmer":

- `HomeView.saveItem(_:)` — after committing a pending row.
- `SettingsView` — every time the user moves the slider (so lowering the cap immediately deletes the oldest rows).
- `ShareViewController.enforceHistoryLimit()` — after the extension has inserted everything.

All three implementations follow the same shape: fetch saved rows sorted by `dateSaved` descending, `delete` everything past index `historyLimit - 1`, save the context.

### Pending-row lifecycle

- Inserted by `ClipboardReader` with `isPending: true`.
- Wiped at the start of the next `readAndInsertPending` call (so opening the app twice in a row replaces, not stacks).
- Promoted to saved by `HomeView.saveItem(_:)` when the user taps.

---

## 7. UI & UX (iOS)

> **Note:** the original prompt asked about menu-bar / window / keyboard-shortcut behavior. Clippd is an iOS app, so this section covers the iOS-equivalents instead — navigation, gestures, share-sheet integration, and the share-extension presentation model.

### Home screen (`S-001`)

- `NavigationStack` with a large title "Clippd" that **collapses on scroll**. `ScrollOffsetPreferenceKey` reports the list's offset in a named coordinate space, and `hasScrolled = offset < -20` toggles the inline title with `.opacity` + `.animation`.
- Top trailing toolbar: **gear icon → SettingsView** (disabled in select mode), and a **Select / Done** toggle.
- `.searchable(text:)` below the title; matches against `textContent` and `urlString`.
- Horizontal **filter pill row** (`FilterPill`): All / Text / Image / Link.
- `List` of `ClipboardItemRow` items. Three empty-state variants: no items, no results for the current filter, no results for the search query.
- **Bottom overlay in select mode:** Select-All / Deselect-All on the left, count in the middle, "Delete Selected" destructive button on the right (gated by `.alert`).
- **Toast** ("Copied!") fades in bottom-right for 1.5 s after a successful copy.

### Row (`ClipboardItemRow`)

- Left: type icon badge (`doc.text`, `photo`, `link`) on a colored fill.
- Center: content preview (text snippet, "Image", or URL with optional `linkPreviewTitle`).
- Right: thumbnail (image data or link-preview thumbnail) when available.
- Below the title: `RelativeTimeView` — "Just now" / "X minutes ago" / "X hours ago" / "X days ago" / `MMM d`, refreshed on a 60-second `Timer.publish` so the labels don't go stale while the user lingers.
- **Pending state:** soft-blue background tint and a "New — tap to save" badge.

### Gestures

- **Tap** on a saved row → copy to pasteboard + toast.
- **Tap** on a pending row → save (commit + optional link-preview fetch).
- **Trailing swipe** → destructive Delete.
- **Tap with checkbox visible** (select mode) → toggle membership in `selectedItemIDs`.

### Onboarding (`S-002`)

Single screen with icon, title, privacy copy, and a "Get Started" button. Shown only when `hasSeenOnboarding == false`. The `ContentView` swap uses an `.easeInOut(0.4)` opacity transition.

### Settings (`S-003`)

`Form` with four sections:

1. **History** — `Slider` 5…100, step 1, with `enforceHistoryLimit()` on change.
2. **Link Previews** — `Toggle` + descriptive footer text.
3. **Storage** — async file-enumeration of the App Group container, displayed as a human-readable size string.
4. **Action** — destructive "Clear All Data" button gated by `.alert`.

### Share Extension (`F-003`)

The extension is **headless** — `ShareViewController.viewDidLoad()` immediately calls `saveAndDismiss()`. There is no custom UI, so the user sees only the system share sheet's progress chrome before being returned to the source app. Supported activation rules from `Info.plist`:

- `NSExtensionActivationSupportsText`
- `NSExtensionActivationSupportsImageWithMaxCount: 10`
- `NSExtensionActivationSupportsWebURLWithMaxCount: 10`
- `NSExtensionActivationSupportsWebPageWithMaxCount: 10`

### Keyboard

No custom hardware-keyboard shortcuts (no `.keyboardShortcut` modifiers, no `UIKeyCommand`s). The app relies on system keyboard support inside `.searchable`.

---

## 8. Dependencies

**Apple system frameworks only — no third-party SPM packages.**

| Framework | Used for |
|---|---|
| SwiftUI | All views (the share extension is the only `UIViewController` in the codebase). |
| SwiftData | Persistence (`@Model`, `ModelContainer`, `ModelContext`, `@Query`, `FetchDescriptor`, `#Predicate`, `SortDescriptor`). |
| UIKit | `UIPasteboard`, `UIImage`, and the `UIViewController` base for the share extension. |
| LinkPresentation | `LPMetadataProvider` for optional link-preview fetches. |
| Combine | `Timer.publish` in `RelativeTimeView`. |
| UniformTypeIdentifiers | UTType checks on `NSItemProvider` in the share extension. |
| Foundation | `UUID`, `Date`, `URL`, `Data`, `FileManager`, `UserDefaults`, `NSDataDetector`. |

**Minimum deployment target:** iOS 17 (required by SwiftData).

**Bundle IDs:** `com.ashish.clippd` (main), `com.ashish.clippd.ClippdShare` (extension).

**App Group:** `group.com.ashish.clippd` — must be enabled on both targets' entitlements; without it `containerURL(forSecurityApplicationGroupIdentifier:)` returns `nil` and the force-unwrap in both processes will crash.

---

## 9. Known Limitations / Tech Debt

1. **Dedup window is one row deep.** `ClipboardReader.isDuplicateText` / `isDuplicateImage` compare only against the most-recent saved row (`fetchLimit = 1`). Pattern A → B → A treats the second A as new. If we want a truly "no duplicates" history, this needs to widen.
2. **Bare-domain URL detection.** `looksLikeURL` accepts anything `NSDataDetector` flags as a link covering the full string. `"google.com"` → `.link`, even if the user intended plain text.
3. **Silent error swallowing.** `try? context.save()` is used in `LinkPreviewFetcher.applyPreview`, `SettingsView` clear-all, and `ShareViewController`. Failures are invisible to the user.
4. **Force-unwrapped App Group container URL.** Both `clippdApp.swift:11` and the equivalent line in `ShareViewController` will crash if the App Group entitlement isn't present. Fine in practice (it's a setup error), but worth replacing with a clear assertion.
5. **Worst-case image compression returns `Data()`.** If every JPEG quality from 0.8 down to 0.1 fails, `compressedImageData` returns an empty `Data` and the row gets persisted with an unrenderable image.
6. **`RelativeTimeView` Timer fires while offscreen.** `Timer.publish(...).autoconnect()` keeps ticking for rows that have scrolled out of view. Cheap at current scale, but unbounded lists would notice.
7. **Storage-usage calculation isn't cancellable.** The async traversal in `SettingsView` keeps running even after the user leaves the screen, and can update state late. Not a correctness bug, just wasted work.
8. **`ClipboardItem` is duplicated across targets.** The main app's `clippd/Models/ClipboardItem.swift` and `ClippdShare/ClipboardItem.swift` are kept in sync by hand. Easy place for schema drift; should move into a shared embedded framework or Swift Package.
9. **No background capture.** iOS does not allow background pasteboard polling; capture is bounded to foregrounding the app or using the share sheet. Document the constraint clearly so users don't expect macOS-style behavior.
10. **Three places enforce the history limit.** `HomeView.saveItem`, `SettingsView`, and `ShareViewController.enforceHistoryLimit` each implement the same trim. Consolidating into one helper (or a SwiftData `delete` rule) would prevent drift.
11. **Pending-row recovery on extension activity.** If the share extension fires while the main app is suspended, pending rows from the previous foreground are still in the store. Not buggy, but slightly confusing — they'll be wiped on the next foreground read.

---

## 10. Changelog

- **v0.1 — 2026-04-26** — Initial document generated. Reflects code as of commit `5717f83` ("UI polish and Bug Fixes"), which introduced `RelativeTimeView`, the scroll-driven header hide via `ScrollOffsetPreferenceKey`, the animated onboarding↔home transition, and immediate history-limit enforcement on the settings slider.
- **2026-04-26** — Fixed share-extension URL misclassification (UX-FIXES #1). `ShareViewController` now falls through from a failed `UTType.url` load to `UTType.plainText` and reclassifies http(s) URL strings as `.link`. `HomeView` backfills link previews for share-extension-saved items on foreground when the setting is enabled.
