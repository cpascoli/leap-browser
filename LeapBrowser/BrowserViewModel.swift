import Combine
import Foundation
import WebKit

@MainActor
final class BrowserViewModel: ObservableObject {
    @Published var addressText: String = URLHelpers.homeURL.absoluteString
    @Published var pageTitle: String = "Leap Browser"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentURL: URL = URLHelpers.homeURL

    weak var webView: WKWebView?

    func attach(_ webView: WKWebView) {
        self.webView = webView
        if webView.url == nil {
            load(URLHelpers.homeURL)
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
        webView?.load(URLRequest(url: url))
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
        if let url = webView?.url {
            currentURL = url
            addressText = url.absoluteString
        }
        if let title = webView?.title, !title.isEmpty {
            pageTitle = title
        }
    }
}
