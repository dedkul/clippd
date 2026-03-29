# Clippd – Requirements Document

> You are an experienced iOS developer. Read this document fully before writing any code. Follow the build steps one at a time. Do not move to the next step until I say "next step". Ask me if anything is unclear.

---

## 1. App Overview

Clippd is a privacy-first clipboard manager for iPhone. It lets users save things they copy — like text, images, and links — so they never lose them. Right now, iPhone does not remember old copied items. Clippd fixes that. When a user opens the app, it checks what is currently copied and asks if they want to save it. Users can also save things from other apps using the share button. Everything is saved on the device only. No internet needed. No data ever leaves the phone.

---

## 2. Main Goals

1. Remember things the user copies, so they are never lost.
2. Let users save copied items with one tap.
3. Let users copy an old item back to their clipboard anytime.
4. Let users save items from other apps using the iOS share sheet.
5. Keep everything private — stored on device only, no internet required by default.
6. Stay simple and clean — feel like a native Apple app.

---

## 3. User Stories

| ID | Story |
|---|---|
| US-001 | As a user, I want the app to notice what I just copied, so I can choose to save it with one tap. |
| US-002 | As a user, I want to see all my saved clipboard items in a list, so I can find them easily. |
| US-003 | As a user, I want to tap a saved item to copy it back to my clipboard, so I can paste it anywhere. |
| US-004 | As a user, I want to save something from Safari or any other app using the share button, so I don't have to switch apps. |
| US-005 | As a user, I want to swipe left on an item to delete it, so I can remove things I no longer need. |
| US-006 | As a user, I want to select multiple items and delete them at once, so I can clean up quickly. |
| US-007 | As a user, I want to filter my list by type (text, image, link), so I can find what I need faster. |
| US-008 | As a user, I want to search through my saved items, so I can find something specific quickly. |
| US-009 | As a user, I want to set how many items the app remembers, so I can control how much storage it uses. |
| US-010 | As a user, I want the app to automatically remove the oldest item when the limit is reached, so I never have to worry about managing it manually. |
| US-011 | As a user, I want to optionally turn on link previews, so I can see a title and thumbnail for saved links. |
| US-012 | As a user, I want a simple onboarding screen on first launch, so I understand how the app works right away. |
| US-013 | As a user, I want to see how much storage the app is using, so I feel in control of my phone's memory. |

---

## 4. Features

### F-001 — Clipboard Reader (On App Open)
- **What it does:** Every time the user opens the app or comes back to it, the app reads what is currently on their clipboard.
- **When it appears:** On every app launch or return to the app (called "foreground").
- **What shows up:** A special item appears at the very top of the list, shown in a different colour (e.g. a soft blue tint), with a label like "New — tap to save".
- **What happens on tap:** The item is saved into the main list and the highlight goes away.
- **What if ignored:** If the user scrolls past it or doesn't tap it, it just stays there until the next time they open the app, when it gets replaced by whatever is on the clipboard then.
- **What if clipboard is empty or same as last saved:** Don't show the pending item at all.
- **If something goes wrong:** If the clipboard can't be read, silently skip — show nothing, no error.

### F-002 — Save Item
- **What it does:** Saves a clipboard item (text, image, or link) into the app's history list.
- **When it appears:** When user taps the pending item at the top (F-001) or when something is shared via the Share Extension (F-003).
- **How it works:** New items are added to the top of the list. If the list is already at the user's limit, the oldest item is automatically deleted to make room.
- **If something goes wrong:** If saving fails (e.g. storage is full), show a simple alert saying "Could not save item. Try freeing up some space."

### F-003 — Share Extension
- **What it does:** Lets the user save text, images, or links from any app (Safari, Notes, Photos, etc.) by tapping the Share button and choosing Clippd.
- **When it appears:** In the iOS share sheet, as an option called "Save to Clippd".
- **How it works:** The item is saved directly into the same history list, using the shared App Group storage so both the extension and main app see the same data.
- **If something goes wrong:** Show a small error message inside the share sheet saying "Could not save. Please try again."

### F-004 — Copy to Clipboard
- **What it does:** When the user taps any saved item in the list, it copies that item back to their iPhone clipboard.
- **When it appears:** On tap of any saved item row.
- **Feedback:** Show a brief confirmation — a small "Copied!" toast message that disappears after 1.5 seconds.
- **If something goes wrong:** Show a simple alert: "Could not copy. Please try again."

### F-005 — Delete Item (Swipe)
- **What it does:** Lets the user delete a single item by swiping left on it.
- **When it appears:** On any saved item row in the list.
- **What shows:** A red "Delete" button appears on swipe.
- **If something goes wrong:** If delete fails, show a simple alert: "Could not delete. Please try again."

### F-006 — Multi-Select & Bulk Delete
- **What it does:** Lets the user select multiple items and delete them all at once, or delete everything.
- **How to enter this mode:** A "Select" button appears in the top right of the main screen.
- **What shows:** Checkboxes appear on each item. A "Delete Selected" button appears at the bottom. A "Select All" button appears at the top.
- **Clear All:** A separate "Clear All" option is available in this mode too.
- **Confirmation:** Before deleting, show a confirmation alert: "Delete X items? This cannot be undone."
- **If something goes wrong:** Show a simple alert: "Could not delete some items. Please try again."

### F-007 — Filter by Type
- **What it does:** Lets the user filter the list to show only Text, only Images, only Links, or All items.
- **Where it lives:** A filter control (segmented picker or pill buttons) near the top of the main screen, just below the search bar.
- **How it works:** Tapping a filter instantly updates the list. The selected filter is highlighted.
- **Default:** "All" is selected by default.

### F-008 — Search
- **What it does:** Lets the user type to search through saved items.
- **Where it lives:** A search bar at the top of the main screen (native iOS search bar).
- **How it works:** Searches through text content and link URLs in real time as the user types. Images without text are not searchable but still show when searching if the filter includes images.
- **If no results:** Show a simple empty state message: "No results found."

### F-009 — Settings Screen
- **What it does:** Lets the user customise the app.
- **Where it lives:** A gear icon in the top left of the main screen, opens a Settings screen.
- **Options available:**
  - **History Limit:** A slider from 5 to 100. Default is 20.
  - **Link Previews:** An on/off toggle. Off by default. When on, the app fetches a title and thumbnail for saved links (requires internet for that one fetch only, then cached forever).
  - **Storage Used:** A read-only line showing how much space Clippd is using on the device (e.g. "Using 12.4 MB").
  - **Clear All Data:** A red button to delete everything. Asks for confirmation first.

### F-010 — Link Preview (Optional, Opt-in)
- **What it does:** When a link is saved and the user has turned on link previews in Settings, the app makes one internet request to fetch the page title and a thumbnail image. These are saved locally and never fetched again.
- **When it appears:** Only when F-009 link preview toggle is ON.
- **What shows in the list:** The link row shows the page title, a small thumbnail, and the URL.
- **When toggle is OFF:** Just show the raw URL with a link icon.
- **If fetch fails:** Just show the raw URL. No error shown to the user.

### F-011 — Onboarding Screen
- **What it does:** Explains the app to a brand new user on their very first launch only.
- **What it shows:** Three simple slides or a single screen with:
  1. What Clippd does ("Never lose a copied item again")
  2. How to save (open the app after copying, or use the share button)
  3. Privacy message ("Everything stays on your device. Always.")
- **A "Get Started" button** takes them to the main screen.
- **Never shows again** after first launch.

---

## 5. Screens

### S-001 — Main Screen (Home)
- **What's on it:**
  - App title "Clippd" in the navigation bar (large title style)
  - Gear icon (top left) → opens S-003 Settings
  - Select button (top right) → enters multi-select mode (F-006)
  - Search bar below the nav bar (F-008)
  - Filter pills below the search bar: All / Text / Image / Link (F-007)
  - The clipboard history list (chronological, newest at top)
  - If clipboard has a new unread item: a highlighted pending item row at the very top with "New — tap to save" label
  - If list is empty: a simple empty state illustration and text ("Nothing saved yet. Copy something and come back!")
- **How you get here:** App launch (after onboarding is done)

### S-002 — Onboarding Screen
- **What's on it:**
  - Simple illustration or icon
  - Short explanation of the app in 2–3 sentences
  - "Get Started" button
- **How you get here:** Only on very first launch of the app
- **Where it goes:** Tapping "Get Started" takes user to S-001

### S-003 — Settings Screen
- **What's on it:**
  - History Limit slider (F-009)
  - Link Previews toggle (F-009)
  - Storage Used display (F-009)
  - Clear All Data button (F-009)
- **How you get here:** Tap gear icon on S-001
- **Style:** Native iOS Settings-style list (Form in SwiftUI)

### S-004 — Share Extension Mini Screen
- **What's on it:**
  - App icon + "Save to Clippd" title
  - A small preview of what's being shared (text snippet, image thumbnail, or URL)
  - "Save" button and "Cancel" button
- **How you get here:** Tapping "Save to Clippd" in the iOS share sheet from any app
- **Where it goes:** Tapping Save closes the sheet and saves the item. Tapping Cancel closes with no action.

---

## 6. Data

### D-001 — Clipboard Item
Each saved item remembers:
- **A unique ID** — so the app can tell items apart
- **Type** — is it text, an image, or a link?
- **Text content** — the actual text (if it's a text item)
- **Image data** — the actual image saved as raw data (if it's an image item, max ~10MB, compressed if larger)
- **URL string** — the web address (if it's a link item)
- **Link preview title** — the page title fetched from the web (optional, only if user has link previews on)
- **Link preview thumbnail** — a small image from the webpage (optional, stored as raw data)
- **Date saved** — when the item was saved, so the list can stay in order
- **Is pending** — a true/false flag marking whether this item has been confirmed saved or is still the "new unread" item at the top

### D-002 — App Settings
The app remembers:
- **History limit** — a number between 5 and 100 (default: 20)
- **Link previews on/off** — true or false (default: false)
- **Has seen onboarding** — true or false, so onboarding only shows once

### D-003 — Shared Storage (App Group)
- The main app and the Share Extension both save and read from the same place on the device using an App Group.
- App Group name: `group.com.yourname.clippd` (replace "yourname" with your Apple developer name)
- This is what allows items saved from the share sheet to instantly appear in the main app.

---

## 7. Extra Details

- **Internet:** Not needed by default. Only used if user turns on Link Previews in Settings, and only for one fetch per new link saved.
- **Data storage:** Everything stored locally on device using SwiftData (Apple's built-in database for iOS 17+).
- **iPhone permissions needed:**
  - **Clipboard access** — to read what the user has copied (iOS will sometimes show a system popup asking the user to allow this — this is normal and expected)
  - **No camera, location, microphone, or contacts needed**
- **Dark mode:** Fully supported automatically by using native SwiftUI and Apple system colours.
- **iPad:** Not supported in v1. iPhone only.
- **iOS version:** iOS 17 or newer.
- **App name:** Clippd
- **Privacy:** No analytics, no tracking, no servers, no accounts. Ever.

---

## 8. Build Steps

Follow these one at a time. Do not skip ahead. After each step, test on the simulator before moving on.

| ID | Step | What to build | References |
|---|---|---|---|
| B-001 | Project setup | Make sure deployment target is iOS 17. Set up the App Group (`group.com.yourname.clippd`) on both the main app target and the Share Extension target in Xcode's Signing & Capabilities tab. | D-003 |
| B-002 | Data model | Create the `ClipboardItem` SwiftData model with all fields listed in D-001. Set up the SwiftData container in `ClippdApp.swift` using the App Group container URL so both targets share the same data. | D-001, D-003 |
| B-003 | App settings storage | Create a simple settings store using `@AppStorage` to save the history limit, link preview toggle, and onboarding seen flag listed in D-002. | D-002 |
| B-004 | Main screen shell | Build the S-001 screen with the navigation bar, gear icon, Select button, search bar, and filter pills. No real data yet — just the layout and empty state message. | S-001, F-007, F-008 |
| B-005 | Clipboard item row | Build the row component that shows a single saved item. It should display differently based on type: text shows a snippet, image shows a thumbnail, link shows the URL. | D-001, S-001 |
| B-006 | Clipboard reader | Build the logic that reads the iPhone clipboard when the app comes to the foreground. Detect the type (text, image, link). If it's new and not already saved, mark it as pending and show it as the highlighted top row on S-001. | F-001, D-001 |
| B-007 | Save item | Build the save action — when the user taps the pending row, save it into SwiftData, remove the pending highlight, and move it into the main list. Apply the history limit rule (auto-delete oldest if over limit). | F-002, D-001, D-002 |
| B-008 | Copy to clipboard | Build the tap action on any saved item row — copy it back to the iPhone clipboard and show the "Copied!" toast message. | F-004 |
| B-009 | Swipe to delete | Add left-swipe delete to each item row. Show red "Delete" button. Remove item from SwiftData on confirm. | F-005 |
| B-010 | Multi-select & bulk delete | Add the Select button to the nav bar. When tapped, show checkboxes on rows, a "Select All" button, and a "Delete Selected" button. Add confirmation alert before deleting. | F-006 |
| B-011 | Filter | Wire up the filter pills so tapping All / Text / Image / Link filters the SwiftData query and updates the list in real time. | F-007 |
|00 B-012 | Search | Wire up the search bar so typing filters the list in real time by text content and URL. | F-8 |
| B-013 | Settings screen | Build S-003 with the history limit slider, link previews toggle, storage used display, and Clear All button with confirmation alert. | F-009, S-003 |
| B-014 | Share Extension | Build the Share Extension (S-004). It should accept text, images, and URLs. When the user taps Save, write the item to the shared App Group SwiftData store. | F-003, S-004, D-003 |
| B-015 | Link previews | Build the link preview fetcher. Only runs when the toggle is ON in Settings. Fetches page title and thumbnail once, saves to the item in SwiftData, never fetches again. Update the link row UI to show the preview. | F-010, D-001 |
| B-016 | Onboarding | Build S-002. Show it only on first launch using the `hasSeenOnboarding` flag in D-002. "Get Started" button saves the flag and navigates to S-001. | F-011, S-002, D-002 |
| B-017 | Polish & edge cases | Test all empty states, error alerts, dark mode, and the history limit auto-delete. Make sure the Share Extension and main app always show the same data. Do a full run-through of every user story in Section 3. | All |
