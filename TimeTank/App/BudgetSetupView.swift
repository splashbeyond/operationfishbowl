import FamilyControls
import SwiftUI

struct BudgetSetupView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var budgetMinutes = TimeTankConstants.defaultBudgetMinutes

    private let budgetPresets = [15, 30, 60, 120, 240, 480, 720]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

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

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DAILY BUDGET")
                                .font(.timeTankLabel())
                                .tracking(1.2)
                                .foregroundStyle(Color.textMuted)

                            Text(TimeTankModel.durationLabel(for: budgetMinutes))
                                .font(.timeTankMetric(52))
                                .foregroundStyle(Color.textDark)
                                .contentTransition(.numericText())

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(budgetPresets, id: \.self) { preset in
                                    Button {
                                        budgetMinutes = preset
                                    } label: {
                                        Text(presetLabel(for: preset))
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(budgetMinutes == preset ? Color.white : Color.tideOrange)
                                    .background(budgetMinutes == preset ? Color.tideOrange : Color.tideOrange.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }

                            Stepper(value: $budgetMinutes, in: 5...TimeTankConstants.maximumBudgetMinutes, step: 5) {
                                Text("How long is fair?")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            }

                            Slider(value: Binding(
                                get: { Double(budgetMinutes) },
                                set: { budgetMinutes = Int(($0 / 5).rounded()) * 5 }
                            ), in: 5...Double(TimeTankConstants.maximumBudgetMinutes), step: 5)
                            .tint(.tideOrange)

                            PrimaryButton(title: "Save Budget", systemImage: "checkmark") {
                                model.saveBudget(minutes: budgetMinutes)
                            }
                        }
                    }

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
        if count == 0 { return "No apps picked yet." }
        return "\(count) app\(count == 1 ? "" : "s") saved. Finn is watching."
    }

    private func presetLabel(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}
