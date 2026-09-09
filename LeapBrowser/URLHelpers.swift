import Foundation

enum URLHelpers {
    static let homeURL = URL(string: "https://www.google.com")!

    /// Turns an address-bar string into a URL. Bare hosts get `https://`.
    /// Strings that look like search queries go to Google Search.
    static func url(fromAddressBar text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
            return url
        }

        let looksLikeHost =
            trimmed.contains(".")
            && !trimmed.contains(" ")
            && !trimmed.hasPrefix("?")

        if looksLikeHost {
            return URL(string: "https://\(trimmed)")
        }

        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        return components.url
    }
}
