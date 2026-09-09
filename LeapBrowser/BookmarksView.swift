import SwiftData
import SwiftUI

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkFolder.sortIndex) private var folders: [BookmarkFolder]
    @Query(filter: #Predicate<Bookmark> { $0.folder == nil }, sort: \Bookmark.sortIndex)
    private var rootBookmarks: [Bookmark]

    var onOpen: (URL) -> Void
    var currentPageTitle: String = ""
    var currentPageURL: URL? = nil
    var onBookmarkCurrent: (() -> Void)? = nil

    @State private var newFolderName = ""
    @State private var showingNewFolder = false
    @State private var bookmarkPendingMove: Bookmark?
    @State private var showingMoveSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rootBookmarks, id: \.id) { bookmark in
                        bookmarkRow(bookmark)
                    }
                    .onDelete(perform: deleteRootBookmarks)
                } header: {
                    sectionLabel("ROOT CACHE")
                }

                Section {
                    ForEach(folders, id: \.id) { folder in
                        DisclosureGroup {
                            ForEach(folder.bookmarks.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.id) { bookmark in
                                bookmarkRow(bookmark)
                            }
                            .onDelete { offsets in
                                deleteBookmarks(in: folder, at: offsets)
                            }
                        } label: {
                            Label {
                                Text(folder.name)
                                    .font(.system(.body, design: .monospaced).weight(.semibold))
                                    .foregroundStyle(CyberpunkTheme.neonAmber)
                            } icon: {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(CyberpunkTheme.neonPink)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    sectionLabel("SECTOR FOLDERS")
                }
            }
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #endif
            .background(CyberpunkTheme.void.ignoresSafeArea())
            .navigationTitle("MEMORY BANK")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.neonCyan)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if onBookmarkCurrent != nil, currentPageURL != nil {
                        Button {
                            onBookmarkCurrent?()
                        } label: {
                            Label("Bookmark Page", systemImage: "bookmark.fill")
                                .foregroundStyle(CyberpunkTheme.neonViolet)
                        }
                    }
                    Button {
                        showingNewFolder = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                            .foregroundStyle(CyberpunkTheme.neonPink)
                    }
                }
            }
            #if os(iOS)
            .toolbarBackground(CyberpunkTheme.panel, for: .navigationBar)
            #endif
            .alert("NEW SECTOR", isPresented: $showingNewFolder) {
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
                Text("Allocate a folder node in the memory bank.")
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
                .preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(.dark)
        .tint(CyberpunkTheme.neonCyan)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced).weight(.bold))
            .foregroundStyle(CyberpunkTheme.mist)
            .tracking(1.5)
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        Button {
            if let url = bookmark.url {
                onOpen(url)
                dismiss()
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(bookmark.title.isEmpty ? bookmark.urlString : bookmark.title)
                    .font(.system(.subheadline, design: .default).weight(.semibold))
                    .foregroundStyle(CyberpunkTheme.neonCyan)
                    .lineLimit(1)
                Text(bookmark.urlString)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(CyberpunkTheme.mist)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(CyberpunkTheme.panel.opacity(0.9))
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
            .tint(CyberpunkTheme.neonViolet)
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
                Button("ROOT // NO FOLDER") {
                    onSelect(nil)
                }
                .foregroundStyle(CyberpunkTheme.neonCyan)
                .listRowBackground(CyberpunkTheme.panel)

                ForEach(folders, id: \.id) { folder in
                    Button(folder.name.uppercased()) {
                        onSelect(folder)
                    }
                    .foregroundStyle(CyberpunkTheme.neonAmber)
                    .listRowBackground(CyberpunkTheme.panel)
                }
            }
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #endif
            .background(CyberpunkTheme.void.ignoresSafeArea())
            .navigationTitle("RELOCATE NODE")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(CyberpunkTheme.mist)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
