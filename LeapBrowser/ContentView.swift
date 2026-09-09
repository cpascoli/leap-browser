import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkFolder.sortIndex) private var folders: [BookmarkFolder]
    @Query(filter: #Predicate<Bookmark> { $0.folder == nil }, sort: \Bookmark.sortIndex)
    private var rootBookmarks: [Bookmark]

    @StateObject private var browser = BrowserViewModel()
    @State private var showBookmarks = false
    @State private var showFolderPicker = false
    @State private var bookmarkSavedMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            if browser.isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(height: 2)
            }
            WebView(browser: browser)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView { url in
                browser.load(url)
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Save bookmark to…", isPresented: $showFolderPicker, titleVisibility: .visible) {
            Button("No Folder") {
                saveBookmark(to: nil)
            }
            ForEach(folders, id: \.id) { folder in
                Button(folder.name) {
                    saveBookmark(to: folder)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(alignment: .bottom) {
            if let bookmarkSavedMessage {
                Text(bookmarkSavedMessage)
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 10) {
            Button {
                browser.goBack()
            } label: {
                Image(systemName: "chevron.backward")
            }
            .disabled(!browser.canGoBack)
            .help("Back")

            Button {
                browser.goHome()
            } label: {
                Image(systemName: "house")
            }
            .help("Home (Google)")

            TextField("Search or enter address", text: $browser.addressText)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                #endif
                .onSubmit {
                    browser.submitAddressBar()
                }

            Button {
                browser.submitAddressBar()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
            }
            .help("Go")

            Button {
                if folders.isEmpty {
                    saveBookmark(to: nil)
                } else {
                    showFolderPicker = true
                }
            } label: {
                Image(systemName: "bookmark")
            }
            .help("Bookmark this page")

            Button {
                showBookmarks = true
            } label: {
                Image(systemName: "book")
            }
            .help("Bookmarks")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #else
        .background(.bar)
        #endif
    }

    private func saveBookmark(to folder: BookmarkFolder?) {
        let title = browser.pageTitle
        let urlString = browser.currentURL.absoluteString
        let sortIndex: Int
        if let folder {
            sortIndex = folder.bookmarks.count
        } else {
            sortIndex = rootBookmarks.count
        }
        let bookmark = Bookmark(title: title, urlString: urlString, folder: folder, sortIndex: sortIndex)
        modelContext.insert(bookmark)
        let destination = folder?.name ?? "Bookmarks"
        withAnimation {
            bookmarkSavedMessage = "Saved to \(destination)"
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation {
                bookmarkSavedMessage = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self], inMemory: true)
}
