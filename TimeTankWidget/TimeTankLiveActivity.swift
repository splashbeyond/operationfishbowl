import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Lock Screen / Notification Banner

struct TimeTankLiveActivityLockScreenView: View {
    let context: ActivityViewContext<TimeTankActivityAttributes>

    var body: some View {
        let pollution = context.state.pollutionLevel

        ZStack {
            // Warm white base
            Color(red: 1.0, green: 0.98, blue: 0.96)

            // Water fill from bottom
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [waterColor(for: pollution).opacity(0.28), waterColor(for: pollution).opacity(0.62)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geo.size.height * (0.06 + pollution * 0.94))
                }
            }

            // Content
            HStack(spacing: 16) {
                // Finn
                Image(finnFaceName(for: pollution))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 2)

                VStack(alignment: .leading, spacing: 5) {
                    Text(statusTitle(for: pollution))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.22, green: 0.18, blue: 0.14))

                    Text("\(Int((pollution * 100).rounded()))% murky")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(pollutionColor(for: pollution))

                    if let expiresAt = context.state.bypassExpiresAt, expiresAt > Date() {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(timerInterval: Date.now...expiresAt, countsDown: true)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundColor(Color(red: 0.55, green: 0.40, blue: 0.28))
                    } else if context.state.isShieldActive {
                        Label("Shield is back", systemImage: "lock.fill")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.18, green: 0.52, blue: 0.36))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .activityBackgroundTint(Color(red: 1.0, green: 0.98, blue: 0.96))
    }
}

// MARK: - Dynamic Island Views

struct TimeTankDICompactLeading: View {
    let pollution: Double
    var body: some View {
        Image(finnFaceName(for: pollution))
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .padding(.leading, 4)
    }
}

struct TimeTankDICompactTrailing: View {
    let pollution: Double
    var body: some View {
        Text("\(Int((pollution * 100).rounded()))%")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(pollutionColor(for: pollution))
            .padding(.trailing, 4)
    }
}

struct TimeTankDIMinimal: View {
    let pollution: Double
    var body: some View {
        Image(finnFaceName(for: pollution))
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }
}

struct TimeTankDIExpandedView: View {
    let context: ActivityViewContext<TimeTankActivityAttributes>

    var body: some View {
        let pollution = context.state.pollutionLevel

        HStack(spacing: 14) {
            Image(finnFaceName(for: pollution))
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("Finn's Tank")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)

                Text("\(Int((pollution * 100).rounded()))% murky")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(pollutionColor(for: pollution))

                if let expiresAt = context.state.bypassExpiresAt, expiresAt > Date() {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text(timerInterval: Date.now...expiresAt, countsDown: true)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Widget Configuration

struct TimeTankLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTankActivityAttributes.self) { context in
            TimeTankLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            let pollution = context.state.pollutionLevel
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(finnFaceName(for: pollution))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int((pollution * 100).rounded()))%")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(pollutionColor(for: pollution))
                        Text("murky")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let expiresAt = context.state.bypassExpiresAt, expiresAt > Date() {
                        HStack(spacing: 5) {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                            Text("Shield returns in ")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                            + Text(timerInterval: Date.now...expiresAt, countsDown: true)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundColor(Color(red: 0.72, green: 0.42, blue: 0.18))
                        .padding(.bottom, 6)
                    } else if context.state.isShieldActive {
                        Label("Shield is back on", systemImage: "lock.fill")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.18, green: 0.52, blue: 0.36))
                            .padding(.bottom, 6)
                    }
                }
            } compactLeading: {
                TimeTankDICompactLeading(pollution: pollution)
            } compactTrailing: {
                TimeTankDICompactTrailing(pollution: pollution)
            } minimal: {
                TimeTankDIMinimal(pollution: pollution)
            }
        }
    }
}

// MARK: - Shared Helpers (file-private)

private func finnFaceName(for pollution: Double) -> String {
    switch pollution {
    case 0..<0.2:   return "FinnMascot"
    case 0.2..<0.4: return "FinnMascotAlert"
    case 0.4..<0.8: return "FinnMascotWorried"
    case 0.8..<1.0: return "FinnMascotSuffering"
    default:        return "FinnMascotDistressed"
    }
}

private func waterColor(for pollution: Double) -> Color {
    if pollution < 0.5 {
        let t = pollution / 0.5
        return Color(red: t * 1.0, green: 0.75 - t * 0.08, blue: 0.65 - t * 0.40)
    } else {
        let t = (pollution - 0.5) / 0.5
        return Color(red: 1.0 - t * 0.29, green: 0.67 - t * 0.27, blue: 0.25 - t * 0.14)
    }
}

private func pollutionColor(for pollution: Double) -> Color {
    if pollution < 0.2 { return Color(red: 0.18, green: 0.62, blue: 0.54) }
    if pollution < 0.4 { return Color(red: 0.90, green: 0.55, blue: 0.20) }
    if pollution < 0.8 { return Color(red: 0.88, green: 0.38, blue: 0.18) }
    return Color(red: 0.72, green: 0.18, blue: 0.12)
}

private func statusTitle(for pollution: Double) -> String {
    if pollution < 0.2 { return "Finn is watching." }
    if pollution < 0.4 { return "Finn is concerned." }
    if pollution < 0.6 { return "Finn is worried." }
    if pollution < 0.8 { return "Finn really needs you." }
    if pollution < 1.0 { return "Finn can barely breathe." }
    return "Finn is suffering."
}
