import Combine
import SwiftUI

struct ThemePalette {
    var void: Color
    var panel: Color
    var well: Color
    var neonPink: Color
    var neonCyan: Color
    var neonViolet: Color
    var neonAmber: Color
    var mist: Color
    var alert: Color
    var preferredColorScheme: ColorScheme
    var prefersDarkWebContent: Bool

    var chromeGradient: LinearGradient {
        LinearGradient(
            colors: chromeGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var auraGradient: LinearGradient {
        LinearGradient(
            colors: [neonPink.opacity(0.85), neonViolet.opacity(0.75), neonCyan.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var chromeGradientColors: [Color]
}

enum AppTheme: String, CaseIterable, Identifiable {
    case tokyo
    case light
    case hacker
    case matrix

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tokyo: return "Tokyo 2226"
        case .light: return "Light"
        case .hacker: return "Hacker"
        case .matrix: return "Matrix"
        }
    }

    var subtitle: String {
        switch self {
        case .tokyo: return "Neon on black / grey"
        case .light: return "Bright chrome · sites prefer light"
        case .hacker: return "VS Code–style dark"
        case .matrix: return "Green terminal rain"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .tokyo:
            return ThemePalette(
                void: Color(red: 0.05, green: 0.05, blue: 0.05),
                panel: Color(red: 0.11, green: 0.11, blue: 0.11),
                well: Color(red: 0.16, green: 0.16, blue: 0.16),
                neonPink: Color(red: 1.0, green: 0.18, blue: 0.72),
                neonCyan: Color(red: 0.15, green: 0.95, blue: 0.95),
                neonViolet: Color(red: 0.62, green: 0.28, blue: 1.0),
                neonAmber: Color(red: 1.0, green: 0.72, blue: 0.20),
                mist: Color(red: 0.70, green: 0.70, blue: 0.72),
                alert: Color(red: 1.0, green: 0.30, blue: 0.35),
                preferredColorScheme: .dark,
                prefersDarkWebContent: true,
                chromeGradientColors: [
                    Color(red: 0.02, green: 0.02, blue: 0.02),
                    Color(red: 0.12, green: 0.12, blue: 0.12),
                    Color(red: 0.07, green: 0.07, blue: 0.07),
                ]
            )
        case .light:
            return ThemePalette(
                void: Color(red: 0.96, green: 0.96, blue: 0.97),
                panel: Color(red: 1.0, green: 1.0, blue: 1.0),
                well: Color(red: 0.92, green: 0.93, blue: 0.95),
                neonPink: Color(red: 0.75, green: 0.12, blue: 0.45),
                neonCyan: Color(red: 0.05, green: 0.45, blue: 0.85),
                neonViolet: Color(red: 0.40, green: 0.28, blue: 0.85),
                neonAmber: Color(red: 0.85, green: 0.50, blue: 0.05),
                mist: Color(red: 0.35, green: 0.37, blue: 0.40),
                alert: Color(red: 0.85, green: 0.15, blue: 0.15),
                preferredColorScheme: .light,
                prefersDarkWebContent: false,
                chromeGradientColors: [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.93, green: 0.94, blue: 0.96),
                    Color(red: 0.96, green: 0.96, blue: 0.97),
                ]
            )
        case .hacker:
            // VS Code Dark+ inspired
            return ThemePalette(
                void: Color(red: 0.12, green: 0.12, blue: 0.12),       // #1e1e1e
                panel: Color(red: 0.15, green: 0.15, blue: 0.15),      // #252526
                well: Color(red: 0.18, green: 0.18, blue: 0.18),       // #2d2d2d
                neonPink: Color(red: 0.81, green: 0.57, blue: 0.47),   // #ce9178
                neonCyan: Color(red: 0.31, green: 0.79, blue: 0.69),   // #4ec9b0
                neonViolet: Color(red: 0.40, green: 0.65, blue: 0.90), // #569cd6
                neonAmber: Color(red: 0.86, green: 0.86, blue: 0.67),  // #dcdcaa
                mist: Color(red: 0.83, green: 0.83, blue: 0.83),       // #d4d4d4
                alert: Color(red: 0.95, green: 0.28, blue: 0.33),
                preferredColorScheme: .dark,
                prefersDarkWebContent: true,
                chromeGradientColors: [
                    Color(red: 0.12, green: 0.12, blue: 0.12),
                    Color(red: 0.18, green: 0.18, blue: 0.18),
                    Color(red: 0.14, green: 0.14, blue: 0.14),
                ]
            )
        case .matrix:
            return ThemePalette(
                void: Color(red: 0.02, green: 0.05, blue: 0.02),
                panel: Color(red: 0.04, green: 0.09, blue: 0.04),
                well: Color(red: 0.06, green: 0.14, blue: 0.06),
                neonPink: Color(red: 0.20, green: 0.90, blue: 0.35),
                neonCyan: Color(red: 0.00, green: 1.0, blue: 0.25),
                neonViolet: Color(red: 0.00, green: 0.70, blue: 0.20),
                neonAmber: Color(red: 0.55, green: 1.0, blue: 0.55),
                mist: Color(red: 0.45, green: 0.75, blue: 0.45),
                alert: Color(red: 0.70, green: 1.0, blue: 0.70),
                preferredColorScheme: .dark,
                prefersDarkWebContent: true,
                chromeGradientColors: [
                    Color(red: 0.01, green: 0.04, blue: 0.01),
                    Color(red: 0.05, green: 0.12, blue: 0.05),
                    Color(red: 0.02, green: 0.07, blue: 0.02),
                ]
            )
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let storageKey = "leap.browser.theme"

    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: storageKey)
        }
    }

    var palette: ThemePalette { theme.palette }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let stored = AppTheme(rawValue: raw) {
            theme = stored
        } else {
            theme = .tokyo
        }
    }
}

/// Convenience accessors that always resolve against the active theme.
enum CyberpunkTheme {
    static var void: Color { ThemeManager.shared.palette.void }
    static var panel: Color { ThemeManager.shared.palette.panel }
    static var well: Color { ThemeManager.shared.palette.well }
    static var neonPink: Color { ThemeManager.shared.palette.neonPink }
    static var neonCyan: Color { ThemeManager.shared.palette.neonCyan }
    static var neonViolet: Color { ThemeManager.shared.palette.neonViolet }
    static var neonAmber: Color { ThemeManager.shared.palette.neonAmber }
    static var mist: Color { ThemeManager.shared.palette.mist }
    static var alert: Color { ThemeManager.shared.palette.alert }
    static var chromeGradient: LinearGradient { ThemeManager.shared.palette.chromeGradient }
    static var auraGradient: LinearGradient { ThemeManager.shared.palette.auraGradient }
    static var preferredColorScheme: ColorScheme { ThemeManager.shared.palette.preferredColorScheme }
    static var prefersDarkWebContent: Bool { ThemeManager.shared.palette.prefersDarkWebContent }
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
            TextField("Search or enter address", text: $text)
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
