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
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(model.currentsBalance)")
                                    .font(.timeTankMetric(64))
                                    .foregroundStyle(Color.tideOrange)
                                Text("earned")
                                    .font(.timeTankHeading(18))
                                    .foregroundStyle(Color.textMuted)
                            }

                            Text("Clean days earn Currents at midnight. Finn earned these.")
                                .font(.timeTankBody())
                                .foregroundStyle(Color.textDark)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Marketplace comes after the shield loop is solid.", systemImage: "lock.fill")
                                .font(.timeTankHeading(17))
                                .foregroundStyle(Color.textDark)
                            Text("The MVP tracks the balance now so tank rewards can plug in cleanly later.")
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
