# App Store submission kit

Everything to paste into App Store Connect for Clippd 1.0. Character limits are Apple's.

## App information

| Field | Value |
|---|---|
| Name (30) | Clippd |
| Backup name if taken | Clippd: Clipboard History |
| Subtitle (30) | Clipboard history, on device |
| Bundle ID | com.ashish.clippd |
| Primary category | Utilities |
| Secondary category | Productivity |
| Age rating | 4+ (answer "None" to every questionnaire item) |
| Price | Free |
| Privacy policy URL | https://github.com/dedkul/clippd/blob/main/PRIVACY.md |
| Support URL | https://x.com/feat_ashish |
| Copyright | 2026 Ashish Jangra |

The repo is public, so the privacy policy link works as soon as PR #1 is merged into `main`.

## Promotional text (170)

Copy something, tap Paste, and it's saved. Clippd keeps a private history of what you copy, right on your iPhone. No account, no cloud.

## Description (4000)

Your iPhone only remembers the last thing you copied. Clippd remembers the rest.

Copy anything, open Clippd and tap Paste. Or save straight from Safari, Photos and other apps with the Share menu, without opening Clippd at all.

CLIPS SHOW THEMSELVES
Images appear as thumbnails, colour codes as swatches, and links with their preview, so you can find things at a glance.

FIND IT AGAIN
• Clips grouped by day
• Search everything you've saved
• Filters for links, YouTube, text, colours and images that appear only when you need them
• List or Board layout

KEEP WHAT MATTERS
• Pin clips to keep them at the top, forever
• Tap any clip to copy it again
• Select several clips to copy, share or delete them together
• Choose how many clips to keep, from 20 to 200

PRIVATE BY DESIGN
Clippd never reads your clipboard on its own. It only sees what you hand it with Paste or Share, so iOS never needs to ask for permission. Everything stays on your iPhone: no account, no cloud, no analytics, no tracking. Link previews can be turned off in Settings.

Built with Apple's own components, so it feels at home on iOS, in light and dark mode, with Dynamic Type and VoiceOver.

## Keywords (100, comma separated, no spaces)

clipboard,history,manager,copy,paste,clips,snippets,saved,links,notes,private,offline,pin,text

## What's New (1.0)

First release.

## App Privacy (nutrition label)

- Data collection: **No, we do not collect data from this app.**
- Result shown on the store: **Data Not Collected**.

Why this is accurate: clips stay on device. Link previews contact the linked website directly, and nothing reaches the developer, so it is not "collection" under Apple's definition.

## App Review notes

> Clippd is a clipboard history app. It uses SwiftUI's PasteButton, so it never reads the pasteboard programmatically and never triggers the paste permission prompt. To test: copy any text or link in Safari, open Clippd and tap Paste in the bottom bar. The Share extension can be tested from Safari's Share menu (Share › Clippd). No login is required.

## Export compliance

`ITSAppUsesNonExemptEncryption = NO` is set in the build settings, so App Store Connect won't ask on each upload. The app only uses Apple's standard HTTPS for link previews.

## Screenshots

Required: 6.9" iPhone (1320 × 2868, or 1290 × 2796). Take them on an iPhone 17 Pro Max (or 16 Pro Max) simulator, which outputs the right size:

```
-seedSampleData -hasSeenOnboarding YES            # home, list
-seedSampleData -hasSeenOnboarding YES -layout board
-hasSeenOnboarding NO                             # welcome sheet
```

Suggested order: Home (light) · Board · Home (dark) · Search · Settings. Up to 10 allowed, 3 to 5 is plenty.

## Release checklist

- [ ] Apple Developer Program membership active (paid, not a personal team)
- [ ] App icon added from Icon Composer, checked in light, dark and tinted
- [ ] Merge PR #1 into `main`
- [ ] Test on a real iPhone: Paste (text, link, image, colour), Share from Safari and Photos, link previews off, history limit, pins survive the limit
- [ ] Create the app in App Store Connect with bundle ID `com.ashish.clippd` (check the name is free)
- [ ] Privacy policy URL is public
- [ ] Xcode: Product › Archive › Distribute App › App Store Connect
- [ ] Install the TestFlight build on your phone and run the test pass once more
- [ ] Fill in the fields above, add screenshots, submit for review
