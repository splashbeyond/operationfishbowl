import ManagedSettings
import SwiftUI

struct TankDashboardView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    header

                    FocusTankView(pollutionLevel: model.pollutionLevel) {
                        guard model.isBudgetExceededToday else { return }
                        model.refresh()
                        if model.isMonitoringEnabled && model.hasSelection {
                            ScreenTimeShielding.applyShield(for: model.selection)
                        }
                    }
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

                    budgetCard
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

    private var budgetCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR BUDGET")
                    .font(.timeTankLabel())
                    .tracking(1.2)
                    .foregroundStyle(Color.textMuted)

                if !model.hasEffectiveSelection {
                    Text("Pick your apps first. Finn only watches what you choose.")
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.textMuted)
                } else {
                    HStack {
                        Label("\(model.selectedItemCount) app\(model.selectedItemCount == 1 ? "" : "s")", systemImage: "square.grid.2x2")
                        Spacer()
                        Text(TimeTankModel.durationLabel(for: model.dailyBudgetMinutes))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                    .font(.timeTankBody(14))
                    .foregroundStyle(Color.textDark)

                    Text(model.isMonitoringEnabled ? "Finn is watching the tank." : "Start TimeTank to protect your time.")
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
