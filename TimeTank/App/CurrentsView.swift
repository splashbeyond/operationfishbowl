import SwiftUI

struct CurrentsView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Image("FinnMascot")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 170)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityLabel("Finn the TimeTank mascot")

                            Text("CURRENTS")
                                .font(.timeTankLabel())
                                .tracking(1.2)
                                .foregroundStyle(Color.textMuted)

                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(model.currentsBalance)")
                                    .font(.timeTankMetric(64))
                                    .foregroundStyle(Color.tideOrange)
                                Text("earned")
                                    .font(.timeTankHeading(18))
                                    .foregroundStyle(Color.textMuted)
                            }

                            Text("Every clean day earns a Current at midnight. Keep the water clean, keep earning.")
                                .font(.timeTankBody())
                                .foregroundStyle(Color.textDark)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Rewards are coming.", systemImage: "lock.fill")
                                .font(.timeTankHeading(17))
                                .foregroundStyle(Color.textDark)
                            Text("Currents will unlock tank decorations and real perks. Keep the water clean to earn more.")
                                .font(.timeTankBody(15))
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Currents")
        }
    }
}
