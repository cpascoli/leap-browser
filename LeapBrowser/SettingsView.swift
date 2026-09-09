import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared
    @Query private var history: [HistoryEntry]

    @State private var showClearHistoryConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            themeManager.theme = theme
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: themeManager.theme == theme ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(themeManager.theme == theme ? CyberpunkTheme.neonCyan : CyberpunkTheme.mist)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.title)
                                        .font(.system(.body, design: .default).weight(.semibold))
                                        .foregroundStyle(CyberpunkTheme.neonCyan)
                                    Text(theme.subtitle)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(CyberpunkTheme.mist)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .listRowBackground(CyberpunkTheme.panel)
                    }
                } header: {
                    Text("THEME")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.mist)
                }

                Section {
                    LabeledContent("Home") {
                        Text("google.com")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(CyberpunkTheme.neonCyan)
                    }
                    LabeledContent("Search") {
                        Text("Google")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(CyberpunkTheme.neonCyan)
                    }
                    LabeledContent("Site theme") {
                        Text(themeManager.palette.prefersDarkWebContent ? "Prefer dark" : "Prefer light")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(CyberpunkTheme.neonAmber)
                    }
                    LabeledContent("Languages") {
                        Text("en-GB → en → it → th")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(CyberpunkTheme.neonPink)
                    }
                } header: {
                    Text("NAVIGATION")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.mist)
                }
                .listRowBackground(CyberpunkTheme.panel)

                Section {
                    Button(role: .destructive) {
                        showClearHistoryConfirm = true
                    } label: {
                        HStack {
                            Text("Clear browsing history")
                            Spacer()
                            Text("\(history.count)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(CyberpunkTheme.mist)
                        }
                    }
                    .disabled(history.isEmpty)
                } header: {
                    Text("DATA")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.mist)
                }
                .listRowBackground(CyberpunkTheme.panel)

                Section {
                    LabeledContent("App") {
                        Text("Leap Browser")
                            .font(.system(.caption, design: .monospaced))
                    }
                    LabeledContent("Build") {
                        Text("0.1.0 · Neo-Tōkyō 2226")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(CyberpunkTheme.mist)
                    }
                } header: {
                    Text("ABOUT")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(CyberpunkTheme.mist)
                }
                .listRowBackground(CyberpunkTheme.panel)
            }
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #endif
            .background(CyberpunkTheme.void.ignoresSafeArea())
            .navigationTitle("SETTINGS")
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
            #if os(iOS)
            .toolbarBackground(CyberpunkTheme.panel, for: .navigationBar)
            #endif
            .confirmationDialog("Clear all history?", isPresented: $showClearHistoryConfirm, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) {
                    for entry in history {
                        modelContext.delete(entry)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .preferredColorScheme(themeManager.palette.preferredColorScheme)
        .tint(CyberpunkTheme.neonCyan)
    }
}
