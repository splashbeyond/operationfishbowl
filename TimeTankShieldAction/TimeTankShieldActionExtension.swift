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
            let windowMinutes = TimeTankRules.bypassWindowMinutes(bypassCount: store.bypassCount, budgetMinutes: store.dailyBudgetMinutes)
            store.startBypassWindow(now: bypassStart)
            ScreenTimeShielding.clearShield()
            // Attempt to schedule the bypass cooldown directly from the extension.
            // If this fails (extensions are unreliable), the main app's scene-active
            // observer will reschedule it on next foreground.
            try? ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: bypassStart)
            store.recordDiagnostic("Secondary shield button tapped; bypass window started.", source: "ShieldAction")
            completionHandler(.close)

        @unknown default:
            completionHandler(.none)
        }
    }
}
