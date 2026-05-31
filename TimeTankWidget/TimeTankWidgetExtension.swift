import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct TimeTankWidgetEntry: TimelineEntry {
    let date: Date
    let pollutionLevel: Double
}

// MARK: - Provider

struct TimeTankWidgetProvider: TimelineProvider {
    private static let appGroup = "group.com.piperstudio.timetank"
    private static let pollutionKey = "pollutionLevel"

    func placeholder(in context: Context) -> TimeTankWidgetEntry {
        TimeTankWidgetEntry(date: Date(), pollutionLevel: 0.45)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeTankWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTankWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> TimeTankWidgetEntry {
        let defaults = UserDefaults(suiteName: Self.appGroup)
        let pollution = defaults?.double(forKey: Self.pollutionKey) ?? 0
        return TimeTankWidgetEntry(date: Date(), pollutionLevel: pollution)
    }
}

// MARK: - Small Widget View

struct TimeTankSmallWidgetView: View {
    let entry: TimeTankWidgetEntry

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Explicit background (same cream as medium)
                Color(red: 1.0, green: 0.98, blue: 0.96)

                // Water rising from bottom — height grows with pollution
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [waterColor.opacity(0.22), waterColor.opacity(0.55)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geo.size.height * (0.08 + entry.pollutionLevel * 0.55))
                }

                // Finn — sized relative to widget, pushed up to leave room for label
                Image(finnFaceName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: geo.size.width * 0.68,
                        height: geo.size.height * 0.70
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 24)

                // Status label pinned to bottom
                Text(percentLabel)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(labelColor)
                    .padding(.bottom, 10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var finnFaceName: String {
        switch entry.pollutionLevel {
        case 0..<0.2:   return "FinnMascot"
        case 0.2..<0.4: return "FinnMascotAlert"
        case 0.4..<0.8: return "FinnMascotWorried"
        case 0.8..<1.0: return "FinnMascotSuffering"
        default:        return "FinnMascotDistressed"
        }
    }

    private var waterColor: Color {
        let p = entry.pollutionLevel
        if p < 0.5 {
            let t = p / 0.5
            return Color(red: t * 1.0, green: 0.75 - t * 0.08, blue: 0.65 - t * 0.40)
        } else {
            let t = (p - 0.5) / 0.5
            return Color(red: 1.0 - t * 0.29, green: 0.67 - t * 0.27, blue: 0.25 - t * 0.14)
        }
    }

    private var percentLabel: String {
        let pct = Int((entry.pollutionLevel * 100).rounded())
        if pct == 0 { return "Clean" }
        return "\(pct)% Murky"
    }

    private var labelColor: Color {
        entry.pollutionLevel > 0.5
            ? Color(red: 0.72, green: 0.18, blue: 0.12)
            : Color(red: 0.22, green: 0.18, blue: 0.14)
    }
}

// MARK: - Medium Widget View

struct TimeTankMediumWidgetView: View {
    let entry: TimeTankWidgetEntry

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 1.0, green: 0.98, blue: 0.96)

                // Water fill
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [waterColor.opacity(0.28), waterColor.opacity(0.60)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: waterFillHeight(in: geo.size.height))
                }

                HStack(spacing: 0) {
                    // Left — Finn
                    Image(finnFaceName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.height * 0.72)
                        .padding(.leading, 12)

                    // Right — stats
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Finn's Tank")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.22, green: 0.18, blue: 0.14))

                        Text(percentLabel)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(pollutionColor)
                            .minimumScaleFactor(0.7)

                        Text(statusMessage)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.40, green: 0.35, blue: 0.30))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 14)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func waterFillHeight(in totalHeight: CGFloat) -> CGFloat {
        let fill = 0.06 + entry.pollutionLevel * 0.94
        return totalHeight * fill
    }

    private var finnFaceName: String {
        switch entry.pollutionLevel {
        case 0..<0.2:   return "FinnMascot"
        case 0.2..<0.4: return "FinnMascotAlert"
        case 0.4..<0.8: return "FinnMascotWorried"
        case 0.8..<1.0: return "FinnMascotSuffering"
        default:        return "FinnMascotDistressed"
        }
    }

    private var waterColor: Color {
        let p = entry.pollutionLevel
        if p < 0.5 {
            let t = p / 0.5
            return Color(red: t * 1.0, green: 0.75 - t * 0.08, blue: 0.65 - t * 0.40)
        } else {
            let t = (p - 0.5) / 0.5
            return Color(red: 1.0 - t * 0.29, green: 0.67 - t * 0.27, blue: 0.25 - t * 0.14)
        }
    }

    private var pollutionColor: Color {
        let p = entry.pollutionLevel
        if p < 0.2 { return Color(red: 0.18, green: 0.62, blue: 0.54) }
        if p < 0.4 { return Color(red: 0.90, green: 0.55, blue: 0.20) }
        if p < 0.8 { return Color(red: 0.88, green: 0.38, blue: 0.18) }
        return Color(red: 0.72, green: 0.18, blue: 0.12)
    }

    private var percentLabel: String {
        let pct = Int((entry.pollutionLevel * 100).rounded())
        if pct == 0 { return "Clean" }
        return "\(pct)%"
    }

    private var statusMessage: String {
        let p = entry.pollutionLevel
        if p == 0     { return "The tank is clean. Great work." }
        if p < 0.2    { return "Just a little murky. Stay on track." }
        if p < 0.4    { return "Finn is getting worried." }
        if p < 0.6    { return "The water's clouding up fast." }
        if p < 0.8    { return "Finn really needs you to stop." }
        if p < 1.0    { return "Finn can barely breathe." }
        return "The tank is fully polluted."
    }
}

// MARK: - Shared Helpers

private func widgetWaterColor(for pollution: Double) -> Color {
    if pollution < 0.5 {
        let t = pollution / 0.5
        return Color(red: t * 1.0, green: 0.75 - t * 0.08, blue: 0.65 - t * 0.40)
    } else {
        let t = (pollution - 0.5) / 0.5
        return Color(red: 1.0 - t * 0.29, green: 0.67 - t * 0.27, blue: 0.25 - t * 0.14)
    }
}

// MARK: - Family-Aware Container

struct TimeTankWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimeTankWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            TimeTankMediumWidgetView(entry: entry)
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
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.96),
                            widgetWaterColor(for: entry.pollutionLevel).opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Finn's Tank")
        .description("Check in on how murky the tank is.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
