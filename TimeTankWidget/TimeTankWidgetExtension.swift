import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct TimeTankWidgetEntry: TimelineEntry {
    let date: Date
    let pollutionLevel: Double
    let bypassCount: Int
    let currentsBalance: Int
    let isMonitoringEnabled: Bool
    let isBudgetExceededToday: Bool
    let bypassExpiresAt: Date?
}

// MARK: - Provider

struct TimeTankWidgetProvider: TimelineProvider {
    private enum Defaults {
        static let appGroupIdentifier = "group.com.piperstudio.timetank"
        static let pollutionLevel = "pollutionLevel"
        static let bypassCount = "bypassCount"
        static let currentsBalance = "currentsBalance"
        static let isMonitoringEnabled = "isMonitoringEnabled"
        static let isBudgetExceededToday = "isBudgetExceededToday"
        static let bypassExpiresAt = "bypassExpiresAt"
    }

    func placeholder(in context: Context) -> TimeTankWidgetEntry {
        TimeTankWidgetEntry(
            date: Date(),
            pollutionLevel: 0.58,
            bypassCount: 2,
            currentsBalance: 7,
            isMonitoringEnabled: true,
            isBudgetExceededToday: false,
            bypassExpiresAt: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeTankWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTankWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> TimeTankWidgetEntry {
        let defaults = UserDefaults(suiteName: Defaults.appGroupIdentifier)
        return TimeTankWidgetEntry(
            date: Date(),
            pollutionLevel: clamp(defaults?.double(forKey: Defaults.pollutionLevel) ?? 0),
            bypassCount: max(0, defaults?.integer(forKey: Defaults.bypassCount) ?? 0),
            currentsBalance: max(0, defaults?.integer(forKey: Defaults.currentsBalance) ?? 0),
            isMonitoringEnabled: defaults?.bool(forKey: Defaults.isMonitoringEnabled) ?? false,
            isBudgetExceededToday: defaults?.bool(forKey: Defaults.isBudgetExceededToday) ?? false,
            bypassExpiresAt: defaults?.object(forKey: Defaults.bypassExpiresAt) as? Date
        )
    }

    private func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

// MARK: - Widget Views

struct TimeTankSmallWidgetView: View {
    let entry: TimeTankWidgetEntry

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(widgetFinnFaceName(for: entry.pollutionLevel))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: .black.opacity(0.28), radius: 4, y: 2)

            Text("\(widgetPercent(for: entry.pollutionLevel))%")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 6, y: 1)
                .monospacedDigit()
                .lineLimit(1)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .unredacted()
    }
}

struct TimeTankMediumWidgetView: View {
    let entry: TimeTankWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(widgetFinnFaceName(for: entry.pollutionLevel))
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
                .shadow(color: .black.opacity(0.35), radius: 7, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(widgetPercent(for: entry.pollutionLevel))%")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)

                Text(widgetStatusTitle(for: entry.pollutionLevel))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(widgetPollutionColor(for: entry.pollutionLevel))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(widgetStatusLong(for: entry))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .unredacted()
    }
}

struct TimeTankLargeFinnWidgetView: View {
    let entry: TimeTankWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(widgetFinnFaceName(for: entry.pollutionLevel))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
                .shadow(color: .black.opacity(0.38), radius: 10, y: 6)

            VStack(spacing: 5) {
                Text("\(widgetPercent(for: entry.pollutionLevel))%")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)

                Text(widgetStatusTitle(for: entry.pollutionLevel))
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(widgetPollutionColor(for: entry.pollutionLevel))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(widgetStatusLong(for: entry))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .unredacted()
    }
}

// MARK: - Shared Widget Components

private struct WidgetBackground: View {
    let pollution: Double

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.07, blue: 0.08),
                Color(red: 0.04, green: 0.15, blue: 0.17),
                widgetWaterColor(for: pollution).opacity(0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Family-Aware Container

struct TimeTankWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimeTankWidgetEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            TimeTankSmallWidgetView(entry: entry)
        case .systemMedium:
            TimeTankMediumWidgetView(entry: entry)
        case .systemLarge:
            TimeTankLargeFinnWidgetView(entry: entry)
        default:
            TimeTankSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct TimeTankWidget: Widget {
    let kind = "TimeTankWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTankWidgetProvider()) { entry in
            TimeTankWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground(pollution: entry.pollutionLevel)
                }
                .widgetURL(URL(string: "timetank://home"))
                .unredacted()
        }
        .configurationDisplayName("Finn's Tank")
        .description("Check Finn's current tank pollution.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Shared Helpers

private func widgetFinnFaceName(for pollution: Double) -> String {
    switch pollution {
    case 0..<0.2:   return "FinnMascot"
    case 0.2..<0.4: return "FinnMascotAlert"
    case 0.4..<0.8: return "FinnMascotWorried"
    case 0.8..<1.0: return "FinnMascotSuffering"
    default:        return "FinnMascotDistressed"
    }
}

private func widgetWaterColor(for pollution: Double) -> Color {
    if pollution < 0.5 {
        let t = pollution / 0.5
        return Color(red: 0.06 + t * 0.94, green: 0.78 - t * 0.10, blue: 0.68 - t * 0.42)
    } else {
        let t = (pollution - 0.5) / 0.5
        return Color(red: 1.0 - t * 0.24, green: 0.62 - t * 0.23, blue: 0.24 - t * 0.12)
    }
}

private func widgetPollutionColor(for pollution: Double) -> Color {
    if pollution < 0.2 { return Color(red: 0.15, green: 0.90, blue: 0.76) }
    if pollution < 0.4 { return Color(red: 1.0, green: 0.72, blue: 0.25) }
    if pollution < 0.8 { return Color(red: 1.0, green: 0.42, blue: 0.17) }
    return Color(red: 1.0, green: 0.24, blue: 0.16)
}

private func widgetPercent(for pollution: Double) -> Int {
    Int((min(1, max(0, pollution)) * 100).rounded())
}

private func widgetStatusShort(for pollution: Double) -> String {
    if pollution <= 0.01 { return "Clean" }
    if pollution < 0.2 { return "Clear" }
    if pollution < 0.4 { return "Murky" }
    if pollution < 0.8 { return "Worried" }
    if pollution < 1.0 { return "Critical" }
    return "Full"
}

private func widgetStatusTitle(for pollution: Double) -> String {
    if pollution <= 0.01 { return "Crystal Clean" }
    if pollution < 0.2 { return "Finn Is Happy" }
    if pollution < 0.4 { return "Getting Murky" }
    if pollution < 0.8 { return "Finn Is Worried" }
    if pollution < 1.0 { return "Critical Water" }
    return "Fully Polluted"
}

private func widgetStatusLong(for entry: TimeTankWidgetEntry) -> String {
    if let expiresAt = entry.bypassExpiresAt, expiresAt > Date() {
        return "Bypass is active. Finn is holding his breath."
    }
    if entry.isBudgetExceededToday {
        return "Budget spent. TimeTank is protecting Finn."
    }
    if !entry.isMonitoringEnabled {
        return "Open TimeTank to set up protection."
    }

    let pollution = entry.pollutionLevel
    if pollution <= 0.01 { return "Keep the water clean today." }
    if pollution < 0.2 { return "A little cloudy, but Finn is okay." }
    if pollution < 0.4 { return "Slow down before the tank clouds up." }
    if pollution < 0.8 { return "Finn needs a break from the device." }
    if pollution < 1.0 { return "Protect the rest of today." }
    return "Tomorrow resets the tank."
}
