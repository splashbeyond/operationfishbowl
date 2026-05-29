import FamilyControls
import Foundation
import Observation

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
    var statusMessage = "Pick the apps that eat your time."
    var authorizationError: String?
    var scheduleError: String?

    private let store = TimeTankStore()

    init() {
        selection = store.selection
        dailyBudgetMinutes = store.dailyBudgetMinutes
        pollutionLevel = store.pollutionLevel
        currentsBalance = store.currentsBalance
        isMonitoringEnabled = store.isMonitoringEnabled
        isBudgetExceededToday = store.isBudgetExceededToday
        bypassExpiresAt = store.bypassExpiresAt
        diagnostics = store.diagnostics
        scheduleError = store.lastScheduleError
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        hasSeenOnboarding = store.hasSeenOnboarding
        enforceExpiredBypassIfNeeded()
    }

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    var selectedItemCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    var remainingMinutesEstimate: Int {
        max(0, Int(Double(dailyBudgetMinutes) * (1 - pollutionLevel)))
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            authorizationError = nil
            statusMessage = "Authorization ready. Finn can watch the tank."
            store.recordDiagnostic("Authorization request completed: \(isAuthorized ? "approved" : "not approved").", source: "App")
        } catch {
            isAuthorized = false
            authorizationError = error.localizedDescription
            statusMessage = "Screen Time access is needed before Finn can help."
            store.recordDiagnostic("Authorization request failed: \(error.localizedDescription)", source: "App")
        }
        refresh()
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        store.hasSeenOnboarding = true
    }

    func saveSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        store.selection = newSelection
        statusMessage = hasSelection ? "Selection saved. Finn has a reason to care." : "Pick something. Finn needs a reason to care."
        store.recordDiagnostic("Selection saved with \(selectedItemCount) item(s).", source: "App")
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
        guard hasSelection else {
            scheduleError = "Select at least one app, category, or website first."
            statusMessage = "Pick something. Finn needs a reason to care."
            store.recordDiagnostic("Monitoring start blocked: no selection.", source: "App")
            refresh()
            return
        }

        do {
            try ScreenTimeScheduler.startDailyMonitoring(selection: selection, budgetMinutes: dailyBudgetMinutes)
            store.isMonitoringEnabled = true
            store.lastScheduleError = nil
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

    func refresh() {
        enforceExpiredBypassIfNeeded()
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        hasSeenOnboarding = store.hasSeenOnboarding
        pollutionLevel = store.pollutionLevel
        currentsBalance = store.currentsBalance
        dailyBudgetMinutes = store.dailyBudgetMinutes
        selection = store.selection
        isMonitoringEnabled = store.isMonitoringEnabled
        isBudgetExceededToday = store.isBudgetExceededToday
        bypassExpiresAt = store.bypassExpiresAt
        diagnostics = store.diagnostics
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
        store.incrementPollution()
        refresh()
        statusMessage = "The water just got murkier."
    }

    func debugAwardCurrent() {
        store.currentsBalance += 1
        refresh()
        statusMessage = "Clean day. Finn's happy. +1 Current earned."
    }
    #endif

    private func enforceExpiredBypassIfNeeded() {
        guard store.isMonitoringEnabled, store.shouldReapplyShield() else { return }

        ScreenTimeShielding.applyShield(for: store.selection)
        store.clearBypassWindow()
        store.recordDiagnostic("Expired bypass recovered from app foreground.", source: "App")
    }
}
