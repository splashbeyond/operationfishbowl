import DeviceActivity
import SwiftUI

@main
struct TimeTankReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TimeTankUsageReport { configuration in
            TimeTankUsageReportView(configuration: configuration)
        }
        TimeTankBudgetTrackerReport { configuration in
            TimeTankBudgetTrackerReportView(configuration: configuration)
        }
        TimeTankAllAppsReport { configuration in
            TimeTankScreenTimeReportView(configuration: configuration)
        }
    }
}

struct TimeTankUsageReport: DeviceActivityReportScene {
    let context = DeviceActivityReport.Context(TimeTankConstants.reportContextIdentifier)
    let content: (TimeTankUsageReportConfiguration) -> TimeTankUsageReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TimeTankUsageReportConfiguration {
        var configuration = TimeTankUsageReportConfiguration()
        var appMap: [String: (duration: TimeInterval, pickups: Int)] = [:]

        for await activityData in data {
            configuration.lastUpdated = max(configuration.lastUpdated ?? activityData.lastUpdatedDate, activityData.lastUpdatedDate)

            for await segment in activityData.activitySegments {
                configuration.totalDuration += segment.totalActivityDuration
                configuration.pickupsWithoutAppActivity += segment.totalPickupsWithoutApplicationActivity

                if let firstPickup = segment.firstPickup {
                    configuration.firstPickup = min(configuration.firstPickup ?? firstPickup, firstPickup)
                }

                if let longestActivity = segment.longestActivity {
                    configuration.longestSession = max(configuration.longestSession, longestActivity.duration)
                }

                for await category in segment.categories {
                    for await application in category.applications {
                        configuration.selectedAppDuration += application.totalActivityDuration
                        configuration.appPickups += application.numberOfPickups
                        configuration.notifications += application.numberOfNotifications

                        let name = application.application.localizedDisplayName ?? "App"
                        let existing = appMap[name] ?? (duration: 0, pickups: 0)
                        appMap[name] = (
                            duration: existing.duration + application.totalActivityDuration,
                            pickups: existing.pickups + application.numberOfPickups
                        )
                    }

                    for await webDomain in category.webDomains {
                        configuration.webDuration += webDomain.totalActivityDuration
                    }
                }
            }
        }

        configuration.topApps = appMap
            .map { AppUsageItem(name: $0.key, duration: $0.value.duration, pickups: $0.value.pickups) }
            .sorted { $0.duration > $1.duration }

        return configuration
    }
}

struct TimeTankBudgetTrackerReport: DeviceActivityReportScene {
    let context = DeviceActivityReport.Context(TimeTankConstants.budgetTrackerContextIdentifier)
    let content: (TimeTankUsageReportConfiguration) -> TimeTankBudgetTrackerReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TimeTankUsageReportConfiguration {
        var configuration = TimeTankUsageReportConfiguration()
        let defaults = UserDefaults(suiteName: TimeTankConstants.appGroupIdentifier)
        let storedBudget = defaults?.integer(forKey: TimeTankDefaultsKey.dailyBudgetMinutes) ?? 0
        configuration.budgetMinutes = storedBudget > 0 ? storedBudget : TimeTankConstants.defaultBudgetMinutes

        for await activityData in data {
            configuration.lastUpdated = max(configuration.lastUpdated ?? activityData.lastUpdatedDate, activityData.lastUpdatedDate)

            for await segment in activityData.activitySegments {
                configuration.totalDuration += segment.totalActivityDuration

                for await category in segment.categories {
                    for await application in category.applications {
                        configuration.selectedAppDuration += application.totalActivityDuration
                    }

                    for await webDomain in category.webDomains {
                        configuration.webDuration += webDomain.totalActivityDuration
                    }
                }
            }
        }

        return configuration
    }
}

struct TimeTankAllAppsReport: DeviceActivityReportScene {
    let context = DeviceActivityReport.Context(TimeTankConstants.allAppsReportContextIdentifier)
    let content: (TimeTankUsageReportConfiguration) -> TimeTankScreenTimeReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TimeTankUsageReportConfiguration {
        var configuration = TimeTankUsageReportConfiguration()

        for await activityData in data {
            configuration.lastUpdated = activityData.lastUpdatedDate
            for await segment in activityData.activitySegments {
                configuration.totalDuration += segment.totalActivityDuration
            }
        }

        return configuration
    }
}

struct AppUsageItem {
    let name: String
    let duration: TimeInterval
    let pickups: Int
}

struct TimeTankUsageReportConfiguration {
    var totalDuration: TimeInterval = 0
    var selectedAppDuration: TimeInterval = 0
    var webDuration: TimeInterval = 0
    var longestSession: TimeInterval = 0
    var appPickups = 0
    var pickupsWithoutAppActivity = 0
    var notifications = 0
    var firstPickup: Date?
    var lastUpdated: Date?
    var topApps: [AppUsageItem] = []
    var sevenDayAverage: TimeInterval = 0
    var budgetMinutes: Int = TimeTankConstants.defaultBudgetMinutes

    var displayedDuration: TimeInterval {
        selectedAppDuration > 0 ? selectedAppDuration : totalDuration
    }

    var totalPickups: Int {
        appPickups + pickupsWithoutAppActivity
    }
}

struct TimeTankBudgetTrackerReportView: View {
    let configuration: TimeTankUsageReportConfiguration

    @Environment(\.colorScheme) private var colorScheme

    private let tideOrange = Color(red: 1.0, green: 0.42, blue: 0.169)
    private let tankTeal = Color(red: 0.0, green: 0.749, blue: 0.647)
    private let amber = Color(red: 1.0, green: 0.671, blue: 0.251)
    private let muddyBrown = Color(red: 0.71, green: 0.396, blue: 0.114)

    private var textDark: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.921, blue: 0.89)
            : Color(red: 0.11, green: 0.102, blue: 0.094)
    }

    private var textMuted: Color {
        colorScheme == .dark
            ? Color(red: 0.704, green: 0.655, blue: 0.621)
            : Color(red: 0.522, green: 0.475, blue: 0.459)
    }

    private var usedSeconds: TimeInterval {
        configuration.displayedDuration
    }

    private var budgetSeconds: TimeInterval {
        TimeInterval(max(1, configuration.budgetMinutes) * 60)
    }

    private var remainingSeconds: TimeInterval {
        max(0, budgetSeconds - usedSeconds)
    }

    private var progress: Double {
        min(1, max(0, usedSeconds / budgetSeconds))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(durationString(remainingSeconds))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(progress >= 1 ? muddyBrown : textDark)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                Text("left")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(textMuted)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(tideOrange.opacity(0.16))
                    Capsule()
                        .fill(progressColor)
                        .frame(width: max(6, geo.size.width * progress))
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(durationString(usedSeconds)) used")
                Spacer()
                Text("\(durationString(budgetSeconds)) budget")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(textMuted)

            if let lastUpdated = configuration.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(textMuted.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        if progress >= 1 { return muddyBrown }
        if progress >= 0.8 { return amber }
        if progress >= 0.55 { return tideOrange }
        return tankTeal
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int((interval / 60).rounded(.down)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 { return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

struct TimeTankUsageReportView: View {
    let configuration: TimeTankUsageReportConfiguration

    @Environment(\.colorScheme) private var colorScheme

    private let tideOrange = Color(red: 1.0, green: 0.42, blue: 0.169)
    private var textDark: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.921, blue: 0.89)
            : Color(red: 0.11, green: 0.102, blue: 0.094)
    }
    private var textMuted: Color {
        colorScheme == .dark
            ? Color(red: 0.704, green: 0.655, blue: 0.621)
            : Color(red: 0.522, green: 0.475, blue: 0.459)
    }
    private var peachFoam: Color {
        colorScheme == .dark
            ? Color(red: 0.31, green: 0.227, blue: 0.173)
            : Color(red: 1.0, green: 0.91, blue: 0.839)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Total time header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(durationString(configuration.displayedDuration))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(textDark)
                Text("today")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(textMuted)
                Spacer()
                if let lastUpdated = configuration.lastUpdated {
                    Text(lastUpdated.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(textMuted)
                }
            }
            .padding(.bottom, 14)

            if configuration.topApps.isEmpty {
                Text("No usage recorded yet today.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(textMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(configuration.topApps.enumerated()), id: \.offset) { index, app in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(tideOrange.opacity(0.12))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(app.name.prefix(1)).uppercased())
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(tideOrange)
                            }

                        Text(app.name)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(textDark)
                            .lineLimit(1)

                        Spacer()

                        Text(durationString(app.duration))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(textMuted)
                    }
                    .padding(.vertical, 9)

                    if index < configuration.topApps.count - 1 {
                        Divider()
                            .background(peachFoam)
                    }
                }
            }
        }
        .padding(14)
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 { return "\(hours)h \(remaining)m" }
        if minutes == 0 { return "< 1m" }
        return "\(minutes)m"
    }
}

struct TimeTankScreenTimeReportView: View {
    let configuration: TimeTankUsageReportConfiguration

    @Environment(\.colorScheme) private var colorScheme

    private var textDark: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.921, blue: 0.89)
            : Color(red: 0.11, green: 0.102, blue: 0.094)
    }
    private var textMuted: Color {
        colorScheme == .dark
            ? Color(red: 0.704, green: 0.655, blue: 0.621)
            : Color(red: 0.522, green: 0.475, blue: 0.459)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(durationString(configuration.totalDuration))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(textDark)
                Text("today")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(textMuted)
                Spacer()
                if let lastUpdated = configuration.lastUpdated {
                    Text(lastUpdated.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(textMuted)
                }
            }

            Text("Total device usage today")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 { return "\(hours)h \(remaining)m" }
        if minutes == 0 { return "< 1m" }
        return "\(minutes)m"
    }
}
