import SwiftUI

struct TabCarouselView: View {
    @ObservedObject var tabManager: TabManager
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tabManager.tabs) { tab in
                        tabCard(tab)
                    }
                }
                .padding(16)
            }
            .background(CyberpunkTheme.void.ignoresSafeArea())
            .navigationTitle("PAGES")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.neonCyan)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        tabManager.addTab()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(CyberpunkTheme.neonPink)
                    }
                    .help("New page")
                }
            }
            #if os(iOS)
            .toolbarBackground(CyberpunkTheme.panel, for: .navigationBar)
            #endif
        }
        .preferredColorScheme(themeManager.palette.preferredColorScheme)
    }

    private func tabCard(_ tab: BrowserTab) -> some View {
        let selected = tab.id == tabManager.selectedTabID
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(tab.title)
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(CyberpunkTheme.neonCyan)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                if tabManager.tabs.count > 1 {
                    Button {
                        tabManager.closeTab(tab.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CyberpunkTheme.mist)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(CyberpunkTheme.well))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(tab.browser.currentURL.absoluteString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(CyberpunkTheme.mist)
                .lineLimit(3)
            Spacer(minLength: 0)
            Text(selected ? "ACTIVE" : "TAP TO OPEN")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(selected ? CyberpunkTheme.neonAmber : CyberpunkTheme.neonPink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CyberpunkTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    selected ? CyberpunkTheme.neonCyan.opacity(0.9) : CyberpunkTheme.neonPink.opacity(0.35),
                    lineWidth: selected ? 2 : 1
                )
        )
        .shadow(color: (selected ? CyberpunkTheme.neonCyan : CyberpunkTheme.neonPink).opacity(0.25), radius: 10)
        .onTapGesture {
            tabManager.select(tab.id)
            dismiss()
        }
    }
}
