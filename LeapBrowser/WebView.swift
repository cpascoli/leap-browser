import SwiftUI
import WebKit

#if os(iOS)
struct WebView: UIViewRepresentable {
    @ObservedObject var browser: BrowserViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(browser: browser)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.observe(webView)
        browser.attach(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        applyPreferredDarkAppearance(to: webView)
    }
}
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    @ObservedObject var browser: BrowserViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(browser: browser)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.observe(webView)
        browser.attach(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        applyPreferredDarkAppearance(to: webView)
    }
}
#endif

/// Ask WebKit to report `prefers-color-scheme: dark` so sites with a night theme opt in.
func applyPreferredDarkAppearance(to webView: WKWebView) {
    #if os(iOS)
    webView.overrideUserInterfaceStyle = .dark
    if #available(iOS 15.0, *) {
        webView.underPageBackgroundColor = UIColor(CyberpunkTheme.void)
    }
    #elseif os(macOS)
    webView.appearance = NSAppearance(named: .darkAqua)
    if #available(macOS 12.0, *) {
        webView.underPageBackgroundColor = NSColor(CyberpunkTheme.void)
    }
    #endif
}

final class Coordinator: NSObject, WKNavigationDelegate {
    let browser: BrowserViewModel
    private var observations: [NSKeyValueObservation] = []

    init(browser: BrowserViewModel) {
        self.browser = browser
    }

    func observe(_ webView: WKWebView) {
        observations = [
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.browser.refreshNavigationState() }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.browser.refreshNavigationState() }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.browser.refreshNavigationState() }
            },
            webView.observe(\.title, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.browser.refreshNavigationState() }
            },
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.browser.refreshNavigationState() }
            },
        ]
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor in browser.refreshNavigationState() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in browser.refreshNavigationState() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in browser.refreshNavigationState() }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in browser.refreshNavigationState() }
    }
}

private func makeConfiguration() -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    return configuration
}
