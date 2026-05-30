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
            // Don't count the bypass yet — only increment if the user actually uses
            // the app during the window (handled in TimeTankMonitorExtension.eventDidReachThreshold)
            store.startBypassWindow(now: Date())
            ScreenTimeShielding.clearShield()
            store.recordDiagnostic("Secondary shield button tapped; bypass window started.", source: "ShieldAction")
            completionHandler(.close)

        @unknown default:
            completionHandler(.none)
        }
    }
}
