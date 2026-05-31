import DeviceActivity
import Foundation
import UserNotifications

final class TimeTankMonitorExtension: DeviceActivityMonitor {
    private let store = TimeTankStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        store.recordDiagnostic("intervalDidStart: \(activity.rawValue)", source: "Monitor")

        if activity == TimeTankConstants.bypassActivityName {
            return
        }

        guard activity == TimeTankConstants.dailyActivityName else { return }

        store.awardCleanDayIfNeeded()

        // Only clear the shield if the budget has NOT already been exceeded today.
        // If budget was exceeded and monitoring was restarted (e.g. user changed settings),
        // keep the shield up rather than letting them back in.
        if !store.isBudgetExceededToday {
            ScreenTimeShielding.clearShield()
            store.recordDiagnostic("Daily interval started — shield cleared (budget not yet spent).", source: "Monitor")
        } else {
            // Budget already exceeded — re-apply shield so it stays up after a monitoring restart
            let selection = store.selection
            let tokenCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
            if tokenCount > 0 {
                ScreenTimeShielding.applyShield(for: selection)
                store.recordDiagnostic("Daily interval started — shield re-applied (budget already spent, \(tokenCount) token(s)).", source: "Monitor")
            } else {
                store.recordDiagnostic("Daily interval started — budget exceeded but selection has 0 tokens, shield not applied.", source: "Monitor")
            }
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.recordDiagnostic("intervalDidEnd: \(activity.rawValue)", source: "Monitor")

        if activity == TimeTankConstants.bypassActivityName {
            store.clearBypassWindow()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])

            if store.shouldReapplyShield() {
                let selection = store.selection
                let tokenCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
                if tokenCount > 0 {
                    ScreenTimeShielding.applyShield(for: selection)
                    store.recordDiagnostic("Shield reapplied after bypass interval ended (\(tokenCount) token(s)).", source: "Monitor")
                } else {
                    store.recordDiagnostic("Bypass ended — 0 tokens in selection, shield not reapplied.", source: "Monitor")
                }
            }
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        store.recordDiagnostic("eventDidReachThreshold: \(event.rawValue) in \(activity.rawValue)", source: "Monitor")

        if activity == TimeTankConstants.dailyActivityName && event == TimeTankConstants.budgetEventName {
            store.markBudgetExceeded()

            // Diagnose app group access — if this returns nil the extension can't read the selection
            let groupDefaults = UserDefaults(suiteName: TimeTankConstants.appGroupIdentifier)
            let primaryBytes  = groupDefaults?.data(forKey: TimeTankDefaultsKey.selectionData)?.count ?? 0
            let backupBytes   = groupDefaults?.data(forKey: TimeTankDefaultsKey.selectionDataBackup)?.count ?? 0
            store.recordDiagnostic("App group data: primary=\(primaryBytes)b backup=\(backupBytes)b", source: "Monitor")

            let selection = store.selection
            let appTokens  = selection.applicationTokens.count
            let catTokens  = selection.categoryTokens.count
            let webTokens  = selection.webDomainTokens.count
            let totalTokens = appTokens + catTokens + webTokens

            store.recordDiagnostic("Budget threshold reached — applying shield to \(appTokens) app(s), \(catTokens) cat(s), \(webTokens) web(s).", source: "Monitor")

            if totalTokens > 0 {
                ScreenTimeShielding.applyShield(for: selection)
                scheduleThresholdNotification()
            } else {
                // Selection has no tokens in this process — this is a critical failure.
                // Send a notification so the user knows their budget ran out even though
                // the shield could not be applied.
                store.recordDiagnostic("CRITICAL: 0 tokens in selection — shield NOT applied. Check app group UserDefaults.", source: "Monitor")
                scheduleThresholdNotification(shieldFailed: true)
            }
        }

        if activity == TimeTankConstants.bypassActivityName && event == TimeTankConstants.bypassUsageEventName {
            store.markBudgetedAppUsedDuringBypass()
            scheduleBypassExpiryNotification()
            store.recordDiagnostic("Budgeted app usage detected during bypass.", source: "Monitor")
        }
    }

    // MARK: - Notifications

    private func scheduleThresholdNotification(shieldFailed: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = "Budget spent."
        if shieldFailed {
            content.body = "Open TimeTank to re-activate Finn's protection."
        } else {
            content.body = "Finn's watching. Your selected apps are now blocked."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "budget-reached",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleBypassExpiryNotification() {
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
