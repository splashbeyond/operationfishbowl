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
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MVP NOTE")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)
                            Text("Detailed history starts after the core Screen Time loop is verified on device.")
                                .font(.timeTankBody())
                                .foregroundStyle(Color.textDark)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Stats")
        }
    }
}
