import Foundation
import WebKit

/// Hides Google Search sponsored blocks. CSS-only and search-path gated so the homepage cannot go blank.
enum GoogleAdHiding {
    static func makeUserScript() -> WKUserScript {
        WKUserScript(
            source: userScriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    static let userScriptSource: String = #"""
    (function () {
      try {
        var host = (location.hostname || "").toLowerCase();
        if (!/(^|\.)google\./.test(host)) return;
        // Only SERP pages — never the homepage / account / consent flows.
        if (!/\/search/.test(location.pathname || "")) return;
        if (window.__leapGoogleAdsCSS) return;
        window.__leapGoogleAdsCSS = true;

        var selectors = [
          "#tads",
          "#tadsb",
          "#bottomads",
          "#tvcap",
          ".commercial-unit-desktop-top",
          ".commercial-unit-desktop-rhs",
          ".cu-container",
          "[data-text-ad]",
          "[data-ad-slot]"
        ];

        var style = document.createElement("style");
        style.id = "leap-hide-google-ads";
        style.textContent = selectors.join(",") +
          "{display:none!important;visibility:hidden!important;height:0!important;max-height:0!important;overflow:hidden!important;}";
        (document.documentElement || document.head || document.body).appendChild(style);
      } catch (e) {}
    })();
    """#
}
