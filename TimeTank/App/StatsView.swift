import DeviceActivity
import SwiftUI

struct StatsView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TODAY")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Int(model.pollutionLevel * 100))")
                                    .font(.timeTankMetric(56))
                                    .foregroundStyle(Color.textDark)
                                Text("% murky")
                                    .font(.timeTankHeading(18))
                                    .foregroundStyle(Color.textMuted)
                            }

                            BudgetProgressBar(progress: model.pollutionLevel)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DISTRACTION APPS")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            if model.isRunningInSimulator {
                                Text("Real app usage, pickups, notifications, and first pickup only render on a signed iPhone with Screen Time authorization.")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            } else if model.hasSelection {
                                DeviceActivityReport(reportContext, filter: reportFilter)
                                    .frame(minHeight: 220)
                            } else {
                                Text("Pick distractions first. The report uses those selected app, category, and web tokens.")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            }
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR SCREEN TIME")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            if model.isRunningInSimulator {
                                Text("Total iPhone usage across all apps renders on a signed device with Screen Time authorization.")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            } else {
                                DeviceActivityReport(allAppsReportContext, filter: allAppsReportFilter)
                                    .frame(minHeight: 80)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Stats")
        }
    }

    private var reportFilter: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 24 * 60 * 60)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: model.selection.applicationTokens,
            categories: model.selection.categoryTokens,
            webDomains: model.selection.webDomainTokens
        )
    }

    private var allAppsReportFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let start = calendar.startOfDay(for: sevenDaysAgo)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) ?? today
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: end)),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }

    private var reportContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(TimeTankConstants.reportContextIdentifier)
    }

    private var allAppsReportContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(TimeTankConstants.allAppsReportContextIdentifier)
    }
}
