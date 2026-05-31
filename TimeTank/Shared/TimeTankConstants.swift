import DeviceActivity
import Foundation
import ManagedSettings

enum TimeTankConstants {
    static let appGroupIdentifier = "group.com.piperstudio.timetank"
    static let bundleIdentifier = "com.piperstudio.timetank"
    static let managedStoreName = ManagedSettingsStore.Name("TimeTankShieldStore")

    static let dailyActivityName = DeviceActivityName("TimeTank.daily.distractions")
    static let budgetEventName = DeviceActivityEvent.Name("TimeTank.event.budgetReached")
    static let bypassActivityName = DeviceActivityName("TimeTank.bypass.cooldown")
    static let bypassUsageEventName = DeviceActivityEvent.Name("TimeTank.event.bypassUsageDetected")
    static let reportContextIdentifier = "TimeTank.usage.summary"
    static let allAppsReportContextIdentifier = "TimeTank.usage.all"

    static let defaultBudgetMinutes = 45
    static let maximumBudgetMinutes = 720
    static let bypassUsageEvidenceSeconds = 30
    static let pollutionIncrement = TimeTankRules.bypassPollutionIncrement
}

enum TimeTankAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

enum TimeTankDefaultsKey {
    static let selectionData = "selectedDistractionApps"
    static let dailyBudgetMinutes = "dailyBudgetMinutes"
    static let pollutionLevel = "pollutionLevel"
    static let currentsBalance = "currentsBalance"
    static let lastScheduleError = "lastScheduleError"
    static let isMonitoringEnabled = "isMonitoringEnabled"
    static let lastCleanEvaluationDay = "lastCleanEvaluationDay"
    static let lastBypassDate = "lastBypassDate"
    static let bypassExpiresAt = "bypassExpiresAt"
    static let isBudgetExceededToday = "isBudgetExceededToday"
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let diagnostics = "diagnostics"
    static let simulatorDemoSelectionEnabled = "simulatorDemoSelectionEnabled"
    static let lastMonitoringStartDate = "lastMonitoringStartDate"
    static let lastThresholdDate = "lastThresholdDate"
    static let lastShieldApplyDate = "lastShieldApplyDate"
    static let lastShieldClearDate = "lastShieldClearDate"
    static let lastShieldActionDate = "lastShieldActionDate"
    static let bypassCount = "bypassCount"
    static let budgetedAppUsedDuringBypass = "budgetedAppUsedDuringBypass"
    static let dailySnapshots = "dailySnapshots"
    static let appearanceMode = "appearanceMode"
}
