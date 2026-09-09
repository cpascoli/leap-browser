import Foundation

enum LanguagePreferences {
    /// English first, then Italian (occasional IT sites), then Thai for Bangkok-local fallbacks.
    /// Note: `en-EN` is not a real BCP-47 tag; we use `en-GB` + `en`.
    static let preferredLanguageCodes = ["en-GB", "en", "it-IT", "it", "th-TH", "th"]

    static let acceptLanguageHeader =
        "en-GB,en;q=0.9,it-IT;q=0.8,it;q=0.7,th-TH;q=0.6,th;q=0.5"

    /// Influences WKWebView's default `Accept-Language` / `navigator.languages` for link navigations.
    static func applyAtLaunch() {
        UserDefaults.standard.set(preferredLanguageCodes, forKey: "AppleLanguages")
    }

    static func apply(to request: inout URLRequest) {
        request.setValue(acceptLanguageHeader, forHTTPHeaderField: "Accept-Language")
    }
}
