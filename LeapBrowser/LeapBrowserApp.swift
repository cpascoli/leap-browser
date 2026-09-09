import SwiftData
import SwiftUI

@main
struct LeapBrowserApp: App {
    @ObservedObject private var themeManager = ThemeManager.shared

    init() {
        LanguagePreferences.applyAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.palette.preferredColorScheme)
                .id(themeManager.theme)
        }
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self, HistoryEntry.self])
    }
}
