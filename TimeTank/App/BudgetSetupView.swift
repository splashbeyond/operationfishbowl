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
                    if model.isRunningInSimulator {
                        TimeTankCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Simulator Demo Mode", systemImage: "iphone.gen3")
                                    .font(.timeTankHeading(18))
                                    .foregroundStyle(Color.textDark)

                                Text("Apple's real Screen Time permissions, picker tokens, and shields require a signed physical iPhone. Use a demo selection here to exercise the MVP flow in Simulator.")
                                    .font(.timeTankBody(14))
                                    .foregroundStyle(Color.textMuted)

                                PrimaryButton(title: "Use Demo Selection", systemImage: "sparkles") {
                                    model.enableSimulatorDemoSelection()
                                }
                            }
                        }
                    }

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
                            .opacity(model.isRunningInSimulator ? 0.55 : 1)
                            .disabled(model.isRunningInSimulator)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("TODAY'S BUDGET")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
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
                                Text("How long is fair for these apps?")
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
                        VStack(alignment: .leading, spacing: 12) {
                            Label(model.isMonitoringEnabled ? "Monitoring is on" : "Monitoring is off", systemImage: model.isMonitoringEnabled ? "checkmark.shield.fill" : "shield")
                                .font(.timeTankHeading(18))
                                .foregroundStyle(model.isMonitoringEnabled ? Color.tankTeal : Color.textDark)

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
        if model.isSimulatorDemoSelectionEnabled && !model.hasSelection {
            return "Demo distraction saved for Simulator."
        }
        return "\(count) selection\(count == 1 ? "" : "s") saved for Finn's tank."
    }

    private func presetLabel(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}
