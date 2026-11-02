# Clippd — Case study logbook

Raw notes for the final case study. Add a line when a decision is made; trim at the end.
Figma: https://www.figma.com/design/pk6FCxXjATmfUY9SvyNMQY

## The story (one line)
iOS has no clipboard history. I wanted to know why, found out, and built the best version the platform allows anyway.

## Decisions

| Date | Decision | Why | Evidence |
|---|---|---|---|
| v1 | Read the clipboard automatically every time the app opens | Felt magic: open app, clip is there | Figma › Before (v1) |
| 2026-10-16 | Drop auto-read, use Apple's `PasteButton` | iOS shows an "Allow Paste" prompt on every open. The system button is user-initiated, so no prompt | Before (v1) vs any redesign screen |
| 2026-10-16 | No full notes (Google Keep style) | Different product. Clipboard history should stay fast and disposable | — |
| 2026-10-16 | Drop snippets, keep pins | Pins and snippets solve the same "keep this" need; pins are one tap | — |
| 2026-10-16 | Smart chips (YouTube, Colors…) only when matching clips exist | My idea. No empty filters, the UI adapts to what you copy | Round 1 chips |
| 2026-10-16 | Minimum iOS 18 | I can only test on iOS 26/27; supporting 17 blind is risky | — |
| 2026-10-18 | Round 1 felt generic → round 2 explored 3 bold directions (Board, Utility, Latest first) | Commit to one idea per direction instead of averaging | Figma › Round 2 |
| 2026-10-18 | Round 3: List (round 1 Option A) + Board as a toggle, same nav | Board looked best for visual clips, List is better for text. A toggle keeps both without two apps | Figma › Round 3 |
| 2026-10-18 | Feedback goes through X DMs, not a separate "Send feedback" row | One contact route, and it gives the handle a real job instead of being an ad | Figma › Round 3 › Settings |
| 2026-10-20 | Round 4: rebuilt with Apple's official iOS 26 UI kit, no custom styling | Clippd should feel like part of iOS. Native parts mean free dark mode, accessibility and Liquid Glass | Figma › Round 4 |
| 2026-10-20 | Compact rows in List (v1 density), cards only in Board | Cards cost too much vertical space for text; Board still benefits from them | Round 3 vs Round 4 List |
| 2026-10-20 | List/Board, Select and Settings moved into one ⋯ menu | Same pattern as Apple Notes; one nav button instead of three | Round 4 › Menu open |
| 2026-10-20 | Designed every state (select, swipe, delete, search, empty, toasts) in light and dark | A screen isn't designed until its edge states are | Round 4, 26 frames |
| 2026-10-21 | Round 5: 6 list variants (inset grouped, type tiles, Mail style, dense, preview first, pinned shelf) | Round 4's list still didn't feel right; explore density vs. scannability before committing | Explorations › Round 5 |
| 2026-10-25 | Picked A (inset grouped); Round 6 tests how a clip shows its type: grey glyphs vs coloured tiles vs opt-in link previews | All-text rows are slow to scan. Also found the app fetches link previews from the web, which clashes with "privacy-first" | Explorations › Round 6 |
| 2026-10-25 | Picked 6C (link previews on) with 6A grey glyphs as the previews-off fallback; coloured tiles rejected as distracting | The clip itself is the best type signal; colour coding by type added noise | Round 6 |
| 2026-10-25 | Round 7: how do people know the icon-only Paste button adds a clip? Icon only vs labelled "Paste" vs clipboard hint | Paste is the app's main action, so it can't rely on a guessable icon. iOS lets apps see that the clipboard changed (and its type) without the paste prompt | Explorations › Round 7 |
| 2026-10-25 | Kept 6C with the original icon-only Paste button; no hint, no label | Keep the home screen simple; the empty state teaches Paste | Round 6 › 6C |
| 2026-10-25 | YouTube chip uses the real YouTube mark instead of a generic play glyph | A play triangle reads as "video", not YouTube | Round 6 › 6C chips |
| 2026-10-25 | Round 8: personality through one accent colour (blue / indigo / orange / indigo + soft wash) | Apple's own apps with personality (Music, Journal) do it with one colour + icon, not custom components | Explorations › Round 8 |
| 2026-11-01 | Picked 8D (indigo + soft wash) | Most personality while every component stays native | Milestone 6 |
| 2026-11-01 | Paste button gets its word ("Paste", indigo) but keeps Apple's icon | Apple draws PasteButton itself so apps can't fake it: label, icon and wording are locked; only style/shape/tint can change. That lock is what makes the no-prompt paste possible | Milestone 7 |
| 2026-11-01 | Title inline with ⋯, subtitle removed, clip counts moved into section headers ("Today · 4") | Title row wasted space and didn't line up with the button | Milestone 7 |
| 2026-11-01 | Onboarding = one Apple-style welcome sheet + one TipKit tip on Paste; no coach-mark tour | Researched on Mobbin: Apple's own apps (Notes) use a 3-row welcome sheet; spotlight tours are heavy and get skipped. PasteButton never shows "Allow Paste", so there's no prompt to teach | Milestone 7 |
| 2026-11-01 | Explorations trimmed to 7 milestones (dropped rounds 1, 3, 7) | Show the decisions that changed direction, not every step | Explorations page |
| 2026-11-02 | Final design page: 14 screens × light/dark; then built it in SwiftUI with native parts only (inset grouped List, inline large title, .searchable in the bottom bar, PasteButton with label, TipKit tip, Menu, swipe actions, edit-mode selection) | Design and code should match one-to-one, so the case study can show Figma next to the simulator | Figma › Final design; simulator screenshots |
| 2026-11-02 | Found a real bug while coding: the Share extension read the history limit as 0 and could wipe all clips | Defaults registered in the app don't exist in the extension's process. Fixed with a fallback, and pinned clips never count toward the limit | ClippdShare/ShareViewController.swift |

## What I learned (fill in honestly as it happens)
- Why iOS has no clipboard history: privacy. Apps can't read the clipboard in the background, and reading it in the foreground triggers a prompt.
- Xcode, the iOS Simulator, SwiftUI basics, SwiftData
- Share extensions and App Groups (how the app and extension share one database)
- Working with AI: where it was fast, where I had to push back (round 1 felt generic)
- App Store: developer account, privacy policy, review _(to do)_

## Still to capture
- Before screenshots from the simulator (commit 5717f83)
- Final screenshots on device
- App Store link once live
