import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkFolder.sortIndex) private var folders: [BookmarkFolder]
    @Query(filter: #Predicate<Bookmark> { $0.folder == nil }, sort: \Bookmark.sortIndex)
    private var rootBookmarks: [Bookmark]

    @StateObject private var tabManager = TabManager()
    @State private var showBookmarks = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showFolderPicker = false
    @State private var showTabCarousel = false
    @State private var bookmarkSavedMessage: String?

    private var browser: BrowserViewModel { tabManager.selectedTab.browser }

    var body: some View {
        VStack(spacing: 0) {
            cyberHeader
            tabStrip
            navigationBar
            loadingPulse
            webStack
            bottomBar
        }
        .background(CyberpunkTheme.void.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { wireHistoryHandlers() }
        .onChange(of: tabManager.selectedTabID) { _, _ in
            wireHistoryHandlers()
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
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView { url in
                browser.load(url)
            }
            .presentationDetents([.medium, .large])
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showTabCarousel) {
            TabCarouselView(tabManager: tabManager)
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
                    .padding(.bottom, 64)
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
            Text("\(tabManager.tabs.count) TAB\(tabManager.tabs.count == 1 ? "" : "S")")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(CyberpunkTheme.neonViolet)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().stroke(CyberpunkTheme.neonViolet.opacity(0.5), lineWidth: 1))
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

    private var tabStrip: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabManager.tabs) { tab in
                        tabChip(tab)
                    }
                }
            }

            // Tap = new tab; long-press = carousel (still includes new tab)
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CyberpunkTheme.neonPink)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8).fill(CyberpunkTheme.well))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(CyberpunkTheme.neonPink.opacity(0.55), lineWidth: 1))
                .shadow(color: CyberpunkTheme.neonPink.opacity(0.35), radius: 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    tabManager.addTab()
                    wireHistoryHandlers()
                }
                .onLongPressGesture(minimumDuration: 0.35) {
                    showTabCarousel = true
                }
                .help("New tab — hold for open tabs")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CyberpunkTheme.panel)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CyberpunkTheme.neonCyan.opacity(0.25))
                .frame(height: 1)
        }
    }

    private func tabChip(_ tab: BrowserTab) -> some View {
        let selected = tab.id == tabManager.selectedTabID
        return HStack(spacing: 6) {
            Button {
                tabManager.select(tab.id)
            } label: {
                Text(tab.title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(selected ? CyberpunkTheme.neonCyan : CyberpunkTheme.mist)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)

            if tabManager.tabs.count > 1 {
                Button {
                    tabManager.closeTab(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(CyberpunkTheme.mist)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? CyberpunkTheme.well : CyberpunkTheme.void.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(selected ? CyberpunkTheme.neonCyan.opacity(0.7) : Color.clear, lineWidth: 1)
        )
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
        .background(CyberpunkTheme.chromeGradient)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CyberpunkTheme.neonPink.opacity(0.35))
                .frame(height: 1)
        }
    }

    private var webStack: some View {
        ZStack {
            ForEach(tabManager.tabs) { tab in
                WebView(
                    browser: tab.browser,
                    onSwipeToNextTab: { tabManager.selectNext() },
                    onSwipeToPreviousTab: { tabManager.selectPrevious() }
                )
                .opacity(tab.id == tabManager.selectedTabID ? 1 : 0)
                .allowsHitTesting(tab.id == tabManager.selectedTabID)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CyberpunkTheme.auraGradient)
                .frame(height: 1)
                .opacity(0.7)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            bottomItem(title: "Settings", systemName: "gearshape.fill", tint: CyberpunkTheme.neonAmber) {
                showSettings = true
            }
            bottomItem(title: "History", systemName: "clock.arrow.circlepath", tint: CyberpunkTheme.neonCyan) {
                showHistory = true
            }
            bottomItem(title: "Bookmarks", systemName: "book.closed.fill", tint: CyberpunkTheme.neonViolet) {
                showBookmarks = true
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(CyberpunkTheme.chromeGradient)
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
        .modelContainer(for: [Bookmark.self, BookmarkFolder.self, HistoryEntry.self], inMemory: true)
}
