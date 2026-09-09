import SwiftData
import SwiftUI

@main
struct LeapBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self])
    }
}
