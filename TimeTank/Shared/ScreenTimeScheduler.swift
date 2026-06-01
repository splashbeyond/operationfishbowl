import DeviceActivity
import FamilyControls
import Foundation

enum ScreenTimeScheduler {
    // startFromNow = true on first install: creates a non-repeating schedule that begins
    // at the current time so pre-install usage never counts against the budget.
    // The monitor extension's intervalDidEnd restarts with the normal midnight schedule at 23:59.
    static func startDailyMonitoring(selection: FamilyActivitySelection, budgetMinutes: Int, startFromNow: Bool = false) throws {
        let center = DeviceActivityCenter()
        // Always stop first — re-calling startMonitoring on an active name is a no-op on some OS
        // versions and an error on others; stopping guarantees a clean slate with the new threshold.
        center.stopMonitoring([TimeTankConstants.dailyActivityName])

        let intervalStart: DateComponents
        let repeats: Bool

        if startFromNow {
            // Start 5 seconds ahead so the schedule isn't stale by the time the OS registers it.
            let buffered = Calendar.current.date(byAdding: .second, value: 5, to: Date()) ?? Date()
            intervalStart = Calendar.current.dateComponents([.hour, .minute, .second], from: buffered)
            repeats = false
        } else {
            intervalStart = DateComponents(hour: 0, minute: 0)
            repeats = true
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: repeats
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: max(1, budgetMinutes))
        )

        try center.startMonitoring(
            TimeTankConstants.dailyActivityName,
            during: schedule,
            events: [TimeTankConstants.budgetEventName: event]
        )
    }

    static func startBypassCooldown(selection: FamilyActivitySelection, windowMinutes: Int, now: Date = Date()) throws {
        let center = DeviceActivityCenter()
        center.stopMonitoring([TimeTankConstants.bypassActivityName])

        let calendar = Calendar.current
        // Buffer the start 10 seconds ahead so the schedule isn't stale by the time
        // the system registers it — important when called from extension processes.
        let start = calendar.date(byAdding: .second, value: 10, to: now) ?? now
        let intendedEnd = calendar.date(byAdding: .minute, value: windowMinutes, to: now) ?? now
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? intendedEnd
        let end = min(intendedEnd, endOfDay)
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: end)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(second: TimeTankConstants.bypassUsageEvidenceSeconds)
        )

        try center.startMonitoring(
            TimeTankConstants.bypassActivityName,
            during: schedule,
            events: [TimeTankConstants.bypassUsageEventName: event]
        )
    }

    static var activeActivitySummary: String {
        let activities = DeviceActivityCenter().activities
        guard !activities.isEmpty else { return "None" }
        return activities.map { String(describing: $0) }.joined(separator: ", ")
    }

    static func stopMonitoring() {
        DeviceActivityCenter().stopMonitoring([
            TimeTankConstants.dailyActivityName,
            TimeTankConstants.bypassActivityName
        ])
    }
}
