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
            store.incrementBypassCount()
            let bypassStartedAt = Date()
            store.startBypassWindow(now: bypassStartedAt)
            ScreenTimeShielding.clearShield()
            store.recordDiagnostic("Secondary shield button tapped; bypass started.", source: "ShieldAction")

            do {
                try ScreenTimeScheduler.startBypassCooldown(selection: store.selection, now: bypassStartedAt)
                store.lastScheduleError = nil
                store.recordDiagnostic("Bypass cooldown monitoring started.", source: "ShieldAction")
            } catch {
                store.lastScheduleError = error.localizedDescription
                store.recordDiagnostic("Bypass schedule failed: \(error.localizedDescription)", source: "ShieldAction")
            }

            completionHandler(.none)

        @unknown default:
            completionHandler(.none)
        }
    }
}
