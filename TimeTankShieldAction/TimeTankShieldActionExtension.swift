import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

final class TimeTankShieldActionExtension: ShieldActionDelegate {
    private let store = TimeTankStore()

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, completionHandler: completionHandler)
    }

    private func handle(action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            store.markShieldAction()
            store.recordDiagnostic("Primary shield button tapped.", source: "ShieldAction")
            completionHandler(.close)

        case .secondaryButtonPressed:
            store.markShieldAction()
            let bypassStart = Date()
            // Calculate window BEFORE incrementing so all three use the same value
            let windowMinutes = TimeTankRules.bypassWindowMinutes(bypassCount: store.bypassCount, budgetMinutes: store.dailyBudgetMinutes)
            store.incrementBypassCount()
            store.startBypassWindow(windowMinutes: windowMinutes, now: bypassStart)
            ScreenTimeShielding.clearShield()
            try? ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: bypassStart)
            scheduleBypassExpiryNotification(pollution: store.pollutionLevel, windowMinutes: windowMinutes, from: bypassStart)
            store.recordDiagnostic("Secondary shield button tapped; bypass counted and window started.", source: "ShieldAction")
            completionHandler(.none)

        @unknown default:
            completionHandler(.none)
        }
    }

    private func scheduleBypassExpiryNotification(pollution: Double, windowMinutes: Int, from start: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["bypass-expiry"])

        let content = UNMutableNotificationContent()
        let (title, body) = finnNotificationCopy(for: pollution)
        content.title = title
        content.body = body
        content.sound = .default

        let fireDate = start.addingTimeInterval(Double(windowMinutes) * 60)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, fireDate.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "bypass-expiry", content: content, trigger: trigger)
        center.add(request)
    }

    private func finnNotificationCopy(for pollution: Double) -> (String, String) {
        switch pollution {
        case 0..<0.2:
            return ("Check in on Finn!", "He noticed you're spending time on this app. He wants to see you.")
        case 0.2..<0.4:
            return ("Finn misses you.", "The tank is getting a little murky. Come check on him.")
        case 0.4..<0.6:
            return ("Finn is worried.", "The water's clouding up and he's waiting for you.")
        case 0.6..<0.8:
            return ("Finn really needs you.", "The tank is getting bad. He can't hold on much longer.")
        default:
            return ("Finn is suffering.", "The water is almost gone. Please come back to him.")
        }
    }
}
