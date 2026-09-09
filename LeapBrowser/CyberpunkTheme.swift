import SwiftUI

enum CyberpunkTheme {
    /// Near-black void
    static let void = Color(red: 0.05, green: 0.05, blue: 0.05)
    /// Raised panel / chrome bar
    static let panel = Color(red: 0.11, green: 0.11, blue: 0.11)
    /// Soft inner well (address field)
    static let well = Color(red: 0.16, green: 0.16, blue: 0.16)
    /// Hot magenta signage
    static let neonPink = Color(red: 1.0, green: 0.18, blue: 0.72)
    /// Rain-slick cyan
    static let neonCyan = Color(red: 0.15, green: 0.95, blue: 0.95)
    /// Electric violet
    static let neonViolet = Color(red: 0.62, green: 0.28, blue: 1.0)
    /// Warm kanji-lamp amber
    static let neonAmber = Color(red: 1.0, green: 0.72, blue: 0.20)
    /// Muted street text
    static let mist = Color(red: 0.70, green: 0.70, blue: 0.72)
    /// Danger / delete
    static let alert = Color(red: 1.0, green: 0.30, blue: 0.35)

    static let chromeGradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.02, blue: 0.02),
            Color(red: 0.12, green: 0.12, blue: 0.12),
            Color(red: 0.07, green: 0.07, blue: 0.07),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let auraGradient = LinearGradient(
        colors: [neonPink.opacity(0.85), neonViolet.opacity(0.75), neonCyan.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct NeonIconButton: View {
    let systemName: String
    var tint: Color = CyberpunkTheme.neonCyan
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? tint : tint.opacity(0.25))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CyberpunkTheme.well.opacity(enabled ? 0.95 : 0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tint.opacity(enabled ? 0.55 : 0.15), lineWidth: 1)
                )
                .shadow(color: enabled ? tint.opacity(0.35) : .clear, radius: 6, y: 0)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct CyberpunkAddressField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CyberpunkTheme.neonPink)
            TextField("NEURAL LINK // URL OR QUERY", text: $text)
                .textFieldStyle(.plain)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(CyberpunkTheme.neonCyan)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                #endif
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(CyberpunkTheme.well)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            CyberpunkTheme.neonPink.opacity(0.7),
                            CyberpunkTheme.neonCyan.opacity(0.5),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: CyberpunkTheme.neonPink.opacity(0.2), radius: 8, y: 0)
    }
}

struct CyberpunkToast: View {
    let message: String

    var body: some View {
        Text(message.uppercased())
            .font(.system(.caption, design: .monospaced).weight(.bold))
            .tracking(1.2)
            .foregroundStyle(CyberpunkTheme.void)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(CyberpunkTheme.auraGradient)
            )
            .shadow(color: CyberpunkTheme.neonCyan.opacity(0.45), radius: 10, y: 0)
    }
}
