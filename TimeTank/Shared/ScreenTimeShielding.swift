import FamilyControls
import ManagedSettings

enum ScreenTimeShielding {
    static func applyShield(for selection: FamilyActivitySelection) {
        let store = ManagedSettingsStore(named: TimeTankConstants.managedStoreName)

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)

        let timeTankStore = TimeTankStore()
        timeTankStore.markShieldApplied()
        timeTankStore.recordDiagnostic("Applied shield to \(selection.applicationTokens.count) app(s), \(selection.categoryTokens.count) category token(s), \(selection.webDomainTokens.count) web domain(s).", source: "Shield")
    }

    static func clearShield() {
        ManagedSettingsStore(named: TimeTankConstants.managedStoreName).clearAllSettings()
        let store = TimeTankStore()
        store.markShieldCleared()
        store.recordDiagnostic("Cleared managed settings shield.", source: "Shield")
    }
}
