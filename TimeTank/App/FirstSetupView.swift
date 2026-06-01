import FamilyControls
import SwiftUI

struct FirstSetupView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var step = 0
    @State private var budgetMinutes = TimeTankConstants.defaultBudgetMinutes
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var pickerOpened = false
    @State private var isGoingForward = true

    var body: some View {
        ZStack {
            Color.warmWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar

                ZStack {
                    if step == 0 { budgetScreen.transition(slide) }
                    if step == 1 { appsScreen.transition(slide) }
                    if step == 2 { featuresScreen.transition(slide) }
                    if step == 3 { launchScreen.transition(slide) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.42, dampingFraction: 0.86), value: step)
            }
        }
        .familyActivityPicker(
            headerText: "Pick the apps that eat your time.",
            footerText: "Utilities like Maps stay free. TimeTank only watches what you choose.",
            isPresented: $isPickerPresented,
            selection: $pickerSelection
        )
        .onChange(of: isPickerPresented) { _, presented in
            if !presented {
                model.saveSelection(pickerSelection)
                pickerOpened = true
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.peachFoam).frame(height: 4)
                Capsule()
                    .fill(Color.tideOrange)
                    .frame(width: geo.size.width * (Double(step) / 3.0), height: 4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.88), value: step)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    private var slide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isGoingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isGoingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func next() {
        isGoingForward = true
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            step = min(step + 1, 3)
        }
    }

    // MARK: - Screen 1: Budget

    private var budgetScreen: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 12)

                Text("SET YOUR BUDGET")
                    .font(.timeTankLabel()).tracking(1.2)
                    .foregroundStyle(Color.tideOrange)

                Spacer().frame(height: 10)

                Text("How long is fair each day?")
                    .font(.timeTankTitle(28))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 18)

                infoCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image("FinnMascotWorried")
                            .resizable().scaledToFit()
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your daily budget is how long you can spend on distraction apps before Finn starts getting sick and the block screen shows up.")
                                .font(.timeTankBody(14))
                                .foregroundStyle(Color.textDark)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("The shorter the budget, the cleaner his water.")
                                .font(.timeTankBody(13))
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                }

                Spacer().frame(height: 24)

                Text(TimeTankModel.durationLabel(for: budgetMinutes))
                    .font(.timeTankMetric(64))
                    .foregroundStyle(Color.tideOrange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: budgetMinutes)
                    .monospacedDigit()

                Text("per day")
                    .font(.timeTankBody(15))
                    .foregroundStyle(Color.textMuted)
                    .padding(.top, 2)

                Spacer().frame(height: 20)

                Slider(
                    value: Binding(
                        get: { Double(budgetMinutes) },
                        set: { budgetMinutes = Int(($0 / 5).rounded()) * 5 }
                    ),
                    in: 5...Double(TimeTankConstants.maximumBudgetMinutes),
                    step: 5
                )
                .tint(Color.tideOrange)

                HStack {
                    Text("5m"); Spacer(); Text("2h"); Spacer(); Text("4h"); Spacer(); Text("12h")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textMuted.opacity(0.55))
                .padding(.top, 2)

                Spacer().frame(height: 32)

                continueButton("Save & Continue") {
                    model.saveBudget(minutes: budgetMinutes)
                    next()
                }

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Screen 2: Apps

    private var appsScreen: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 12)

                Text("CHOOSE YOUR APPS")
                    .font(.timeTankLabel()).tracking(1.2)
                    .foregroundStyle(Color.tideOrange)

                Spacer().frame(height: 10)

                Text("What does Finn watch?")
                    .font(.timeTankTitle(28))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 18)

                infoCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image("FinnMascot")
                            .resizable().scaledToFit()
                            .frame(width: 44, height: 44)
                        Text("Pick the apps that eat your time. Finn only tracks what you choose — Maps, Messages, and utilities stay completely free.")
                            .font(.timeTankBody(14))
                            .foregroundStyle(Color.textDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer().frame(height: 24)

                Button {
                    pickerSelection = model.selection
                    isPickerPresented = true
                } label: {
                    Label("Choose Apps", systemImage: "square.grid.2x2")
                        .font(.timeTankButton())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.tideOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.tideOrange.opacity(0.3), radius: 12, y: 4)
                }
                .buttonStyle(.plain)

                if pickerOpened {
                    HStack(spacing: 8) {
                        Image(systemName: model.selectedItemCount > 0 ? "checkmark.circle.fill" : "info.circle")
                            .foregroundStyle(model.selectedItemCount > 0 ? Color.tankTeal : Color.textMuted)
                        Text(model.selectedItemCount > 0
                            ? "Finn is watching \(model.selectedItemCount) app\(model.selectedItemCount == 1 ? "" : "s")."
                            : "No apps yet. You can pick them later in the Budget tab.")
                            .font(.timeTankBody(14))
                            .foregroundStyle(model.selectedItemCount > 0 ? Color.tankTeal : Color.textMuted)
                    }
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: 32)

                VStack(spacing: 10) {
                    continueButton("Continue", action: next)
                    if !pickerOpened {
                        Button("Skip for now") { next() }
                            .font(.timeTankBody(15))
                            .foregroundStyle(Color.textMuted)
                    }
                }

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Screen 3: Features

    private var featuresScreen: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 12)

                Text("HOW IT WORKS")
                    .font(.timeTankLabel()).tracking(1.2)
                    .foregroundStyle(Color.tankTeal)

                Spacer().frame(height: 10)

                Text("Here's what Finn does.")
                    .font(.timeTankTitle(28))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 20)

                VStack(spacing: 12) {
                    featureRow(
                        icon: "drop.fill", color: .tankTeal,
                        title: "The Tank",
                        body: "Every minute on your picked apps adds murk. The pollution meter shows how much of your budget you've burned. Resets clean at midnight."
                    )
                    featureRow(
                        icon: "shield.fill", color: .tideOrange,
                        title: "The Shield",
                        body: "When your budget runs out, a block screen covers every app you picked. Finn puts it up automatically — no action needed from you."
                    )
                    featureRow(
                        icon: "arrow.trianglehead.clockwise", color: .amber,
                        title: "Bypasses",
                        body: "Tap \"Ask For More Time\" on the shield for a short window to keep going. Each bypass adds more murk. Windows escalate: 5 → 10 → 15 → 30 → 60 min."
                    )
                    featureRow(
                        icon: "square.grid.2x2.fill", color: Color(red: 0.45, green: 0.45, blue: 0.9),
                        title: "Widgets",
                        body: "Add the TimeTank widget to your home screen to see Finn's mood at a glance. If he looks worried, put the device down."
                    )
                    featureRow(
                        icon: "centsign.circle.fill", color: .tideOrange,
                        title: "Currents",
                        body: "Stay under budget with no bypasses and earn 1 Current at midnight. Build streaks for bonus earnings. Spend Currents on perks."
                    )
                    featureRow(
                        icon: "chart.bar.fill", color: .textMuted,
                        title: "Stats",
                        body: "Track your daily history in the Stats tab. See how your usage and tank pollution trends over time."
                    )
                }

                Spacer().frame(height: 32)

                continueButton("Got It", action: next)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func featureRow(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.timeTankBody(15))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textDark)
                Text(body)
                    .font(.timeTankBody(14))
                    .foregroundStyle(Color.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.peachFoam, lineWidth: 1)
        }
    }

    // MARK: - Screen 4: Launch

    private var launchScreen: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Image("FinnMascot")
                    .resizable().scaledToFit()
                    .frame(maxWidth: 190)
                    .shadow(color: Color.tideOrange.opacity(0.2), radius: 24, y: 8)

                Spacer().frame(height: 28)

                Text("Finn is ready.")
                    .font(.timeTankTitle(34))
                    .foregroundStyle(Color.textDark)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 12)

                Text("Start protection and Finn begins watching your tank right now. You can always adjust your apps and budget in the Budget tab.")
                    .font(.timeTankBody(16))
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 40)

                Button {
                    handleLaunch()
                } label: {
                    Label("Start Finn's Protection", systemImage: "water.waves")
                        .font(.timeTankButton())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.tideOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.tideOrange.opacity(0.35), radius: 16, y: 6)
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 12)

                Button("Set up later") {
                    model.completeFirstSetup()
                }
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textMuted)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func handleLaunch() {
        if !model.isAuthorized {
            Task {
                await model.requestAuthorization()
                if model.isAuthorized { model.startMonitoring() }
                model.completeFirstSetup()
            }
        } else {
            model.startMonitoring()
            model.completeFirstSetup()
        }
    }

    // MARK: - Shared Helpers

    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.peachFoam, lineWidth: 1)
            }
    }

    private func continueButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.timeTankButton())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.tideOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.tideOrange.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
