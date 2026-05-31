import FamilyControls
import ManagedSettings

enum ScreenTimeShielding {
    static func applyShield(for selection: FamilyActivitySelection) {
        let appTokens  = selection.applicationTokens
        let catTokens  = selection.categoryTokens
        let webTokens  = selection.webDomainTokens

        // Bail out entirely if the selection is empty — setting all to nil just clears shields.
        guard !appTokens.isEmpty || !catTokens.isEmpty || !webTokens.isEmpty else {
            let store = TimeTankStore()
            store.recordDiagnostic("applyShield called with empty selection — skipped.", source: "Shield")
            return
        }

        let managedStore = ManagedSettingsStore(named: TimeTankConstants.managedStoreName)
        managedStore.shield.applications        = appTokens.isEmpty ? nil : appTokens
        managedStore.shield.applicationCategories = catTokens.isEmpty ? nil : .specific(catTokens)
        managedStore.shield.webDomains          = webTokens.isEmpty ? nil : webTokens
        managedStore.shield.webDomainCategories = catTokens.isEmpty ? nil : .specific(catTokens)

        let timeTankStore = TimeTankStore()
        timeTankStore.markShieldApplied()
        timeTankStore.recordDiagnostic(
            "Shield applied: \(appTokens.count) app(s), \(catTokens.count) cat(s), \(webTokens.count) web(s).",
            source: "Shield"
        )
    }

    static func clearShield() {
        ManagedSettingsStore(named: TimeTankConstants.managedStoreName).clearAllSettings()
        let store = TimeTankStore()
        store.markShieldCleared()
        store.recordDiagnostic("Shield cleared.", source: "Shield")
    }
}
