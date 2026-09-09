import Combine
import Foundation
import SwiftUI

final class BrowserTab: ObservableObject, Identifiable {
    let id: UUID
    let browser: BrowserViewModel
    private var browserObservation: AnyCancellable?

    init(id: UUID = UUID(), startURL: URL = URLHelpers.homeURL) {
        self.id = id
        self.browser = BrowserViewModel()
        self.browser.currentURL = startURL
        self.browser.addressText = startURL.absoluteString
        browserObservation = browser.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var title: String {
        let page = browser.pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !page.isEmpty, page != "Leap Browser" { return page }
        return browser.currentURL.host ?? "New Tab"
    }
}

final class TabManager: ObservableObject {
    @Published private(set) var tabs: [BrowserTab]
    @Published var selectedTabID: UUID
    private var tabCancellables = Set<AnyCancellable>()

    var selectedTab: BrowserTab {
        tabs.first(where: { $0.id == selectedTabID }) ?? tabs[0]
    }

    var selectedIndex: Int {
        tabs.firstIndex(where: { $0.id == selectedTabID }) ?? 0
    }

    init() {
        let first = BrowserTab()
        self.tabs = [first]
        self.selectedTabID = first.id
        bindTabUpdates()
    }

    @discardableResult
    func addTab(startURL: URL = URLHelpers.homeURL, select: Bool = true) -> BrowserTab {
        let tab = BrowserTab(startURL: startURL)
        tabs.append(tab)
        bindTabUpdates()
        if select {
            selectedTabID = tab.id
        }
        return tab
    }

    func closeTab(_ id: UUID) {
        guard tabs.count > 1, let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = selectedTabID == id
        tabs.remove(at: index)
        bindTabUpdates()
        if wasSelected {
            let newIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[newIndex].id
        }
    }

    func select(_ id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        selectedTabID = id
    }

    func selectNext() {
        guard tabs.count > 1 else { return }
        let next = (selectedIndex + 1) % tabs.count
        selectedTabID = tabs[next].id
    }

    func selectPrevious() {
        guard tabs.count > 1 else { return }
        let prev = (selectedIndex - 1 + tabs.count) % tabs.count
        selectedTabID = tabs[prev].id
    }

    /// So ContentView re-renders when the active page's isLoading / progress changes.
    private func bindTabUpdates() {
        tabCancellables.removeAll()
        for tab in tabs {
            tab.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &tabCancellables)
        }
    }
}
