import SwiftUI

extension Color {
    static let warmWhite = Color(red: 1.0, green: 0.973, blue: 0.949)
    static let peachFoam = Color(red: 1.0, green: 0.91, blue: 0.839)
    static let tideOrange = Color(red: 1.0, green: 0.42, blue: 0.169)
    static let coral = Color(red: 1.0, green: 0.549, blue: 0.38)
    static let textDark = Color(red: 0.11, green: 0.102, blue: 0.094)
    static let textMuted = Color(red: 0.522, green: 0.475, blue: 0.459)
    static let tankTeal = Color(red: 0.0, green: 0.749, blue: 0.647)
    static let amber = Color(red: 1.0, green: 0.671, blue: 0.251)
    static let muddyBrown = Color(red: 0.71, green: 0.396, blue: 0.114)
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
            .background(Color.white)
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
