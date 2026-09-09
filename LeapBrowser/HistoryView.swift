import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HistoryEntry.visitedAt, order: .reverse) private var entries: [HistoryEntry]

    var onOpen: (URL) -> Void

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "NO SIGNAL LOG",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Pages you visit will appear here.")
                    )
                    .foregroundStyle(CyberpunkTheme.mist)
                } else {
                    List {
                        ForEach(entries, id: \.id) { entry in
                            Button {
                                if let url = entry.url {
                                    onOpen(url)
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.title.isEmpty ? entry.urlString : entry.title)
                                        .font(.system(.subheadline).weight(.semibold))
                                        .foregroundStyle(CyberpunkTheme.neonCyan)
                                        .lineLimit(1)
                                    Text(entry.urlString)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(CyberpunkTheme.mist)
                                        .lineLimit(1)
                                    Text(entry.visitedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(CyberpunkTheme.mist.opacity(0.7))
                                }
                                .padding(.vertical, 2)
                            }
                            .listRowBackground(CyberpunkTheme.panel.opacity(0.9))
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    #if os(iOS)
                    .scrollContentBackground(.hidden)
                    #endif
                }
            }
            .background(CyberpunkTheme.void.ignoresSafeArea())
            .navigationTitle("HISTORY LOG")
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
                    Button("CLEAR", role: .destructive) {
                        clearAll()
                    }
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(CyberpunkTheme.alert)
                    .disabled(entries.isEmpty)
                }
            }
            #if os(iOS)
            .toolbarBackground(CyberpunkTheme.panel, for: .navigationBar)
            #endif
        }
        .preferredColorScheme(themeManager.palette.preferredColorScheme)
        .tint(CyberpunkTheme.neonCyan)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }

    private func clearAll() {
        for entry in entries {
            modelContext.delete(entry)
        }
    }
}
