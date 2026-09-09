import SwiftUI

struct ContentView: View {
    private let startURL = URL(string: "https://example.com")!

    var body: some View {
        WebView(url: startURL)
            .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
