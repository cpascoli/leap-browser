import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkFolder.sortIndex) private var folders: [BookmarkFolder]
    @Query(filter: #Predicate<Bookmark> { $0.folder == nil }, sort: \Bookmark.sortIndex)
    private var rootBookmarks: [Bookmark]

    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var tabManager = TabManager()
    @StateObject private var chrome = ChromeState()
    @State private var showBookmarks = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showFolderPicker = false
    @State private var showTabCarousel = false
    @State private var bookmarkSavedMessage: String?

    private var browser: BrowserViewModel { tabManager.selectedTab.browser }

    var body: some View {
        ZStack {
            webStack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if chrome.isVisible {
                    navigationBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                    loadingPulse
                        .transition(.opacity)
                } else {
                    // Invisible pull zone / status-bar tap target to help reveal chrome
                    Color.clear
                        .frame(height: 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.22)) { chrome.reveal() }
                        }
                }

                Spacer(minLength: 0)

                if chrome.isVisible {
                    bottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: chrome.isVisible)
        }
        .background(CyberpunkTheme.void.ignoresSafeArea())
        .preferredColorScheme(themeManager.palette.preferredColorScheme)
        .onAppear { wireHistoryHandlers() }
        .onChange(of: tabManager.selectedTabID) { _, _ in
            wireHistoryHandlers()
            withAnimation(.easeInOut(duration: 0.22)) { chrome.reveal() }
        }
        .onChange(of: tabManager.tabs.count) { _, _ in
            wireHistoryHandlers()
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(
                onOpen: { url in browser.load(url) },
                currentPageTitle: browser.pageTitle,
                currentPageURL: browser.currentURL,
                onBookmarkCurrent: {
                    if folders.isEmpty {
                        saveBookmark(to: nil)
                    } else {
                        showFolderPicker = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .preferredColorScheme(themeManager.palette.preferredColorScheme)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView { url in
                browser.load(url)
            }
            .presentationDetents([.medium, .large])
            .preferredColorScheme(themeManager.palette.preferredColorScheme)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .preferredColorScheme(themeManager.palette.preferredColorScheme)
        }
        .sheet(isPresented: $showTabCarousel) {
            TabCarouselView(tabManager: tabManager)
                .presentationDetents([.medium, .large])
                .preferredColorScheme(themeManager.palette.preferredColorScheme)
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
                    .padding(.bottom, chrome.isVisible ? 64 : 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 8) {
            NeonIconButton(systemName: "chevron.backward", tint: CyberpunkTheme.neonCyan, enabled: browser.canGoBack) {
                browser.goBack()
            }
            NeonIconButton(systemName: "house.fill", tint: CyberpunkTheme.neonAmber) {
                browser.goHome()
            }
            CyberpunkAddressField(text: Binding(
                get: { browser.addressText },
                set: { browser.addressText = $0 }
            )) {
                browser.submitAddressBar()
            }
            NeonIconButton(systemName: "arrow.right", tint: CyberpunkTheme.neonPink) {
                browser.submitAddressBar()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .padding(.top, 2)
        .background(CyberpunkTheme.chromeGradient.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CyberpunkTheme.neonPink.opacity(0.35))
                .frame(height: 1)
        }
    }

    private var webStack: some View {
        ZStack {
            ForEach(tabManager.tabs) { tab in
                tabWebView(for: tab)
                    .opacity(tab.id == tabManager.selectedTabID ? 1 : 0)
                    .allowsHitTesting(tab.id == tabManager.selectedTabID)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func tabWebView(for tab: BrowserTab) -> some View {
        #if os(iOS)
        WebView(
            browser: tab.browser,
            onSwipeToNextTab: { tabManager.selectNext() },
            onSwipeToPreviousTab: { tabManager.selectPrevious() },
            onScroll: { y, dragging in
                chrome.handleScroll(offsetY: y, isDragging: dragging)
            }
        )
        #else
        WebView(
            browser: tab.browser,
            onSwipeToNextTab: { tabManager.selectNext() },
            onSwipeToPreviousTab: { tabManager.selectPrevious() },
            onScroll: { y, dragging in
                chrome.handleScroll(offsetY: y, isDragging: dragging)
            },
            onMacScroll: { y, delta in
                chrome.handleMacScroll(scrollY: y, deltaY: delta)
            }
        )
        #endif
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            bottomItem(title: "Pages", systemName: "square.on.square", tint: CyberpunkTheme.neonPink) {
                showTabCarousel = true
            }
            bottomItem(title: "History", systemName: "clock.arrow.circlepath", tint: CyberpunkTheme.neonCyan) {
                showHistory = true
            }
            bottomItem(title: "Bookmarks", systemName: "book.closed.fill", tint: CyberpunkTheme.neonViolet) {
                showBookmarks = true
            }
            bottomItem(title: "Settings", systemName: "gearshape.fill", tint: CyberpunkTheme.neonAmber) {
                showSettings = true
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(CyberpunkTheme.chromeGradient.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CyberpunkTheme.neonCyan.opacity(0.35))
                .frame(height: 1)
        }
    }

    private func bottomItem(title: String, systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.45), radius: 6)
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(CyberpunkTheme.mist)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
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

    private func wireHistoryHandlers() {
        for tab in tabManager.tabs {
            tab.browser.onPageCommitted = { url, title in
                recordHistory(url: url, title: title)
            }
        }
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

    private func recordHistory(url: URL, title: String) {
        let urlString = url.absoluteString
        guard !urlString.isEmpty, url.scheme == "http" || url.scheme == "https" else { return }

        let descriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { $0.urlString == urlString }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.title = title
            existing.visitedAt = Date()
            existing.visitCount += 1
        } else {
            modelContext.insert(HistoryEntry(title: title, urlString: urlString))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager.shared)
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self, HistoryEntry.self], inMemory: true)
}
