import Combine
import Foundation
import WebKit

final class BrowserViewModel: ObservableObject {
    @Published var addressText: String = URLHelpers.homeURL.absoluteString
    @Published var pageTitle: String = "Leap Browser"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0
    @Published var currentURL: URL = URLHelpers.homeURL

    /// Fired when a navigation finishes with a usable URL (for history logging).
    var onPageCommitted: ((URL, String) -> Void)?

    weak var webView: WKWebView?

    func attach(_ webView: WKWebView) {
        self.webView = webView
        if webView.url == nil {
            load(currentURL)
        }
        refreshNavigationState()
    }

    func submitAddressBar() {
        guard let url = URLHelpers.url(fromAddressBar: addressText) else { return }
        load(url)
    }

    func load(_ url: URL) {
        currentURL = url
        addressText = url.absoluteString
        var request = URLRequest(url: url)
        LanguagePreferences.apply(to: &request)
        webView?.load(request)
    }

    func goHome() {
        load(URLHelpers.homeURL)
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func refreshNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
        isLoading = webView?.isLoading ?? false
        estimatedProgress = webView?.estimatedProgress ?? 0
        if let url = webView?.url {
            currentURL = url
            addressText = url.absoluteString
        }
        if let title = webView?.title, !title.isEmpty {
            pageTitle = title
        }
    }

    func notifyPageCommitted() {
        guard let url = webView?.url else { return }
        let title = (webView?.title?.isEmpty == false ? webView?.title : nil) ?? url.host ?? url.absoluteString
        currentURL = url
        pageTitle = title
        addressText = url.absoluteString
        onPageCommitted?(url, title)
    }
}
