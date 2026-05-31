import DeviceActivity
import Foundation
import UserNotifications

final class TimeTankMonitorExtension: DeviceActivityMonitor {
    private let store = TimeTankStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        if activity == TimeTankConstants.bypassActivityName {
            store.recordDiagnostic("Bypass interval started.", source: "Monitor")
            return
        }

        guard activity == TimeTankConstants.dailyActivityName else {
            store.recordDiagnostic("Unknown interval started: \(String(describing: activity)).", source: "Monitor")
            return
        }

        store.awardCleanDayIfNeeded()
        ScreenTimeShielding.clearShield()
        store.recordDiagnostic("Daily interval started; progress evaluated.", source: "Monitor")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity == TimeTankConstants.bypassActivityName {
            store.clearBypassWindow()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])
            store.recordDiagnostic("Bypass interval ended.", source: "Monitor")

            if store.shouldReapplyShield() {
                ScreenTimeShielding.applyShield(for: store.selection)
                store.recordDiagnostic("Shield reapplied after bypass interval ended.", source: "Monitor")
            }
        }

        if activity == TimeTankConstants.dailyActivityName {
            store.recordDiagnostic("Daily interval ended.", source: "Monitor")
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        if activity == TimeTankConstants.dailyActivityName && event == TimeTankConstants.budgetEventName {
            store.markBudgetExceeded()
            store.recordDiagnostic("Daily budget threshold reached.", source: "Monitor")
            ScreenTimeShielding.applyShield(for: store.selection)
        }

        if activity == TimeTankConstants.bypassActivityName && event == TimeTankConstants.bypassUsageEventName {
            store.markBudgetedAppUsedDuringBypass()
            scheduleBypassExpiryNotificationIfNeeded()
            store.recordDiagnostic("Budgeted app usage detected during bypass; expiry notification armed.", source: "Monitor")
        }
    }

    private func scheduleBypassExpiryNotificationIfNeeded() {
        guard store.isBypassActive(), let expiresAt = store.bypassExpiresAt else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])

        let content = UNMutableNotificationContent()
        content.title = "Bypass ended."
        content.body = "TimeTank is protecting your distraction budget again."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, expiresAt.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "bypass-expiry", content: content, trigger: trigger)
        center.add(request)
    }
}
