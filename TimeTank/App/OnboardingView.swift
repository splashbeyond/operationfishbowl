import SwiftUI

struct OnboardingView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        ZStack {
            Color.warmWhite.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image("FinnBowl")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 246)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityLabel("Finn swimming in his bowl")
                        .padding(.top, 38)

                    VStack(spacing: 10) {
                        Text("This is Finn.")
                            .font(.timeTankTitle(32))
                            .foregroundStyle(Color.textDark)

                        Text("He lives in your tank. Pick the apps that eat your time, set a fair budget, and keep his water clean.")
                            .font(.timeTankBody(17))
                            .foregroundStyle(Color.textMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 26)

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            onboardingRow(icon: "square.grid.2x2", title: "Pick your apps", copy: "Only track apps that eat your time.")
                            onboardingRow(icon: "clock", title: "Set a daily budget", copy: "Use your time when it makes sense.")
                            onboardingRow(icon: "water.waves", title: "Keep the water clean", copy: "The more you go over, the murkier it gets.")
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        PrimaryButton(
                            title: model.isAuthorized ? "Set Up Finn" : "Allow Screen Time",
                            systemImage: "person.badge.shield.checkmark"
                        ) {
                            if model.isAuthorized {
                                model.completeOnboarding()
                            } else {
                                Task {
                                    await model.requestAuthorization()
                                    if model.isAuthorized {
                                        model.completeOnboarding()
                                    }
                                }
                            }
                        }

                        Button {
                            model.completeOnboarding()
                        } label: {
                            Text("Set up later")
                                .font(.timeTankButton())
                                .foregroundStyle(Color.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    if let error = model.authorizationError {
                        Text(error)
                            .font(.timeTankBody(13))
                            .foregroundStyle(Color.muddyBrown)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }

                    Color.clear.frame(height: 20)
                }
            }
        }
    }

    private func onboardingRow(icon: String, title: String, copy: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.tideOrange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.timeTankHeading(16))
                    .foregroundStyle(Color.textDark)
                Text(copy)
                    .font(.timeTankBody(14))
                    .foregroundStyle(Color.textMuted)
            }
        }
    }
}
