import Foundation
import WebKit

/// Hides Google Search sponsored / ad blocks inside WKWebView (until full WKContentRuleList ad blocking).
enum GoogleAdHiding {
    static let scriptNameHint = "leap-hide-google-ads"

    static let userScriptSource: String = #"""
    (function () {
      try {
        var host = (location.hostname || "").toLowerCase();
        if (!/(^|\.)google\./.test(host) && host !== "google.com") return;
        if (window.__leapGoogleAdsHidden) return;
        window.__leapGoogleAdsHidden = true;

        var selectors = [
          "#tads",
          "#tadsb",
          "#bottomads",
          "#tvcap",
          "#taw",
          "#dzww3d",
          ".commercial-unit-desktop-top",
          ".commercial-unit-desktop-rhs",
          ".cu-container",
          ".pla-unit-container",
          "[data-text-ad]",
          "[data-ad-slot]",
          "[data-ad-info]",
          "div[aria-label='Ads']",
          "div[aria-label='Anuncios']",
          "div[aria-label='Advertisements']"
        ];

        function ensureStyle() {
          var style = document.getElementById("leap-hide-google-ads");
          if (!style) {
            style = document.createElement("style");
            style.id = "leap-hide-google-ads";
            (document.documentElement || document.head || document.body).appendChild(style);
          }
          style.textContent =
            selectors.join(",") +
            "{display:none!important;visibility:hidden!important;height:0!important;max-height:0!important;overflow:hidden!important;margin:0!important;padding:0!important;}";
        }

        var sponsoredRe = /^(Sponsored|Ad|Ads|Anuncio|Anuncios|Sponsorizzato|Gesponsert|Sponsorisé)$/i;

        function hideLabeledSponsored() {
          var nodes = document.querySelectorAll("span, div, a, font");
          for (var i = 0; i < nodes.length; i++) {
            var el = nodes[i];
            if (!el || el.childElementCount > 2) continue;
            var text = (el.textContent || "").replace(/\s+/g, " ").trim();
            if (!sponsoredRe.test(text)) continue;
            var node = el;
            for (var depth = 0; depth < 10 && node; depth++) {
              var parent = node.parentElement;
              if (!parent) break;
              if (parent.id === "search" || parent.id === "rso" || parent.id === "center_col") {
                node.style.setProperty("display", "none", "important");
                break;
              }
              if (parent.id === "tads" || parent.id === "tvcap" || parent.id === "tadsb") {
                parent.style.setProperty("display", "none", "important");
                break;
              }
              node = parent;
            }
          }
        }

        function run() {
          ensureStyle();
          hideLabeledSponsored();
        }

        run();
        var obs = new MutationObserver(function () { run(); });
        obs.observe(document.documentElement, { childList: true, subtree: true });
        document.addEventListener("DOMContentLoaded", run, { once: true });
      } catch (e) {}
    })();
    """#

    static func makeUserScript() -> WKUserScript {
        WKUserScript(
            source: userScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }
}
