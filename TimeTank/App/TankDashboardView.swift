import DeviceActivity
import SwiftUI

struct TankDashboardView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    header

                    FocusTankView(pollutionLevel: model.pollutionLevel)
                        .frame(height: 360)
                        .padding(.bottom, -70)

                    pollutionDisplay

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(model.statusMessage, systemImage: "drop.fill")
                                .font(.timeTankHeading(17))
                                .foregroundStyle(Color.textDark)

                            BudgetProgressBar(progress: model.pollutionLevel)

                            Text(model.budgetBoundaryText)
                                .font(.timeTankBody(14))
                                .foregroundStyle(Color.textMuted)
                        }
                    }

                    if !model.isMonitoringEnabled {
                        PrimaryButton(title: "Start TimeTank", systemImage: "play.fill") {
                            model.startMonitoring()
                        }
                    }

                    screenTimeCard
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIMETANK")
                    .font(.timeTankTitle())
                    .foregroundStyle(Color.tideOrange)

                Text("Keep the water clean.")
                    .font(.timeTankBody())
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            CurrentsBadge(balance: model.currentsBalance)
        }
    }

    private var pollutionDisplay: some View {
        VStack(spacing: 4) {
            Text("\(Int(model.pollutionLevel * 100))")
                .font(.timeTankMetric(56))
                .foregroundStyle(pollutionColor)
            Text("% murky")
                .font(.timeTankBody(13))
                .foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, -12)
    }

    private var screenTimeCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Distraction Time")
                    .font(.timeTankHeading(17))
                    .foregroundStyle(Color.textDark)

                if model.isRunningInSimulator {
                    Text("Real usage reports require a signed iPhone. Simulator only exercises the demo flow.")
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.textMuted)
                } else if !model.hasSelection {
                    Text("Pick distractions first. TimeTank only judges the apps you choose.")
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.textMuted)
                } else if model.isAuthorized {
                    DeviceActivityReport(
                        .init(TimeTankConstants.reportContextIdentifier),
                        filter: todayFilter
                    )
                    .frame(minHeight: 200)
                } else {
                    Text("Approve Screen Time access to see your usage.")
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
    }

    private var pollutionColor: Color {
        if model.pollutionLevel >= 1 { return .muddyBrown }
        if model.pollutionLevel >= 0.8 { return .amber }
        return .tankTeal
    }

    private var todayFilter: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval()
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone]),
            applications: model.selection.applicationTokens,
            categories: model.selection.categoryTokens,
            webDomains: model.selection.webDomainTokens
        )
    }
}

struct BudgetProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.peachFoam)

                Capsule()
                    .fill(fillColor)
                    .frame(width: max(6, proxy.size.width * progress))
            }
        }
        .frame(height: 6)
    }

    private var fillColor: Color {
        if progress >= 1 { return .muddyBrown }
        if progress >= 0.8 { return .amber }
        return .tankTeal
    }
}

struct CurrentsBadge: View {
    let balance: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "centsign.circle.fill")
            Text("\(balance)")
        }
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(Color.tideOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.tideOrange.opacity(0.15))
        .clipShape(Capsule())
    }
}
