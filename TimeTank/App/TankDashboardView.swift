import SwiftUI

struct TankDashboardView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    FocusTankView(pollutionLevel: model.pollutionLevel)
                        .frame(height: 330)
                        .padding(.vertical, 8)

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(model.statusMessage, systemImage: "drop.fill")
                                .font(.timeTankHeading(17))
                                .foregroundStyle(Color.textDark)

                            BudgetProgressBar(progress: min(1, model.pollutionLevel))

                            HStack {
                                Text("\(model.remainingMinutesEstimate) min remaining")
                                    .font(.timeTankBody(14))
                                    .foregroundStyle(Color.textMuted)

                                Spacer()

                                Text("\(Int(model.pollutionLevel * 100))% murky")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(pollutionColor)
                            }
                        }
                    }

                    if !model.isMonitoringEnabled {
                        PrimaryButton(title: "Start TimeTank", systemImage: "play.fill") {
                            model.startMonitoring()
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("TimeTank")
            .navigationBarTitleDisplayMode(.inline)
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
