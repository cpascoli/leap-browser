# Leap Browser — Architecture Decision Records

## ADR-001: Rendering engine = WKWebView (WebKit)

- **Status:** Accepted  
- **Context:** Need one project for iOS and macOS; App Store distribution assumed.  
- **Decision:** Use WKWebView / WebKit exclusively for page rendering.  
- **Consequences:** No Chromium feature parity (e.g. some extension models). Strongest path for shared SwiftUI code and App Store compliance. We may still read Brave/Firefox for UX and policy patterns.

## ADR-002: UI framework = SwiftUI multiplatform

- **Status:** Accepted  
- **Context:** Dual-platform UI with shared navigation and settings.  
- **Decision:** SwiftUI app with iOS and macOS destinations; isolate `UIViewRepresentable` / `NSViewRepresentable` (or platform web view bridges) behind a thin `WebView` wrapper.  
- **Consequences:** Occasional platform `#if` for chrome; business logic stays shared.

## ADR-003: Ad blocking via WKContentRuleList

- **Status:** Accepted (MVP)  
- **Context:** “All ads should be blocked” as a product requirement.  
- **Decision:** In-app content rule lists compiled with `WKContentRuleListStore`. Optional Safari Content Blocker extension deferred.  
- **Consequences:** Rule grammar is Apple’s subset; maintain a conversion/bundling pipeline; communicate best-effort blocking to users.

## ADR-004: Chrome user-agent by default

- **Status:** Accepted  
- **Context:** Maximum site compatibility.  
- **Decision:** Default UA mimics current Chrome; separate mobile and desktop strings. Centralise in `UserAgentProvider`.  
- **Consequences:** Sites treat Leap as Chrome; must refresh strings periodically; keep a debug override in settings.

## ADR-005: Per-domain JavaScript policy with reload

- **Status:** Accepted  
- **Context:** Enable/disable JS on specific sites/domains.  
- **Decision:** Persist `SitePolicy` per host; apply through web view configuration; **reload** the tab when the effective policy changes.  
- **Consequences:** Simpler and more reliable than fighting mid-document preference mutation; UX must explain that the page reloads.

## ADR-006: Library sync via iCloud / CloudKit

- **Status:** Accepted  
- **Context:** Sync bookmarks and history between Mac and iOS.  
- **Decision:** Private CloudKit database via SwiftData+CloudKit or Core Data + `NSPersistentCloudKitContainer`. Sync bookmarks, history, and site policies. Tab session sync deferred.  
- **Consequences:** Requires iCloud account; conflict strategy is UUID + last-writer-wins; local-only mode when iCloud unavailable.

## ADR-007: Minimum OS versions

- **Status:** Proposed  
- **Context:** Reduce compatibility surface.  
- **Decision (proposal):** iOS 17+ / macOS 14+.  
- **Consequences:** Modern APIs; excludes older devices — revisit if user base requires it.

## ADR-008: Policy host key

- **Status:** Proposed  
- **Context:** JS/ads exceptions need a stable key.  
- **Decision (proposal):** Store policies keyed by **registrable domain (eTLD+1)** with optional more-specific host overrides.  
- **Consequences:** Need a public-suffix-aware helper; fewer entries than raw hostnames; document override precedence in ARCHITECTURE.md.

## ADR-009: History retention

- **Status:** Proposed  
- **Context:** History can grow quickly and sync cost scales with volume.  
- **Decision (proposal):** Default retain **90 days**; prune locally on a schedule; sync only non-pruned records.  
- **Consequences:** Predictable storage; power users may want longer retention later.
