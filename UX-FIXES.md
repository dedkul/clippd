# Clippd — UX Issues & Fixes

A living checklist of UX issues, bugs, and small improvements for the Clippd app.
Claude Code should read this file before starting work, fix items in priority order, and check them off as they are resolved.

---

## How to Use This File

- Each issue has a checkbox `[ ]` — mark it `[x]` once fully resolved and tested
- Fill in the **Resolution** field with a short note on what was changed and which files were touched
- Move fully resolved items to the **Completed** section at the bottom of this file
- Append a matching one-line entry to the `Changelog` section of `DESIGN.md` so both docs stay in sync
- If you discover related issues while fixing something, add them as new entries here instead of silently fixing them
- If you cannot reproduce or fix an issue, leave it unchecked and add a note under **Resolution** explaining why

## Priority Legend

- 🔴 **High** — broken core flow, blocks a key feature
- 🟡 **Medium** — feature works but with rough edges
- 🟢 **Low** — polish, nice-to-have

---

## Active Issues

_No active issues._

---

## Completed

### ✅ 1. YouTube links shared via Share Sheet are saved as text, not as links
- **Fixed on:** 2026-04-26
- **Summary:** Reworked the share extension's attachment loop so a failed `UTType.url` extraction now falls through to the next branch instead of skipping the provider, and added a strict `http(s)` URL fallback inside the `UTType.plainText` branch. Apps that ship links only as text (YouTube being the obvious one) now get classified as `.link`. Also added a foreground link-preview backfill in the main app so share-extension-saved links pick up titles + thumbnails on the next launch when the setting is on.
- **Files touched:** `ClippdShare/ShareViewController.swift`, `clippd/Views/HomeView.swift`
- **Notes:**
  - The fallback uses an explicit scheme + host check (no `NSDataDetector`) so plain text like "google.com" is still saved as text — consistent with the existing tech-debt entry about bare-domain promotion in `ClipboardReader`.
  - The share extension itself does not perform the network fetch (extensions are tightly memory- and time-bounded); the main app handles the backfill on foreground.
  - Per the file's own guidance, share extensions behave differently in the simulator — recommend a real-device pass against YouTube, Safari, X/Twitter, Reddit, and Notes before closing.

<!--
Example format:

### ✅ [Original issue title]
- **Fixed on:** YYYY-MM-DD
- **Summary:** Short description of what was changed
- **Files touched:** `Path/To/File.swift`, `Path/To/Other.swift`
-->

---

## Notes for Claude Code

- Always update this file at the end of a fix session, even if only partial progress was made
- When marking an item complete, also append a one-line entry to the `Changelog` section of `DESIGN.md`
- Prefer fixes that use native Apple frameworks — this project intentionally avoids third-party dependencies
- Keep the Share Extension's memory footprint small; iOS will kill it if it grows too much
- Test on a real device when possible — share extensions behave differently in the simulator
