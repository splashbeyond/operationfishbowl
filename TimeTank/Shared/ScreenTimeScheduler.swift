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

    // endsAt: pass the exact expiry Date when recovering an existing bypass window so the
    // schedule matches the original intent rather than recalculating from windowMinutes.
    static func startBypassCooldown(
        selection: FamilyActivitySelection,
        windowMinutes: Int,
        now: Date = Date(),
        endsAt: Date? = nil
    ) throws {
        let center = DeviceActivityCenter()
        center.stopMonitoring([TimeTankConstants.bypassActivityName])

        let calendar = Calendar.current
        // 5-second buffer — enough for extension registration lag without eating short windows.
        let start = calendar.date(byAdding: .second, value: 5, to: now) ?? now
        let intendedEnd = endsAt ?? (calendar.date(byAdding: .minute, value: windowMinutes, to: now) ?? now)
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

        // startMonitoring can return without throwing but still not register.
        // Verify the activity actually appears in the center before returning.
        guard center.activities.contains(TimeTankConstants.bypassActivityName) else {
            throw NSError(
                domain: "TimeTank",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Bypass activity not found in DeviceActivityCenter after registration."]
            )
        }
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
