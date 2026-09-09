import SwiftData
import SwiftUI

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkFolder.sortIndex) private var folders: [BookmarkFolder]
    @Query(filter: #Predicate<Bookmark> { $0.folder == nil }, sort: \Bookmark.sortIndex)
    private var rootBookmarks: [Bookmark]

    var onOpen: (URL) -> Void

    @State private var newFolderName = ""
    @State private var showingNewFolder = false
    @State private var bookmarkPendingMove: Bookmark?
    @State private var showingMoveSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Bookmarks") {
                    ForEach(rootBookmarks, id: \.id) { bookmark in
                        bookmarkRow(bookmark)
                    }
                    .onDelete(perform: deleteRootBookmarks)
                }

                Section("Folders") {
                    ForEach(folders, id: \.id) { folder in
                        DisclosureGroup {
                            ForEach(folder.bookmarks.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.id) { bookmark in
                                bookmarkRow(bookmark)
                            }
                            .onDelete { offsets in
                                deleteBookmarks(in: folder, at: offsets)
                            }
                        } label: {
                            Label(folder.name, systemImage: "folder")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewFolder = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
                Button("Create") {
                    let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let folder = BookmarkFolder(name: name, sortIndex: folders.count)
                    modelContext.insert(folder)
                    newFolderName = ""
                }
            } message: {
                Text("Organise bookmarks into a named folder.")
            }
            .sheet(isPresented: $showingMoveSheet) {
                MoveBookmarkSheet(
                    folders: folders,
                    onSelect: { folder in
                        if let bookmark = bookmarkPendingMove {
                            bookmark.folder = folder
                            bookmark.sortIndex = (folder?.bookmarks.count) ?? rootBookmarks.count
                        }
                        bookmarkPendingMove = nil
                        showingMoveSheet = false
                    },
                    onCancel: {
                        bookmarkPendingMove = nil
                        showingMoveSheet = false
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        Button {
            if let url = bookmark.url {
                onOpen(url)
                dismiss()
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title.isEmpty ? bookmark.urlString : bookmark.title)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(bookmark.urlString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(bookmark)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                bookmarkPendingMove = bookmark
                showingMoveSheet = true
            } label: {
                Label("Move", systemImage: "folder")
            }
            .tint(.indigo)
        }
    }

    private func deleteRootBookmarks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rootBookmarks[index])
        }
    }

    private func deleteBookmarks(in folder: BookmarkFolder, at offsets: IndexSet) {
        let items = folder.bookmarks.sorted(by: { $0.sortIndex < $1.sortIndex })
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

private struct MoveBookmarkSheet: View {
    let folders: [BookmarkFolder]
    var onSelect: (BookmarkFolder?) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Button("No Folder (top level)") {
                    onSelect(nil)
                }
                ForEach(folders, id: \.id) { folder in
                    Button(folder.name) {
                        onSelect(folder)
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}
