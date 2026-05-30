import DeviceActivity
import SwiftUI

@main
struct TimeTankReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TimeTankUsageReport { configuration in
            TimeTankUsageReportView(configuration: configuration)
        }
    }
}

struct TimeTankUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = TimeTankConstants.reportContext
    let content: (TimeTankUsageReportConfiguration) -> TimeTankUsageReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TimeTankUsageReportConfiguration {
        var configuration = TimeTankUsageReportConfiguration()

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

    var displayedDuration: TimeInterval {
        selectedAppDuration > 0 ? selectedAppDuration : totalDuration
    }

    var totalPickups: Int {
        appPickups + pickupsWithoutAppActivity
    }
}

struct TimeTankUsageReportView: View {
    let configuration: TimeTankUsageReportConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(durationString(configuration.displayedDuration))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("today")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metric("Pickups", "\(configuration.totalPickups)", "Direct and device pickups")
                metric("Notifications", "\(configuration.notifications)", "From selected apps")
                metric("First pickup", firstPickupString, "Today")
                metric("Longest", durationString(configuration.longestSession), "Single session")
            }

            if let lastUpdated = configuration.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }

    private var firstPickupString: String {
        guard let firstPickup = configuration.firstPickup else { return "None" }
        return firstPickup.formatted(date: .omitted, time: .shortened)
    }

    private func metric(_ title: String, _ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(caption)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }

        return "\(remainingMinutes)m"
    }
}
