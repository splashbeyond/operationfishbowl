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
        let cleaningActive = store.cleaningShieldActive
        let atMaxPollution = store.pollutionLevel >= TimeTankRules.maximumPollution - 0.0001
        let finalPending   = store.finalBypassPending

        // Cleaning shield has only a primary button — always close
        if cleaningActive {
            store.markShieldAction()
            store.recordDiagnostic("Cleaning shield dismissed — user must open TimeTank.", source: "ShieldAction")
            completionHandler(.close)
            return
        }

        switch action {
        case .primaryButtonPressed:
            store.markShieldAction()
            if finalPending {
                store.finalBypassPending = false
                store.recordDiagnostic("Final bypass cancelled at stage 2.", source: "ShieldAction")
            } else {
                store.recordDiagnostic("Primary shield button tapped.", source: "ShieldAction")
            }
            completionHandler(.close)

        case .secondaryButtonPressed:
            store.markShieldAction()

            if atMaxPollution && !finalPending {
                // Stage 1: set pending flag, close — user must reopen the app to confirm
                store.finalBypassPending = true
                store.recordDiagnostic("Final bypass stage 1 — pending confirmation.", source: "ShieldAction")
                completionHandler(.close)

            } else if atMaxPollution && finalPending {
                // Stage 2: confirmed — unlock for the rest of the day, no bypass window
                store.finalBypassPending = false
                store.finalBypassConfirmedToday = true
                ScreenTimeShielding.clearShield()
                store.recordDiagnostic("Final bypass confirmed — unlocked for day.", source: "ShieldAction")
                completionHandler(.none)

            } else {
                // Normal bypass
                let bypassStart = Date()
                let windowMinutes = TimeTankRules.bypassWindowMinutes(
                    bypassCount: store.bypassCount,
                    budgetMinutes: store.dailyBudgetMinutes
                )
                store.bypassCount += 1
                store.incrementPollution()
                store.startBypassWindow(windowMinutes: windowMinutes, now: bypassStart)
                ScreenTimeShielding.clearShield()
                do {
                    try ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: bypassStart)
                    store.recordDiagnostic("Bypass granted: window=\(windowMinutes)m.", source: "ShieldAction")
                } catch {
                    store.recordDiagnostic("Bypass cooldown attempt 1 failed: \(error.localizedDescription) — retrying.", source: "ShieldAction")
                    do {
                        try ScreenTimeScheduler.startBypassCooldown(selection: store.selection, windowMinutes: windowMinutes, now: bypassStart)
                        store.recordDiagnostic("Bypass cooldown registered on retry.", source: "ShieldAction")
                    } catch {
                        store.recordDiagnostic("Bypass cooldown failed after retry: \(error.localizedDescription)", source: "ShieldAction")
                    }
                }
                completionHandler(.none)
            }

        default:
            completionHandler(.none)
        }
    }
}
