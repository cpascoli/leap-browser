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
    var onScroll: ((CGFloat, Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            browser: browser,
            onSwipeToNextTab: onSwipeToNextTab,
            onSwipeToPreviousTab: onSwipeToPreviousTab,
            onScroll: onScroll
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration(coordinator: context.coordinator))
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.delegate = context.coordinator
        webView.scrollView.alwaysBounceVertical = true
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
        context.coordinator.onScroll = onScroll
        context.coordinator.browser = browser
    }
}
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    @ObservedObject var browser: BrowserViewModel
    var onSwipeToNextTab: (() -> Void)?
    var onSwipeToPreviousTab: (() -> Void)?
    var onScroll: ((CGFloat, Bool) -> Void)?
    var onMacScroll: ((CGFloat, CGFloat) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            browser: browser,
            onSwipeToNextTab: onSwipeToNextTab,
            onSwipeToPreviousTab: onSwipeToPreviousTab,
            onScroll: onScroll,
            onMacScroll: onMacScroll
        )
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration(coordinator: context.coordinator))
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.observe(webView)
        context.coordinator.installTabSwipe(on: webView)
        context.coordinator.installScrollBridge(on: webView)
        browser.attach(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        applyPreferredDarkAppearance(to: webView)
        context.coordinator.onSwipeToNextTab = onSwipeToNextTab
        context.coordinator.onSwipeToPreviousTab = onSwipeToPreviousTab
        context.coordinator.onScroll = onScroll
        context.coordinator.onMacScroll = onMacScroll
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

final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var browser: BrowserViewModel
    var onSwipeToNextTab: (() -> Void)?
    var onSwipeToPreviousTab: (() -> Void)?
    var onScroll: ((CGFloat, Bool) -> Void)?
    var onMacScroll: ((CGFloat, CGFloat) -> Void)?
    private var observations: [NSKeyValueObservation] = []
    #if os(iOS)
    private weak var pan: UIPanGestureRecognizer?
    #endif

    init(
        browser: BrowserViewModel,
        onSwipeToNextTab: (() -> Void)?,
        onSwipeToPreviousTab: (() -> Void)?,
        onScroll: ((CGFloat, Bool) -> Void)?,
        onMacScroll: ((CGFloat, CGFloat) -> Void)? = nil
    ) {
        self.browser = browser
        self.onSwipeToNextTab = onSwipeToNextTab
        self.onSwipeToPreviousTab = onSwipeToPreviousTab
        self.onScroll = onScroll
        self.onMacScroll = onMacScroll
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

    func installScrollBridge(on webView: WKWebView) {
        // Script already injected via configuration userContentController.
    }
    #endif

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "leapScroll",
              let body = message.body as? [String: Any],
              let y = body["y"] as? Double else { return }
        let delta = body["delta"] as? Double ?? 0
        Task { @MainActor in
            onMacScroll?(CGFloat(y), CGFloat(delta))
            onScroll?(CGFloat(y), false)
        }
    }

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
extension Coordinator: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        onScroll?(y, scrollView.isDragging || scrollView.isTracking)
    }
}

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

private func makeConfiguration(coordinator: Coordinator) -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    configuration.processPool = WebKitShared.processPool
    let contentController = configuration.userContentController
    contentController.removeScriptMessageHandler(forName: "leapScroll")
    contentController.add(coordinator, name: "leapScroll")
    let js = """
    (function() {
      if (window.__leapScrollInstalled) return;
      window.__leapScrollInstalled = true;
      var lastY = window.scrollY || 0;
      window.addEventListener('scroll', function() {
        var y = window.scrollY || document.documentElement.scrollTop || 0;
        var delta = lastY - y;
        lastY = y;
        try { window.webkit.messageHandlers.leapScroll.postMessage({ y: y, delta: delta }); } catch(e) {}
      }, { passive: true });
      window.addEventListener('wheel', function(e) {
        var y = window.scrollY || document.documentElement.scrollTop || 0;
        try { window.webkit.messageHandlers.leapScroll.postMessage({ y: y, delta: e.deltaY * -1 }); } catch(err) {}
      }, { passive: true });
    })();
    """
    contentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    return configuration
}
