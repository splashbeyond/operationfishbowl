import SwiftUI

struct SettingsView: View {
    @Environment(TimeTankModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SCREEN TIME")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            statusRow(title: "Authorization", value: model.isRunningInSimulator ? "Simulator demo" : model.isAuthorized ? "Ready" : "Needs access")
                            statusRow(title: "Selected items", value: "\(model.selectedItemCount)")
                            statusRow(title: "Budget", value: "\(model.dailyBudgetMinutes) min")
                            statusRow(title: "Budget state", value: model.isBudgetExceededToday ? "Spent today" : "Available")
                            statusRow(title: "Murkiness", value: model.murkinessState.rawValue.capitalized)
                            statusRow(title: "Bypass", value: bypassStatus)
                            statusRow(title: "Active schedules", value: model.activeActivitySummary)
                            statusRow(title: "Monitoring started", value: formatted(model.lastMonitoringStartDate))
                            statusRow(title: "Threshold reached", value: formatted(model.lastThresholdDate))
                            statusRow(title: "Last shield apply", value: formatted(model.lastShieldApplyDate))
                            statusRow(title: "Last shield clear", value: formatted(model.lastShieldClearDate))
                            statusRow(title: "Last shield action", value: formatted(model.lastShieldActionDate))
                            statusRow(title: "App Group", value: TimeTankConstants.appGroupIdentifier)
                        }
                    }

                    if let authorizationError = model.authorizationError {
                        TimeTankCard {
                            Text(authorizationError)
                                .font(.timeTankBody(14))
                                .foregroundStyle(Color.muddyBrown)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("DIAGNOSTICS")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.textMuted)

                                Spacer()

                                Button {
                                    model.clearDiagnostics()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.textMuted)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Clear diagnostics")
                            }

                            if model.diagnostics.isEmpty {
                                Text("No Screen Time events recorded yet.")
                                    .font(.timeTankBody(14))
                                    .foregroundStyle(Color.textMuted)
                            } else {
                                ForEach(model.diagnostics) { event in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(event.source) · \(event.timestamp.formatted(date: .omitted, time: .shortened))")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.textMuted)
                                        Text(event.message)
                                            .font(.timeTankBody(14))
                                            .foregroundStyle(Color.textDark)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    PrimaryButton(title: "Request Authorization", systemImage: "person.badge.shield.checkmark") {
                        Task { await model.requestAuthorization() }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DEVICE VERIFICATION")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            Text("For real-device testing: pick one obvious app, start the one-minute test, use that app for over a minute, then check diagnostics for a threshold callback and shield apply event.")
                                .font(.timeTankBody(14))
                                .foregroundStyle(Color.textDark)

                            Button {
                                model.startOneMinuteDeviceTest()
                            } label: {
                                Label("Start 1-Minute Test", systemImage: "timer")
                                    .font(.timeTankButton())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.tideOrange)

                            Button {
                                model.applyShieldNowForDeviceTest()
                            } label: {
                                Label("Apply Shield Now", systemImage: "shield.lefthalf.filled")
                                    .font(.timeTankButton())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.tideOrange)

                            Button {
                                model.clearShieldForDeviceTest()
                            } label: {
                                Label("Clear Shield", systemImage: "shield.slash")
                                    .font(.timeTankButton())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.coral)
                        }
                    }

                    Button {
                        model.stopMonitoring()
                    } label: {
                        Label("Pause Monitoring", systemImage: "pause.fill")
                            .font(.timeTankButton())
                            .foregroundStyle(Color.tideOrange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.tideOrange, lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        model.resetProgress()
                    } label: {
                        Label("Reset Tank Progress", systemImage: "arrow.counterclockwise")
                            .font(.timeTankButton())
                            .foregroundStyle(Color.coral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }

                    #if DEBUG
                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DEBUG")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            Button("Add pollution") {
                                model.debugAddPollution()
                            }
                            .buttonStyle(.bordered)

                            Button("Award Current") {
                                model.debugAwardCurrent()
                            }
                            .buttonStyle(.bordered)
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
                .font(.timeTankBody(15))
                .foregroundStyle(Color.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textDark)
                .multilineTextAlignment(.trailing)
        }
    }

    private var bypassStatus: String {
        guard let bypassExpiresAt = model.bypassExpiresAt else { return "Inactive" }

        let seconds = max(0, Int(bypassExpiresAt.timeIntervalSinceNow))
        if seconds == 0 { return "Expired" }

        let minutes = max(1, Int(ceil(Double(seconds) / 60)))
        return "\(minutes) min left"
    }

    private func formatted(_ date: Date?) -> String {
        guard let date else { return "Never" }
        return date.formatted(date: .omitted, time: .shortened)
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
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
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
