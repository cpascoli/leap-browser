import SwiftData
import SwiftUI

@main
struct LeapBrowserApp: App {
    init() {
        LanguagePreferences.applyAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self, HistoryEntry.self])
    }
}
