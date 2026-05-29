import FamilyControls
import SwiftUI

struct BudgetSetupView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var budgetMinutes = TimeTankConstants.defaultBudgetMinutes

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PICK APPS")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            Text("Choose the apps that eat your time.")
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

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("TODAY'S BUDGET")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            Text("\(budgetMinutes) min")
                                .font(.timeTankMetric(52))
                                .foregroundStyle(Color.textDark)
                                .contentTransition(.numericText())

                            Stepper(value: $budgetMinutes, in: 5...240, step: 5) {
                                Text("How long is fair?")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            }

                            Slider(value: Binding(
                                get: { Double(budgetMinutes) },
                                set: { budgetMinutes = Int(($0 / 5).rounded()) * 5 }
                            ), in: 5...240, step: 5)
                            .tint(.tideOrange)

                            PrimaryButton(title: "Save Budget", systemImage: "checkmark") {
                                model.saveBudget(minutes: budgetMinutes)
                            }
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(model.isMonitoringEnabled ? "Monitoring is on" : "Monitoring is off", systemImage: model.isMonitoringEnabled ? "checkmark.shield.fill" : "shield")
                                .font(.timeTankHeading(18))
                                .foregroundStyle(model.isMonitoringEnabled ? Color.tankTeal : Color.textDark)

                            if let error = model.scheduleError {
                                Text(error)
                                    .font(.timeTankBody(14))
                                    .foregroundStyle(Color.muddyBrown)
                            }

                            PrimaryButton(title: model.isMonitoringEnabled ? "Restart Monitoring" : "Start Monitoring", systemImage: "water.waves") {
                                model.startMonitoring()
                            }
                        }
                    }
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
                if !presented {
                    model.saveSelection(pickerSelection)
                }
            }
            .onAppear {
                pickerSelection = model.selection
                budgetMinutes = model.dailyBudgetMinutes
            }
        }
    }

    private var selectionSummary: String {
        let count = model.selectedItemCount
        if count == 0 {
            return "No distractions selected yet."
        }
        return "\(count) selection\(count == 1 ? "" : "s") saved for Finn's tank."
    }
}
