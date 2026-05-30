import DeviceActivity
import FamilyControls
import Foundation

enum ScreenTimeScheduler {
    static func startDailyMonitoring(selection: FamilyActivitySelection, budgetMinutes: Int) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: max(1, budgetMinutes))
        )

        try DeviceActivityCenter().startMonitoring(
            TimeTankConstants.dailyActivityName,
            during: schedule,
            events: [TimeTankConstants.budgetEventName: event]
        )
    }

    static func startBypassCooldown(selection: FamilyActivitySelection, now: Date = Date()) throws {
        let calendar = Calendar.current
        let intendedEnd = calendar.date(byAdding: .minute, value: TimeTankConstants.bypassWindowMinutes, to: now) ?? now
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? intendedEnd
        let end = min(intendedEnd, endOfDay)
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
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
            threshold: DateComponents(minute: TimeTankConstants.bypassWindowMinutes)
        )

        try DeviceActivityCenter().startMonitoring(
            TimeTankConstants.bypassActivityName,
            during: schedule,
            events: [TimeTankConstants.bypassEventName: event]
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
