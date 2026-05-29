import FamilyControls
import ManagedSettings

enum ScreenTimeShielding {
    static func applyShield(for selection: FamilyActivitySelection) {
        let store = ManagedSettingsStore(named: TimeTankConstants.managedStoreName)

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        TimeTankStore().recordDiagnostic("Applied shield to current selection.", source: "Shield")
    }

    static func clearShield() {
        ManagedSettingsStore(named: TimeTankConstants.managedStoreName).clearAllSettings()
        TimeTankStore().recordDiagnostic("Cleared managed settings shield.", source: "Shield")
    }
}
