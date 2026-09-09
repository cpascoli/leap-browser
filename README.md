# Leap Browser

A simple web browser for **iOS** and **macOS**, built from one shared SwiftUI project on **WKWebView (WebKit)**.

## Goals

- One codebase for iPhone, iPad, and Mac
- Block ads by default
- Enable or disable JavaScript per site / domain
- Present as Chrome (user-agent) for maximum site compatibility
- Manage bookmarks and browsing history
- Sync bookmarks and history over **iCloud** between desktop and mobile

## Stack (locked)

| Layer | Choice |
| --- | --- |
| UI | SwiftUI (multiplatform) |
| Engine | WKWebView / WebKit |
| Persistence | SwiftData + CloudKit (or Core Data + `NSPersistentCloudKitContainer`) |
| Ad blocking | `WKContentRuleList` (compiled JSON rules); optional Safari Content Blocker extension later |
| Config / policies | Local store + iCloud-backed preferences for per-domain JS |

Chromium / CEF is **out of scope** as the rendering engine (iOS App Store constraints and the single-project goal). We can still study Brave, Firefox, and similar projects for *patterns* (blocklists, policy UX, sync conflict handling).

## Docs

- [Architecture](docs/ARCHITECTURE.md) — system design, modules, sync, security
- [Milestones](docs/MILESTONES.md) — phased plan from empty repo to polished product
- [Decisions](docs/DECISIONS.md) — architecture decision records

## Open & run (Milestone 1)

Requires **Xcode 15+** on a Mac (iOS 17 / macOS 14 SDKs).

1. Clone this repo and open `LeapBrowser.xcodeproj`
2. Select the **LeapBrowser** scheme
3. Pick an **iOS Simulator** or **My Mac**, then Run (⌘R)
4. You should see https://example.com in a WKWebView

### Identifiers (placeholders)

| Item | Value |
| --- | --- |
| Bundle ID | `app.leapbrowser` |
| iCloud container (later) | `iCloud.app.leapbrowser` |

CloudKit / iCloud entitlements are **not** enabled yet (Milestone 7).

## Status

Milestone **0** (docs) and **1** (multiplatform skeleton + WKWebView) are in progress on `main`. Next: Milestone 2 — URL bar and navigation chrome.

## Licence

TBD.
