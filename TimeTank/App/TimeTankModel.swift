import DeviceActivity
import FamilyControls
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class TimeTankModel {
    var selection: FamilyActivitySelection
    var dailyBudgetMinutes: Int
    var pollutionLevel: Double
    var currentsBalance: Int
    var isAuthorized: Bool
    var hasSeenOnboarding: Bool
    var isMonitoringEnabled: Bool
    var isBudgetExceededToday: Bool
    var bypassExpiresAt: Date?
    var diagnostics: [TimeTankDiagnosticEvent]
    var isSimulatorDemoSelectionEnabled: Bool
    var activeActivitySummary: String
    var lastMonitoringStartDate: Date?
    var lastThresholdDate: Date?
    var lastShieldApplyDate: Date?
    var lastShieldClearDate: Date?
    var lastShieldActionDate: Date?
    var bypassCount: Int
    var dailySnapshots: [TimeTankDailySnapshot]
    var appearanceMode: TimeTankAppearanceMode
    var isBudgetLockedForToday: Bool
    var hasBudgetBeenSet: Bool
    var statusMessage = "Pick the apps that eat your time."
    var authorizationError: String?
    var scheduleError: String?

    private let store = TimeTankStore()

    init() {
        bypassCount = store.bypassCount
        dailySnapshots = store.dailySnapshots
        appearanceMode = TimeTankAppearanceMode(rawValue: store.appearanceModeRawValue) ?? .light
        isBudgetLockedForToday = store.isBudgetLockedForToday
        hasBudgetBeenSet = store.hasBudgetBeenSet
        selection = store.selection
        dailyBudgetMinutes = store.dailyBudgetMinutes
        pollutionLevel = store.pollutionLevel
        currentsBalance = store.currentsBalance
        isMonitoringEnabled = store.isMonitoringEnabled
        isBudgetExceededToday = store.isBudgetExceededToday
        bypassExpiresAt = store.bypassExpiresAt
        diagnostics = store.diagnostics
        isSimulatorDemoSelectionEnabled = store.simulatorDemoSelectionEnabled
        activeActivitySummary = ScreenTimeScheduler.activeActivitySummary
        lastMonitoringStartDate = store.lastMonitoringStartDate
        lastThresholdDate = store.lastThresholdDate
        lastShieldApplyDate = store.lastShieldApplyDate
        lastShieldClearDate = store.lastShieldClearDate
        lastShieldActionDate = store.lastShieldActionDate
        scheduleError = store.lastScheduleError
        #if targetEnvironment(simulator)
        isAuthorized = true
        #else
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        #endif
        hasSeenOnboarding = store.hasSeenOnboarding
        enforceExpiredBypassIfNeeded()
        autoRestartMonitoringIfNeeded()
    }

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    var hasEffectiveSelection: Bool {
        hasSelection || isSimulatorDemoSelectionEnabled
    }

    var selectedItemCount: Int {
        let selectedTokens = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
        return selectedTokens > 0 ? selectedTokens : (isSimulatorDemoSelectionEnabled ? 1 : 0)
    }

    var murkinessState: TimeTankMurkinessState {
        TimeTankRules.murkinessState(
            usageProgress: nil,
            isBudgetExceeded: isBudgetExceededToday,
            pollutionLevel: pollutionLevel
        )
    }

    var budgetBoundaryText: String {
        TimeTankRules.statusMessage(for: murkinessState, budgetMinutes: dailyBudgetMinutes)
    }

    func requestAuthorization() async {
        #if targetEnvironment(simulator)
        isAuthorized = true
        authorizationError = nil
        statusMessage = "Simulator demo mode is ready. Real Screen Time authorization needs an iPhone."
        store.recordDiagnostic("Simulator demo authorization enabled.", source: "App")
        refresh()
        #else
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            authorizationError = nil
            statusMessage = "Authorization ready. Finn can watch the tank."
            store.recordDiagnostic("Authorization request completed: \(isAuthorized ? "approved" : "not approved").", source: "App")
            autoStartIfReady()
        } catch {
            isAuthorized = false
            authorizationError = error.localizedDescription
            statusMessage = "Screen Time access is needed before Finn can help."
            store.recordDiagnostic("Authorization request failed: \(error.localizedDescription)", source: "App")
        }
        refresh()
        #endif
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        store.hasSeenOnboarding = true
    }

    func saveSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        store.selection = newSelection
        store.simulatorDemoSelectionEnabled = false
        statusMessage = hasSelection ? "Selection saved. Finn has a reason to care." : "Pick something. Finn needs a reason to care."
        store.recordDiagnostic("Selection saved with \(selectedItemCount) item(s).", source: "App")
        refresh()
        // Always restart with the new selection — autoStartIfReady guards on !isMonitoringEnabled
        // which would skip the restart if monitoring was already running with old tokens.
        #if !targetEnvironment(simulator)
        if isAuthorized && hasEffectiveSelection {
            startMonitoring()
        }
        #endif
    }

    func enableSimulatorDemoSelection() {
        store.simulatorDemoSelectionEnabled = true
        isSimulatorDemoSelectionEnabled = true
        statusMessage = "Simulator demo selection is ready."
        store.recordDiagnostic("Simulator demo selection enabled.", source: "App")
        refresh()
    }

    func saveBudget(minutes: Int) {
        dailyBudgetMinutes = min(TimeTankConstants.maximumBudgetMinutes, max(1, minutes))
        store.dailyBudgetMinutes = dailyBudgetMinutes
        store.lastBudgetSaveDate = Date()
        statusMessage = "Got it. \(Self.durationLabel(for: dailyBudgetMinutes)). Finn's counting on you."
        store.recordDiagnostic("Budget saved: \(dailyBudgetMinutes) minute(s).", source: "App")
        refresh()
        // Re-register the DeviceActivity schedule with the new threshold immediately.
        // Without this the system keeps enforcing the old budget until next app launch.
        #if !targetEnvironment(simulator)
        if isAuthorized && hasEffectiveSelection {
            startMonitoring()
        }
        #endif
    }

    func saveAppearanceMode(_ mode: TimeTankAppearanceMode) {
        appearanceMode = mode
        store.appearanceModeRawValue = mode.rawValue
        statusMessage = "Appearance set to \(mode.label)."
    }

    func startMonitoring() {
        guard isAuthorized else {
            scheduleError = "Approve Screen Time access before starting monitoring."
            statusMessage = "Screen Time access is needed before Finn can help."
            store.recordDiagnostic("Monitoring start blocked: missing authorization.", source: "App")
            refresh()
            return
        }

        guard hasEffectiveSelection else {
            scheduleError = "Select at least one app, category, or website first."
            statusMessage = "Pick something. Finn needs a reason to care."
            store.recordDiagnostic("Monitoring start blocked: no selection.", source: "App")
            refresh()
            return
        }

        #if targetEnvironment(simulator)
        store.isMonitoringEnabled = true
        store.lastScheduleError = nil
        isMonitoringEnabled = true
        scheduleError = nil
        statusMessage = "Simulator demo monitoring is on."
        store.recordDiagnostic("Simulator demo monitoring started.", source: "App")
        refresh()
        #else
        do {
            requestNotificationPermission()
            let appCount  = selection.applicationTokens.count
            let catCount  = selection.categoryTokens.count
            let webCount  = selection.webDomainTokens.count
            store.recordDiagnostic("Starting monitoring: \(appCount) app(s), \(catCount) cat(s), \(webCount) web(s), budget \(dailyBudgetMinutes)m.", source: "App")
            guard appCount + catCount + webCount > 0 else {
                throw NSError(domain: "TimeTank", code: 1, userInfo: [NSLocalizedDescriptionKey: "Selection has no tokens — pick at least one app."])
            }
            try ScreenTimeScheduler.startDailyMonitoring(selection: selection, budgetMinutes: dailyBudgetMinutes)
            store.markMonitoringStarted()
            isMonitoringEnabled = true
            scheduleError = nil
            statusMessage = "TimeTank is watching the water."
            let activeSchedules = DeviceActivityCenter().activities.map { $0.rawValue }.joined(separator: ", ")
            store.recordDiagnostic("Monitoring registered OK — \(appCount) app token(s). Active: [\(activeSchedules.isEmpty ? "none!" : activeSchedules)]", source: "App")
        } catch {
            store.isMonitoringEnabled = false
            store.lastScheduleError = error.localizedDescription
            isMonitoringEnabled = false
            scheduleError = error.localizedDescription
            statusMessage = "Monitoring could not start yet."
            store.recordDiagnostic("Monitoring failed: \(error.localizedDescription)", source: "App")
        }
        refresh()
        #endif
    }

    func stopMonitoring() {
        ScreenTimeScheduler.stopMonitoring()
        ScreenTimeShielding.clearShield()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])
        store.isBudgetExceededToday = false
        store.clearBypassWindow()
        store.isMonitoringEnabled = false
        isMonitoringEnabled = false
        statusMessage = "Monitoring paused."
        store.recordDiagnostic("Monitoring paused by user.", source: "App")
        refresh()
    }

    func refresh() {
        enforceExpiredBypassIfNeeded()
        autoRestartMonitoringIfNeeded()
        #if targetEnvironment(simulator)
        isAuthorized = true
        #else
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        #endif
        hasSeenOnboarding = store.hasSeenOnboarding
        pollutionLevel = store.pollutionLevel
        bypassCount = store.bypassCount
        dailySnapshots = store.dailySnapshots
        appearanceMode = TimeTankAppearanceMode(rawValue: store.appearanceModeRawValue) ?? .light
        isBudgetLockedForToday = store.isBudgetLockedForToday
        hasBudgetBeenSet = store.hasBudgetBeenSet
        currentsBalance = store.currentsBalance
        dailyBudgetMinutes = store.dailyBudgetMinutes
        selection = store.selection
        isMonitoringEnabled = store.isMonitoringEnabled
        isBudgetExceededToday = store.isBudgetExceededToday
        bypassExpiresAt = store.bypassExpiresAt
        diagnostics = store.diagnostics
        isSimulatorDemoSelectionEnabled = store.simulatorDemoSelectionEnabled
        activeActivitySummary = ScreenTimeScheduler.activeActivitySummary
        lastMonitoringStartDate = store.lastMonitoringStartDate
        lastThresholdDate = store.lastThresholdDate
        lastShieldApplyDate = store.lastShieldApplyDate
        lastShieldClearDate = store.lastShieldClearDate
        lastShieldActionDate = store.lastShieldActionDate
        scheduleError = store.lastScheduleError
    }

    func resetProgress() {
        store.resetProgress()
        store.recordDiagnostic("Tank progress reset.", source: "App")
        refresh()
        statusMessage = "Fresh water. Finn's ready."
    }

    func clearDiagnostics() {
        store.clearDiagnostics()
        refresh()
    }

    // Start monitoring for the first time if all conditions are met and it hasn't started yet
    private func autoStartIfReady() {
        #if !targetEnvironment(simulator)
        guard isAuthorized, hasEffectiveSelection, !isMonitoringEnabled else { return }
        startMonitoring()
        #endif
    }

    // Re-start daily monitoring if it was previously enabled but the DeviceActivity schedule
    // was lost (e.g. after app reinstall or OS restart clears the system schedule)
    private func autoRestartMonitoringIfNeeded() {
        #if !targetEnvironment(simulator)
        guard isAuthorized, hasEffectiveSelection, store.isMonitoringEnabled else { return }
        guard DeviceActivityCenter().activities.isEmpty else { return }
        startMonitoring()
        #endif
    }

    private func enforceExpiredBypassIfNeeded() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])

        if store.isBypassActive(), store.isMonitoringEnabled, store.hasSelection {
            let activities = DeviceActivityCenter().activities
            if !activities.contains(TimeTankConstants.bypassActivityName) {
                if let expiresAt = store.bypassExpiresAt {
                    let remaining = expiresAt.timeIntervalSinceNow
                    if remaining > 0 {
                        let startNow = Date()
                        let windowMinutes = TimeTankRules.bypassWindowMinutes(
                            bypassCount: store.bypassCount,
                            budgetMinutes: store.dailyBudgetMinutes
                        )
                        try? ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: startNow)
                        store.recordDiagnostic("Bypass cooldown rescheduled from main app foreground.", source: "App")
                    }
                }
            }
        }

        guard store.isMonitoringEnabled, store.shouldReapplyShield() else { return }
        ScreenTimeShielding.applyShield(for: store.selection)
        store.clearBypassWindow()
        store.recordDiagnostic("Expired bypass recovered from app foreground.", source: "App")
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func durationLabel(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 { return "\(hours) hr" }
        return "\(hours)h \(remainder)m"
    }
}
