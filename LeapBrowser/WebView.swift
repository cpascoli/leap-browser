import SwiftUI
import WebKit

#if os(iOS)
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Milestone 1: single hardcoded start URL; navigation chrome arrives in M2.
    }
}
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Milestone 1: single hardcoded start URL; navigation chrome arrives in M2.
    }
}
#endif

private func makeConfiguration() -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    // Milestone 1 placeholder — UA, content blockers, and JS policies land in later milestones.
    return configuration
}
