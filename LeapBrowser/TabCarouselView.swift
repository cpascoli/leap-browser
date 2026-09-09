import SwiftUI

struct TabCarouselView: View {
    @ObservedObject var tabManager: TabManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(tabManager.tabs) { tab in
                            tabCard(tab)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                Button {
                    tabManager.addTab()
                    dismiss()
                } label: {
                    Label("NEW TAB", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(CyberpunkTheme.void)
                        .background(CyberpunkTheme.auraGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                Text("Swipe the page left/right to switch tabs · Hold + for this carousel")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(CyberpunkTheme.mist)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CyberpunkTheme.void.ignoresSafeArea())
            .navigationTitle("OPEN TABS")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func tabCard(_ tab: BrowserTab) -> some View {
        let selected = tab.id == tabManager.selectedTabID
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tab.title)
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(CyberpunkTheme.neonCyan)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if tabManager.tabs.count > 1 {
                    Button {
                        tabManager.closeTab(tab.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CyberpunkTheme.mist)
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
        .frame(width: 200, height: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CyberpunkTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? CyberpunkTheme.neonCyan.opacity(0.9) : CyberpunkTheme.neonPink.opacity(0.35), lineWidth: selected ? 2 : 1)
        )
        .shadow(color: (selected ? CyberpunkTheme.neonCyan : CyberpunkTheme.neonPink).opacity(0.25), radius: 10)
        .onTapGesture {
            tabManager.select(tab.id)
            dismiss()
        }
    }
}
