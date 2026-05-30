import DeviceActivity
import SwiftUI

@main
struct TimeTankReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TimeTankUsageReport { configuration in
            TimeTankUsageReportView(configuration: configuration)
        }
        TimeTankAllAppsReport { configuration in
            TimeTankUsageReportView(configuration: configuration)
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

        // Write overflow seconds to shared defaults so the main app can recalculate pollution
        if let sharedDefaults = UserDefaults(suiteName: TimeTankConstants.appGroupIdentifier) {
            let budgetMinutes = sharedDefaults.integer(forKey: TimeTankDefaultsKey.dailyBudgetMinutes)
            let effectiveBudget = Double(budgetMinutes > 0 ? budgetMinutes : TimeTankConstants.defaultBudgetMinutes) * 60.0
            let overflow = max(0.0, configuration.selectedAppDuration - effectiveBudget)
            sharedDefaults.set(overflow, forKey: TimeTankDefaultsKey.overflowSeconds)
        }

        return configuration
    }
}

struct TimeTankAllAppsReport: DeviceActivityReportScene {
    let context = DeviceActivityReport.Context(TimeTankConstants.allAppsReportContextIdentifier)
    let content: (TimeTankUsageReportConfiguration) -> TimeTankUsageReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TimeTankUsageReportConfiguration {
        var configuration = TimeTankUsageReportConfiguration()
        var appMap: [String: (duration: TimeInterval, pickups: Int)] = [:]

        for await activityData in data {
            configuration.lastUpdated = max(configuration.lastUpdated ?? activityData.lastUpdatedDate, activityData.lastUpdatedDate)

            for await segment in activityData.activitySegments {
                configuration.totalDuration += segment.totalActivityDuration

                for await category in segment.categories {
                    for await application in category.applications {
                        let name = application.application.localizedDisplayName ?? "App"
                        let existing = appMap[name] ?? (duration: 0, pickups: 0)
                        appMap[name] = (
                            duration: existing.duration + application.totalActivityDuration,
                            pickups: existing.pickups + application.numberOfPickups
                        )
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

    var displayedDuration: TimeInterval {
        selectedAppDuration > 0 ? selectedAppDuration : totalDuration
    }

    var totalPickups: Int {
        appPickups + pickupsWithoutAppActivity
    }
}

struct TimeTankUsageReportView: View {
    let configuration: TimeTankUsageReportConfiguration

    private let tideOrange = Color(red: 1.0, green: 0.42, blue: 0.169)
    private let textDark   = Color(red: 0.11, green: 0.102, blue: 0.094)
    private let textMuted  = Color(red: 0.522, green: 0.475, blue: 0.459)
    private let peachFoam  = Color(red: 1.0, green: 0.91, blue: 0.839)

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
