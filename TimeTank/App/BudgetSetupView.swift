import FamilyControls
import SwiftUI

struct BudgetSetupView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var budgetMinutes = TimeTankConstants.defaultBudgetMinutes
    @State private var saveState: SaveState = .idle

    private enum SaveState: Equatable {
        case idle
        case saved
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
                if model.isBudgetLockedForToday {
                    saveState = .locked
                }
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

                // Big time display
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(TimeTankModel.durationLabel(for: budgetMinutes))
                        .font(.timeTankMetric(52))
                        .foregroundStyle(saveState == .locked ? Color.textMuted : Color.textDark)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: budgetMinutes)

                    if saveState == .locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.textMuted.opacity(0.6))
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // Slider — disabled when locked
                Slider(
                    value: Binding(
                        get: { Double(budgetMinutes) },
                        set: { budgetMinutes = Int(($0 / 5).rounded()) * 5 }
                    ),
                    in: 5...Double(TimeTankConstants.maximumBudgetMinutes),
                    step: 5
                )
                .tint(saveState == .locked ? Color.textMuted.opacity(0.4) : Color.tideOrange)
                .disabled(saveState == .locked)

                // Tick labels
                HStack {
                    Text("5m")
                    Spacer()
                    Text("2h")
                    Spacer()
                    Text("4h")
                    Spacer()
                    Text("12h")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textMuted.opacity(0.6))

                // Save button or locked indicator
                ZStack {
                    if saveState == .locked {
                        lockedIndicator
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    } else {
                        saveButton
                            .transition(.opacity)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: saveState)

                if saveState == .idle {
                    Text("Once saved, your budget is locked in for the day.")
                        .font(.timeTankBody(12))
                        .foregroundStyle(Color.textMuted.opacity(0.75))
                        .transition(.opacity)
                }
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

    // MARK: - Save Button States

    private var saveButton: some View {
        Button {
            handleSave()
        } label: {
            HStack(spacing: 8) {
                if saveState == .saved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
                Text(saveState == .saved ? "Budget Saved" : "Save Budget")
                    .font(.timeTankButton())
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(saveState == .saved ? Color.tankTeal : Color.tideOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(
                color: (saveState == .saved ? Color.tankTeal : Color.tideOrange).opacity(0.3),
                radius: 12, y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(saveState == .saved)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: saveState)
    }

    private var lockedIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text("Locked until tomorrow.")
                    .font(.timeTankBody(15))
                    .foregroundStyle(Color.textDark)
                Text("Come back tomorrow to update your budget.")
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

    private func handleSave() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            saveState = .saved
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
