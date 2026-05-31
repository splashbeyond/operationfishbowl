import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

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
            let windowMinutes = TimeTankRules.bypassWindowMinutes(
                bypassCount: store.bypassCount,
                budgetMinutes: store.dailyBudgetMinutes
            )
            store.bypassCount += 1
            store.incrementPollution()
            store.startBypassWindow(windowMinutes: windowMinutes, now: bypassStart)
            ScreenTimeShielding.clearShield()
            try? ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: bypassStart)
            store.recordDiagnostic("Secondary shield button tapped; bypass counted and window started.", source: "ShieldAction")
            completionHandler(.none)

        @unknown default:
            completionHandler(.none)
        }
    }
}
