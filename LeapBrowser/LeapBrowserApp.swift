import SwiftData
import SwiftUI

@main
struct LeapBrowserApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        LanguagePreferences.applyAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.palette.preferredColorScheme)
                .id(themeManager.theme) // force chrome refresh on theme change
        }
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self, HistoryEntry.self])
    }
}
