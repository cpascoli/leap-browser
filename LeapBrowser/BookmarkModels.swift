import Foundation
import SwiftData

@Model
final class BookmarkFolder {
    var id: UUID
    var name: String
    var sortIndex: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Bookmark.folder)
    var bookmarks: [Bookmark]

    init(name: String, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = Date()
        self.bookmarks = []
    }
}

@Model
final class Bookmark {
    var id: UUID
    var title: String
    var urlString: String
    var sortIndex: Int
    var createdAt: Date
    var folder: BookmarkFolder?

    init(title: String, urlString: String, folder: BookmarkFolder? = nil, sortIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.urlString = urlString
        self.sortIndex = sortIndex
        self.createdAt = Date()
        self.folder = folder
    }

    var url: URL? {
        URL(string: urlString)
    }
}

@Model
final class HistoryEntry {
    var id: UUID
    var title: String
    var urlString: String
    var visitedAt: Date
    var visitCount: Int

    init(title: String, urlString: String, visitedAt: Date = Date(), visitCount: Int = 1) {
        self.id = UUID()
        self.title = title
        self.urlString = urlString
        self.visitedAt = visitedAt
        self.visitCount = visitCount
    }

    var url: URL? {
        URL(string: urlString)
    }
}
