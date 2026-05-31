import SwiftUI
import UIKit

extension TimeTankAppearanceMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

extension Color {
    static let warmWhite = Color.dynamic(
        light: UIColor(red: 1.0, green: 0.973, blue: 0.949, alpha: 1),
        dark: UIColor(red: 0.09, green: 0.082, blue: 0.074, alpha: 1)
    )
    static let cardBackground = Color.dynamic(
        light: .white,
        dark: UIColor(red: 0.145, green: 0.133, blue: 0.121, alpha: 1)
    )
    static let peachFoam = Color.dynamic(
        light: UIColor(red: 1.0, green: 0.91, blue: 0.839, alpha: 1),
        dark: UIColor(red: 0.31, green: 0.227, blue: 0.173, alpha: 1)
    )
    static let tideOrange = Color(red: 1.0, green: 0.42, blue: 0.169)
    static let coral = Color(red: 1.0, green: 0.549, blue: 0.38)
    static let textDark = Color.dynamic(
        light: UIColor(red: 0.11, green: 0.102, blue: 0.094, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.921, blue: 0.89, alpha: 1)
    )
    static let textMuted = Color.dynamic(
        light: UIColor(red: 0.522, green: 0.475, blue: 0.459, alpha: 1),
        dark: UIColor(red: 0.704, green: 0.655, blue: 0.621, alpha: 1)
    )
    static let tankTeal = Color(red: 0.0, green: 0.749, blue: 0.647)
    static let amber = Color(red: 1.0, green: 0.671, blue: 0.251)
    static let muddyBrown = Color(red: 0.71, green: 0.396, blue: 0.114)

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension Font {
    static func timeTankTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func timeTankHeading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func timeTankBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func timeTankButton(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func timeTankMetric(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    // All-caps section labels — always pair with .tracking(1.2)
    static func timeTankLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

struct TimeTankCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.peachFoam, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.timeTankButton())
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.tideOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.tideOrange.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
