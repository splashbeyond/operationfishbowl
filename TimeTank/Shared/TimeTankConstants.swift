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
    static let bypassEventName = DeviceActivityEvent.Name("TimeTank.event.bypassEnded")

    static let defaultBudgetMinutes = 45
    static let bypassWindowMinutes = 15
    static let pollutionIncrement = 0.2
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
}
