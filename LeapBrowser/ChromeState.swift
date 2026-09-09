import Combine
import Foundation

@MainActor
final class ChromeState: ObservableObject {
    @Published private(set) var isVisible: Bool = true

    private var lastOffsetY: CGFloat = 0
    private let pullRevealThreshold: CGFloat = -48
    private let hideAfterScrollY: CGFloat = 28

    func reveal() {
        guard !isVisible else { return }
        isVisible = true
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
    }

    /// Drive chrome from page scroll.
    /// Reveal when the user is at the top and pulls down (negative offset / overscroll).
    /// Hide once they scroll into the page content.
    func handleScroll(offsetY: CGFloat, isDragging: Bool) {
        if offsetY <= pullRevealThreshold {
            reveal()
        } else if offsetY > hideAfterScrollY {
            // Scrolling down into content — tuck chrome away.
            if isDragging || offsetY > lastOffsetY + 1.5 {
                hide()
            }
        }
        lastOffsetY = offsetY
    }

    func handleMacScroll(scrollY: CGFloat, deltaY: CGFloat) {
        if scrollY <= 1, deltaY > 4 {
            // At top and scrolling "up" / pulling content down.
            reveal()
        } else if scrollY > hideAfterScrollY, deltaY < -1 {
            hide()
        }
    }
}
