import Foundation

enum LanguagePreferences {
    /// English first (app is en-GB), Thai next so Bangkok-local content can still win when English isn't offered.
    /// Note: `en-EN` is not a real BCP-47 tag; we use `en-GB` + `en`.
    static let preferredLanguageCodes = ["en-GB", "en", "th-TH", "th"]

    static let acceptLanguageHeader =
        "en-GB,en;q=0.9,th-TH;q=0.8,th;q=0.7"

    /// Influences WKWebView's default `Accept-Language` / `navigator.languages` for link navigations.
    static func applyAtLaunch() {
        UserDefaults.standard.set(preferredLanguageCodes, forKey: "AppleLanguages")
    }

    static func apply(to request: inout URLRequest) {
        request.setValue(acceptLanguageHeader, forHTTPHeaderField: "Accept-Language")
    }
}
