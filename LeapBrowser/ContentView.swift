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
            cyberHeader
            navigationBar
            loadingPulse
            WebView(browser: browser)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(CyberpunkTheme.auraGradient)
                        .frame(height: 1)
                        .opacity(0.7)
                }
        }
        .background(CyberpunkTheme.void.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showBookmarks) {
            BookmarksView { url in
                browser.load(url)
            }
            .presentationDetents([.medium, .large])
            .preferredColorScheme(.dark)
        }
        .confirmationDialog("SAVE TO NODE…", isPresented: $showFolderPicker, titleVisibility: .visible) {
            Button("ROOT // NO FOLDER") {
                saveBookmark(to: nil)
            }
            ForEach(folders, id: \.id) { folder in
                Button(folder.name.uppercased()) {
                    saveBookmark(to: folder)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(alignment: .bottom) {
            if let bookmarkSavedMessage {
                CyberpunkToast(message: bookmarkSavedMessage)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var cyberHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LEAP // リープ")
                    .font(.system(.caption, design: .monospaced).weight(.heavy))
                    .foregroundStyle(CyberpunkTheme.auraGradient)
                    .shadow(color: CyberpunkTheme.neonPink.opacity(0.6), radius: 8)
                Text("NEO-TŌKYŌ NET · 2226")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CyberpunkTheme.mist.opacity(0.8))
            }
            Spacer()
            Text(browser.isLoading ? "SYNCING…" : "LINK STABLE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(browser.isLoading ? CyberpunkTheme.neonAmber : CyberpunkTheme.neonCyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().stroke(browser.isLoading ? CyberpunkTheme.neonAmber.opacity(0.6) : CyberpunkTheme.neonCyan.opacity(0.5), lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(CyberpunkTheme.chromeGradient)
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            NeonIconButton(systemName: "chevron.backward", tint: CyberpunkTheme.neonCyan, enabled: browser.canGoBack) {
                browser.goBack()
            }
            NeonIconButton(systemName: "house.fill", tint: CyberpunkTheme.neonAmber) {
                browser.goHome()
            }
            CyberpunkAddressField(text: $browser.addressText) {
                browser.submitAddressBar()
            }
            NeonIconButton(systemName: "arrow.right", tint: CyberpunkTheme.neonPink) {
                browser.submitAddressBar()
            }
            NeonIconButton(systemName: "bookmark.fill", tint: CyberpunkTheme.neonViolet) {
                if folders.isEmpty {
                    saveBookmark(to: nil)
                } else {
                    showFolderPicker = true
                }
            }
            NeonIconButton(systemName: "book.closed.fill", tint: CyberpunkTheme.neonCyan) {
                showBookmarks = true
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(CyberpunkTheme.chromeGradient)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CyberpunkTheme.neonPink.opacity(0.35))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var loadingPulse: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(CyberpunkTheme.panel)
                .frame(height: 2)
            if browser.isLoading {
                Rectangle()
                    .fill(CyberpunkTheme.auraGradient)
                    .frame(height: 2)
                    .shadow(color: CyberpunkTheme.neonCyan.opacity(0.8), radius: 4)
            }
        }
        .frame(height: 2)
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
        let destination = folder?.name ?? "ROOT"
        withAnimation {
            bookmarkSavedMessage = "Cached → \(destination)"
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
