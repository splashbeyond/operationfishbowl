import ManagedSettings
import SwiftUI

struct SettingsView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("APPEARANCE")
                                .font(.timeTankLabel())
                                .tracking(1.2)
                                .foregroundStyle(Color.textMuted)

                            Picker("Appearance", selection: Binding(
                                get: { model.appearanceMode },
                                set: { model.saveAppearanceMode($0) }
                            )) {
                                ForEach(TimeTankAppearanceMode.allCases) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("MONITORING")
                                .font(.timeTankLabel())
                                .tracking(1.2)
                                .foregroundStyle(Color.textMuted)

                            HStack(spacing: 10) {
                                Image(systemName: model.isMonitoringEnabled ? "checkmark.shield.fill" : "shield")
                                    .foregroundStyle(model.isMonitoringEnabled ? Color.tankTeal : Color.textMuted)
                                Text(model.isMonitoringEnabled ? "Finn is watching the tank." : "Monitoring is paused.")
                                    .font(.timeTankBody(16))
                                    .foregroundStyle(Color.textDark)
                            }

                            if model.isMonitoringEnabled {
                                Button {
                                    model.stopMonitoring()
                                } label: {
                                    Label("Pause Monitoring", systemImage: "pause.fill")
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
                            } else {
                                PrimaryButton(title: "Start Monitoring", systemImage: "water.waves") {
                                    model.startMonitoring()
                                }
                            }
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.timeTankLabel())
                                .tracking(1.2)
                                .foregroundStyle(Color.textMuted)

                            HStack {
                                Text("TimeTank")
                                    .font(.timeTankBody(15))
                                    .foregroundStyle(Color.textDark)
                                Spacer()
                                Text(appVersion)
                                    .font(.timeTankBody(15))
                                    .foregroundStyle(Color.textMuted)
                            }

                            Text("Keep the water clean.")
                                .font(.timeTankBody(14))
                                .foregroundStyle(Color.textMuted)
                        }
                    }

                    #if DEBUG
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DEBUG")
                                .font(.timeTankLabel())
                                .tracking(1.2)
                                .foregroundStyle(Color.textMuted)

                            // Monitoring state
                            statusRow(title: "Monitoring flag", value: model.isMonitoringEnabled ? "ON" : "OFF")
                            statusRow(title: "Active schedules", value: model.activeActivitySummary)
                            statusRow(title: "Budget", value: TimeTankModel.durationLabel(for: model.dailyBudgetMinutes))
                            statusRow(title: "Selected items", value: "\(model.selectedItemCount)")
                            statusRow(title: "Authorized", value: model.isAuthorized ? "Yes" : "No")
                            statusRow(title: "Budget exceeded", value: model.isBudgetExceededToday ? "Yes" : "No")
                            statusRow(title: "Pollution", value: "\(Int(model.pollutionLevel * 100))%")

                            Divider()

                            Button("Force Apply Shield") {
                                if model.hasSelection {
                                    ScreenTimeShielding.applyShield(for: model.selection)
                                    model.refresh()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.tideOrange)

                            Button("Clear Shield") {
                                ScreenTimeShielding.clearShield()
                                model.refresh()
                            }
                            .buttonStyle(.bordered)

                            Button("Add pollution") { model.debugAddPollution() }
                                .buttonStyle(.bordered)

                            Button("Award Current") { model.debugAwardCurrent() }
                                .buttonStyle(.bordered)
                        }
                    }

                    // Diagnostics
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("DIAGNOSTICS")
                                    .font(.timeTankLabel())
                                    .tracking(1.2)
                                    .foregroundStyle(Color.textMuted)
                                Spacer()
                                Button {
                                    model.clearDiagnostics()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.textMuted)
                                }
                                .buttonStyle(.plain)
                            }

                            if model.diagnostics.isEmpty {
                                Text("No events yet.")
                                    .font(.timeTankBody(13))
                                    .foregroundStyle(Color.textMuted)
                            } else {
                                ForEach(model.diagnostics) { event in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(event.source) · \(event.timestamp.formatted(date: .omitted, time: .shortened))")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.textMuted)
                                        Text(event.message)
                                            .font(.timeTankBody(13))
                                            .foregroundStyle(Color.textDark)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    TankPreviewCard()
                    #endif
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Settings")
        }
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.timeTankBody(13))
                .foregroundStyle(Color.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.trailing)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(v)"
    }
}

#if DEBUG
struct TankPreviewCard: View {
    @State private var previewPollution: Double = 0

    private var faceName: String {
        switch previewPollution {
        case 0..<0.2:  return "Blissful"
        case 0.2..<0.4: return "Alert"
        case 0.4..<0.6: return "Worried"
        case 0.6..<1.0: return "Distressed"
        default:        return "Suffering"
        }
    }

    private var faceColor: Color {
        switch previewPollution {
        case 0..<0.4:  return .tankTeal
        case 0.4..<0.6: return .amber
        default:        return .muddyBrown
        }
    }

    var body: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("TANK PREVIEW")
                        .font(.timeTankLabel())
                        .tracking(1.2)
                        .foregroundStyle(Color.textMuted)
                    Spacer()
                    Text(faceName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(faceColor)
                    Text("·")
                        .foregroundStyle(Color.textMuted)
                    Text("\(Int(previewPollution * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.textMuted)
                }

                FocusTankView(pollutionLevel: previewPollution)
                    .frame(height: 220)

                VStack(spacing: 6) {
                    Slider(value: $previewPollution, in: 0...1, step: 0.01)
                        .tint(.tideOrange)

                    HStack(spacing: 0) {
                        ForEach(["0", "20", "40", "60", "80", "100"], id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.textMuted)
                            if label != "100" { Spacer() }
                        }
                    }
                }

                HStack(spacing: 6) {
                    ForEach([0.0, 0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                previewPollution = level
                            }
                        } label: {
                            Text("\(Int(level * 100))%")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(previewPollution == level ? Color.white : Color.tideOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(previewPollution == level ? Color.tideOrange : Color.tideOrange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: previewPollution)
                    }
                }
            }
        }
    }
}
#endif
