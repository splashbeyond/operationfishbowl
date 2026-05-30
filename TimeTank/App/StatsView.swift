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
                            Text("SCREEN TIME REPORT")
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

    private var reportContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(TimeTankConstants.reportContextIdentifier)
    }
}
