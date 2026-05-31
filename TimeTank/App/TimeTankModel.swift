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
    var overflowSeconds: TimeInterval
    var statusMessage = "Pick the apps that eat your time."
    var authorizationError: String?
    var scheduleError: String?

    private let store = TimeTankStore()

    init() {
        bypassCount = store.bypassCount
        overflowSeconds = store.overflowSeconds
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

    var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
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
        autoStartIfReady()
    }

    func enableSimulatorDemoSelection() {
        store.simulatorDemoSelectionEnabled = true
        isSimulatorDemoSelectionEnabled = true
        statusMessage = "Simulator demo selection is ready."
        store.recordDiagnostic("Simulator demo selection enabled.", source: "App")
        refresh()
    }

    func saveBudget(minutes: Int) {
        dailyBudgetMinutes = max(1, minutes)
        store.dailyBudgetMinutes = dailyBudgetMinutes
        statusMessage = "Got it. \(dailyBudgetMinutes) minutes. Finn's counting on you."
        store.recordDiagnostic("Budget saved: \(dailyBudgetMinutes) minute(s).", source: "App")
        refresh()
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
            try ScreenTimeScheduler.startDailyMonitoring(selection: selection, budgetMinutes: dailyBudgetMinutes)
            store.markMonitoringStarted()
            isMonitoringEnabled = true
            scheduleError = nil
            statusMessage = "TimeTank is watching the water."
            store.recordDiagnostic("Daily monitoring started for \(dailyBudgetMinutes) minute budget.", source: "App")
        } catch {
            store.isMonitoringEnabled = false
            store.lastScheduleError = error.localizedDescription
            isMonitoringEnabled = false
            scheduleError = error.localizedDescription
            statusMessage = "Monitoring could not start yet."
            store.recordDiagnostic("Daily monitoring failed: \(error.localizedDescription)", source: "App")
        }
        refresh()
        #endif
    }

    func stopMonitoring() {
        ScreenTimeScheduler.stopMonitoring()
        ScreenTimeShielding.clearShield()
        store.isBudgetExceededToday = false
        store.clearBypassWindow()
        store.isMonitoringEnabled = false
        isMonitoringEnabled = false
        statusMessage = "Monitoring paused."
        store.recordDiagnostic("Monitoring paused by user.", source: "App")
        refresh()
    }

    func startOneMinuteDeviceTest() {
        guard isAuthorized else {
            scheduleError = "Approve Screen Time access before starting the device test."
            store.recordDiagnostic("One-minute test blocked: missing authorization.", source: "App")
            refresh()
            return
        }

        guard hasSelection else {
            scheduleError = "Pick at least one real app before starting the device test."
            store.recordDiagnostic("One-minute test blocked: no real selection.", source: "App")
            refresh()
            return
        }

        #if targetEnvironment(simulator)
        statusMessage = "Use Simulator demo mode here. The one-minute test needs an iPhone."
        store.recordDiagnostic("One-minute test skipped in Simulator.", source: "App")
        refresh()
        #else
        do {
            try ScreenTimeScheduler.startDailyMonitoring(selection: selection, budgetMinutes: 1)
            dailyBudgetMinutes = 1
            store.dailyBudgetMinutes = 1
            store.markMonitoringStarted()
            store.isBudgetExceededToday = false
            store.clearBypassWindow()
            isMonitoringEnabled = true
            scheduleError = nil
            statusMessage = "One-minute device test is running. Open a selected app for over a minute."
            store.recordDiagnostic("One-minute device test started.", source: "App")
        } catch {
            store.isMonitoringEnabled = false
            store.lastScheduleError = error.localizedDescription
            isMonitoringEnabled = false
            scheduleError = error.localizedDescription
            statusMessage = "Device test could not start."
            store.recordDiagnostic("One-minute device test failed: \(error.localizedDescription)", source: "App")
        }
        refresh()
        #endif
    }

    func applyShieldNowForDeviceTest() {
        guard hasSelection else {
            scheduleError = "Pick at least one real app before applying a test shield."
            store.recordDiagnostic("Manual shield blocked: no real selection.", source: "App")
            refresh()
            return
        }

        ScreenTimeShielding.applyShield(for: selection)
        store.markBudgetExceeded()
        statusMessage = "Manual shield applied. Open a selected app to verify the block."
        store.recordDiagnostic("Manual shield applied from Settings.", source: "App")
        refresh()
    }

    func clearShieldForDeviceTest() {
        ScreenTimeShielding.clearShield()
        store.clearBypassWindow()
        statusMessage = "Manual shield cleared."
        store.recordDiagnostic("Manual shield cleared from Settings.", source: "App")
        refresh()
    }

    func refresh() {
        store.recalculatePollution()
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
        overflowSeconds = store.overflowSeconds
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

    #if DEBUG
    func debugAddPollution() {
        store.isBudgetExceededToday = true
        store.bypassCount += 1
        store.overflowSeconds += Double(store.dailyBudgetMinutes) * 60.0 * 0.1
        store.recalculatePollution()
        refresh()
        statusMessage = "The water just got murkier."
    }

    func debugAwardCurrent() {
        store.currentsBalance += 1
        refresh()
        statusMessage = "Clean day. Finn's happy. +1 Current earned."
    }
    #endif

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
        if store.isBypassActive(), store.isMonitoringEnabled, store.hasSelection {
            let activities = DeviceActivityCenter().activities
            if !activities.contains(TimeTankConstants.bypassActivityName) {
                if let expiresAt = store.bypassExpiresAt {
                    let remaining = expiresAt.timeIntervalSinceNow
                    if remaining > 0 {
                        let startNow = Date()
                        let windowMinutes = TimeTankRules.bypassWindowMinutes(bypassCount: store.bypassCount, budgetMinutes: store.dailyBudgetMinutes)
                        try? ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: startNow)
                        scheduleBypassExpiryNotification(at: expiresAt)
                        store.recordDiagnostic("Bypass cooldown rescheduled from main app foreground.", source: "App")
                    }
                }
            }
        }

        guard store.isMonitoringEnabled, store.shouldReapplyShield() else { return }
        ScreenTimeShielding.applyShield(for: store.selection)
        store.clearBypassWindow()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])
        store.recordDiagnostic("Expired bypass recovered from app foreground.", source: "App")
    }

    private func scheduleBypassExpiryNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])

        let content = UNMutableNotificationContent()
        content.title = "Finn needs you back"
        content.body = "Your bypass window is up. Open TimeTank to check on the tank."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "bypass-expiry", content: content, trigger: trigger)
        center.add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
