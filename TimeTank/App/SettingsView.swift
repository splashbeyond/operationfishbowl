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

                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(v)"
    }
}

