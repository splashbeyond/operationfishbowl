import FamilyControls
import SwiftUI

struct BudgetSetupView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var budgetMinutes = TimeTankConstants.defaultBudgetMinutes
    @State private var saveState: SaveState = .unset

    // .unset    — first time, no budget ever saved
    // .active   — budget is set and carrying over, new day, can update
    // .saving   — brief checkmark confirmation after tapping save
    // .locked   — saved today, slider locked until tomorrow
    private enum SaveState: Equatable {
        case unset
        case active
        case saving
        case locked
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    appPickerCard
                    budgetCard
                    monitoringCard
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Budget")
            .familyActivityPicker(
                headerText: "Pick the apps that eat your time.",
                footerText: "Utilities can stay untracked. TimeTank only watches what you choose.",
                isPresented: $isPickerPresented,
                selection: $pickerSelection
            )
            .onChange(of: isPickerPresented) { _, presented in
                if !presented { model.saveSelection(pickerSelection) }
            }
            .onAppear {
                pickerSelection = model.selection
                budgetMinutes = model.dailyBudgetMinutes
                saveState = model.isBudgetLockedForToday ? .locked
                           : model.hasBudgetBeenSet      ? .active
                           : .unset
            }
        }
    }

    // MARK: - Cards

    private var appPickerCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR APPS")
                    .font(.timeTankLabel())
                    .tracking(1.2)
                    .foregroundStyle(Color.textMuted)

                Text("Pick the apps that eat your time.")
                    .font(.timeTankHeading())
                    .foregroundStyle(Color.textDark)

                Text(selectionSummary)
                    .font(.timeTankBody(15))
                    .foregroundStyle(Color.textMuted)

                PrimaryButton(title: "Choose Apps", systemImage: "square.grid.2x2") {
                    pickerSelection = model.selection
                    isPickerPresented = true
                }
            }
        }
    }

    private var budgetCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("DAILY BUDGET")
                    .font(.timeTankLabel())
                    .tracking(1.2)
                    .foregroundStyle(Color.textMuted)

                // Budget amount
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(TimeTankModel.durationLabel(for: budgetMinutes))
                        .font(.timeTankMetric(52))
                        .foregroundStyle(isSliderLocked ? Color.textMuted : Color.textDark)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: budgetMinutes)

                    if isSliderLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.textMuted.opacity(0.5))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSliderLocked)

                // Context line
                Text(budgetContextLine)
                    .font(.timeTankBody(14))
                    .foregroundStyle(Color.textMuted)
                    .animation(.easeInOut(duration: 0.25), value: saveState)

                // Slider
                Slider(
                    value: Binding(
                        get: { Double(budgetMinutes) },
                        set: { budgetMinutes = Int(($0 / 5).rounded()) * 5 }
                    ),
                    in: 5...Double(TimeTankConstants.maximumBudgetMinutes),
                    step: 5
                )
                .tint(isSliderLocked ? Color.textMuted.opacity(0.35) : Color.tideOrange)
                .disabled(isSliderLocked)

                // Tick labels
                HStack {
                    Text("5m"); Spacer()
                    Text("2h"); Spacer()
                    Text("4h"); Spacer()
                    Text("12h")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textMuted.opacity(0.55))

                // Action area
                ZStack {
                    switch saveState {
                    case .unset:
                        primarySaveButton(label: "Save Budget")
                            .transition(.opacity)

                    case .active:
                        updateButton
                            .transition(.opacity)

                    case .saving:
                        primarySaveButton(label: "Budget Saved", confirmed: true)
                            .transition(.opacity)

                    case .locked:
                        lockedBadge
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: saveState)
            }
        }
    }

    private var monitoringCard: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("STATUS")
                    .font(.timeTankLabel())
                    .tracking(1.2)
                    .foregroundStyle(Color.textMuted)

                HStack(spacing: 10) {
                    Image(systemName: model.isMonitoringEnabled ? "checkmark.shield.fill" : "shield")
                        .foregroundStyle(model.isMonitoringEnabled ? Color.tankTeal : Color.textMuted)
                    Text(model.isMonitoringEnabled ? "Finn is watching the tank." : "Finn isn't watching yet.")
                        .font(.timeTankBody(16))
                        .foregroundStyle(Color.textDark)
                }

                if let error = model.scheduleError {
                    Text(error)
                        .font(.timeTankBody(14))
                        .foregroundStyle(Color.muddyBrown)
                }

                if !model.isAuthorized {
                    PrimaryButton(title: "Allow Screen Time", systemImage: "person.badge.shield.checkmark") {
                        Task { await model.requestAuthorization() }
                    }
                }

                PrimaryButton(
                    title: model.isMonitoringEnabled ? "Restart Monitoring" : "Start Monitoring",
                    systemImage: "water.waves"
                ) {
                    model.startMonitoring()
                }
            }
        }
    }

    // MARK: - Action Views

    private func primarySaveButton(label: String, confirmed: Bool = false) -> some View {
        Button {
            guard !confirmed else { return }
            handleSave()
        } label: {
            HStack(spacing: 8) {
                if confirmed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
                Text(label)
                    .font(.timeTankButton())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(confirmed ? Color.tankTeal : Color.tideOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(
                color: (confirmed ? Color.tankTeal : Color.tideOrange).opacity(0.3),
                radius: 12, y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(confirmed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: confirmed)
    }

    // Subtle secondary-style button for returning users — no action required
    private var updateButton: some View {
        Button {
            handleSave()
        } label: {
            Label("Update Budget", systemImage: "pencil")
                .font(.timeTankButton())
                .foregroundStyle(Color.tideOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.tideOrange, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }

    private var lockedBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text("Budget is set for today.")
                    .font(.timeTankBody(15))
                    .foregroundStyle(Color.textDark)
                Text("Finn carries this forward every day. Update tomorrow if you'd like to adjust.")
                    .font(.timeTankBody(13))
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.peachFoam)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Helpers

    private var isSliderLocked: Bool {
        saveState == .locked || saveState == .saving
    }

    private var budgetContextLine: String {
        switch saveState {
        case .unset:   return "How long is fair for these apps each day?"
        case .active:  return "Finn uses this budget every day. Change it anytime."
        case .saving:  return "Finn uses this budget every day."
        case .locked:  return "This budget runs automatically. No action needed."
        }
    }

    private func handleSave() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            saveState = .saving
        }
        model.saveBudget(minutes: budgetMinutes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                saveState = .locked
            }
        }
    }

    private var selectionSummary: String {
        let count = model.selectedItemCount
        if count == 0 { return "No apps picked yet." }
        return "\(count) app\(count == 1 ? "" : "s") saved. Finn is watching."
    }
}
