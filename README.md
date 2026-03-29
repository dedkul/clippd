# Clippd

Clippd is a privacy-first iPhone clipboard manager I made as a vibe-coding side project.

I am primarily a designer, not a deeply technical iOS engineer, and this project started from a very simple frustration: most clipboard manager apps I found were paid, and I wanted something clean, private, and useful for myself. At the same time, I wanted an excuse to get more hands-on with coding, so Clippd became a small product idea, a learning project, and a way to build something I would actually use.

The goal was to keep it simple:

- save text, links, and images
- bring old clipboard items back with one tap
- keep everything on-device
- make the app understandable even for non-technical people

## What Clippd Does

Clippd gives your clipboard a memory.

When you copy something and open the app, Clippd can detect it and show it as a new pending item. You can save it into your history, browse older saved items, filter them by type, search through them, and copy anything back to the clipboard whenever you need it again.

It also includes a Share Extension, so you can save content from other apps like Safari, Notes, or Photos directly into Clippd.

## Why I Made It

This project came from a very real personal use case:

- I wanted a clipboard manager for iPhone
- many options on the App Store were paid
- I wanted something private and lightweight
- I also wanted to learn by building, not just by reading tutorials

So this repo is intentionally a real product idea, but it is also a design-led learning project. It is planned with care, but built in a very practical, "make it work, make it understandable, keep shipping" way.

## Who This Project Is For

This repo may be especially useful if you are:

- a designer learning to code through real projects
- someone curious about building simple iOS apps with SwiftUI
- interested in privacy-first product ideas
- looking for a small example of an app + share extension setup

## Current Features

The current app includes:

- onboarding for first-time users
- clipboard detection when the app becomes active
- support for text, images, and links
- pending clipboard items that can be saved with one tap
- saved clipboard history using SwiftData
- tap to copy any saved item back to the clipboard
- swipe to delete items
- multi-select mode for bulk deletion
- filtering by content type
- search for saved text and links
- settings for history limit, link previews, and storage usage
- optional link preview fetching
- iOS Share Extension for saving from other apps
- shared App Group storage between the main app and the extension

## Privacy

Privacy is one of the main ideas behind Clippd.

- everything is stored locally on-device
- no accounts
- no analytics
- no tracking
- no server dependency for the main app flow

The only optional network behavior is link preview fetching, and that only happens if the user enables it in Settings.

## Built With

- `SwiftUI` for the app interface
- `SwiftData` for local persistence
- `LinkPresentation` for optional link metadata previews
- `UIPasteboard` for clipboard access
- iOS Share Extension for saving content from other apps
- App Groups for shared storage between targets

## Project Structure

The project has two main targets:

- `clippd` - the main iPhone app
- `ClippdShare` - the Share Extension

Main app areas:

- `clippd/Views` for the UI screens
- `clippd/Models` for app data and settings
- `clippd/Services` for clipboard reading and link previews

Extension area:

- `ClippdShare` for the share flow and shared persistence setup

There is also a more detailed product planning document in `clippd/Instructions/REQUIREMENTS.md`, which explains the original goals, user stories, and feature plan in plain language.

## Tech Notes

Here are the important implementation details at a glance:

- deployment target: iOS 17+
- app data is stored with `SwiftData`
- storage is shared through the App Group `group.com.ashish.clippd`
- the share extension writes into the same shared store as the main app
- the app is designed around native Apple frameworks instead of third-party dependencies

## Product Philosophy

I wanted this app to feel:

- useful before clever
- native before overdesigned
- private before "growth"
- simple enough that a normal person could understand it quickly

This is not trying to be a giant power-user clipboard system. It is trying to be a straightforward, personal, well-planned utility app.

## Project Status

Clippd is still a side project and an active learning project.

That means:

- it is real and functional
- it has been planned intentionally
- it is not pretending to be a huge production-scale app
- there is still room to refine UX, polish states, and improve the overall product

In other words: this is a designer-built app made with curiosity, practicality, and a lot of vibe coding, but with enough structure underneath it to grow properly.

## Possible Next Improvements

Some natural next steps for the project:

- improve the visual polish and branding
- add better empty states and richer share previews
- improve image handling and edge cases
- refine bulk actions and item management
- expand testing and release preparation
- prepare App Store assets and screenshots

## Notes For GitHub Visitors

If you are reading this as a developer, this project is a small SwiftUI utility app with a clean use case and shared-data extension setup.

If you are reading this as a designer, this project is also proof that you do not need to be "super technical" to start building software ideas. You can start with a real problem, define the important behaviors clearly, and build your way into better technical understanding.

---

Built by a designer who wanted a better clipboard tool and decided to learn by making one.