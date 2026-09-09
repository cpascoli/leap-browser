import SwiftUI
import WebKit

enum WebKitShared {
    static let processPool = WKProcessPool()
}

#if os(iOS)
struct WebView: UIViewRepresentable {
    @ObservedObject var browser: BrowserViewModel
    var onSwipeToNextTab: (() -> Void)?
    var onSwipeToPreviousTab: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(browser: browser, onSwipeToNextTab: onSwipeToNextTab, onSwipeToPreviousTab: onSwipeToPreviousTab)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        // Back/forward edge swipes fight tab switching — use the back button instead.
        webView.allowsBackForwardNavigationGestures = false
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.observe(webView)
        context.coordinator.installTabSwipe(on: webView)
        browser.attach(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.onSwipeToNextTab = onSwipeToNextTab
        context.coordinator.onSwipeToPreviousTab = onSwipeToPreviousTab
        context.coordinator.browser = browser
    }
}
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    @ObservedObject var browser: BrowserViewModel
    var onSwipeToNextTab: (() -> Void)?
    var onSwipeToPreviousTab: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(browser: browser, onSwipeToNextTab: onSwipeToNextTab, onSwipeToPreviousTab: onSwipeToPreviousTab)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.observe(webView)
        context.coordinator.installTabSwipe(on: webView)
        browser.attach(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.onSwipeToNextTab = onSwipeToNextTab
        context.coordinator.onSwipeToPreviousTab = onSwipeToPreviousTab
        context.coordinator.browser = browser
    }
}
#endif

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
    var browser: BrowserViewModel
    var onSwipeToNextTab: (() -> Void)?
    var onSwipeToPreviousTab: (() -> Void)?
    private var observations: [NSKeyValueObservation] = []
    #if os(iOS)
    private weak var pan: UIPanGestureRecognizer?
    #elseif os(macOS)
    private var monitor: Any?
    #endif

    init(
        browser: BrowserViewModel,
        onSwipeToNextTab: (() -> Void)?,
        onSwipeToPreviousTab: (() -> Void)?
    ) {
        self.browser = browser
        self.onSwipeToNextTab = onSwipeToNextTab
        self.onSwipeToPreviousTab = onSwipeToPreviousTab
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

    #if os(iOS)
    func installTabSwipe(on webView: WKWebView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        webView.addGestureRecognizer(pan)
        self.pan = pan
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let translation = gesture.translation(in: gesture.view)
        let velocity = gesture.velocity(in: gesture.view)
        let dx = translation.x
        let dy = translation.y
        guard abs(dx) > abs(dy) * 1.6, abs(dx) > 80 || abs(velocity.x) > 700 else { return }
        if dx < 0 {
            onSwipeToNextTab?()
        } else {
            onSwipeToPreviousTab?()
        }
    }
    #elseif os(macOS)
    func installTabSwipe(on webView: WKWebView) {
        // Trackpad swipe between pages isn't exposed cleanly; use SwiftUI swipe on chrome
        // plus Option+scroll / two-finger horizontal via magnify alternative — also listen for swipe.
        let swipe = NSPanGestureRecognizer(target: self, action: #selector(handleMacPan(_:)))
        webView.addGestureRecognizer(swipe)
    }

    @objc private func handleMacPan(_ gesture: NSPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let t = gesture.translation(in: gesture.view)
        guard abs(t.x) > abs(t.y) * 1.6, abs(t.x) > 100 else { return }
        if t.x < 0 {
            onSwipeToNextTab?()
        } else {
            onSwipeToPreviousTab?()
        }
    }
    #endif

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor in browser.refreshNavigationState() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            browser.refreshNavigationState()
            browser.notifyPageCommitted()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in browser.refreshNavigationState() }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in browser.refreshNavigationState() }
    }
}

#if os(iOS)
extension Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: pan.view)
        return abs(v.x) > abs(v.y)
    }
}
#endif

private func makeConfiguration() -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    configuration.processPool = WebKitShared.processPool
    return configuration
}
