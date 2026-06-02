import FamilyControls
import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct TimeTankDiagnosticEvent: Identifiable {
    let timestamp: Date
    let source: String
    let message: String

    var id: String {
        "\(timestamp.timeIntervalSince1970)-\(source)-\(message)"
    }
}

struct TimeTankDailySnapshot: Identifiable, Codable {
    let dayKey: String
    let pollutionLevel: Double
    let bypassCount: Int
    let stateRawValue: String
    let capturedAt: Date

    var id: String { dayKey }

    var state: TimeTankMurkinessState {
        TimeTankMurkinessState(rawValue: stateRawValue) ?? .clean
    }
}

final class TimeTankStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .timeTankShared) {
        self.defaults = defaults
    }

    var dailyBudgetMinutes: Int {
        get {
            let stored = defaults.integer(forKey: TimeTankDefaultsKey.dailyBudgetMinutes)
            return stored > 0 ? stored : TimeTankConstants.defaultBudgetMinutes
        }
        set {
            defaults.set(Self.normalizedBudgetMinutes(newValue), forKey: TimeTankDefaultsKey.dailyBudgetMinutes)
            reloadWidgets()
        }
    }

    var pollutionLevel: Double {
        get {
            defaults.object(forKey: TimeTankDefaultsKey.pollutionLevel) as? Double ?? 0
        }
        set {
            defaults.set(Self.clampPollution(newValue), forKey: TimeTankDefaultsKey.pollutionLevel)
            reloadWidgets()
        }
    }

    var currentsBalance: Int {
        get { defaults.integer(forKey: TimeTankDefaultsKey.currentsBalance) }
        set {
            defaults.set(max(0, newValue), forKey: TimeTankDefaultsKey.currentsBalance)
            reloadWidgets()
        }
    }

    var isMonitoringEnabled: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.isMonitoringEnabled) }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.isMonitoringEnabled)
            reloadWidgets()
        }
    }

    var lastScheduleError: String? {
        get { defaults.string(forKey: TimeTankDefaultsKey.lastScheduleError) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastScheduleError) }
    }

    var lastBypassDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastBypassDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastBypassDate) }
    }

    var bypassExpiresAt: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.bypassExpiresAt) as? Date }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.bypassExpiresAt)
            reloadWidgets()
        }
    }

    var isBudgetExceededToday: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.isBudgetExceededToday) }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.isBudgetExceededToday)
            reloadWidgets()
        }
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.hasSeenOnboarding) }
    }

    var hasCompletedFirstSetup: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.hasCompletedFirstSetup) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.hasCompletedFirstSetup) }
    }

    // True while the install-day non-repeating schedule is active.
    // The monitor extension clears this and restarts a midnight-repeating schedule at 23:59.
    var isInstallDaySchedule: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.isInstallDaySchedule) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.isInstallDaySchedule) }
    }

    var simulatorDemoSelectionEnabled: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.simulatorDemoSelectionEnabled) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.simulatorDemoSelectionEnabled) }
    }

    var lastMonitoringStartDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastMonitoringStartDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastMonitoringStartDate) }
    }

    var budgetTrackingStartDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.budgetTrackingStartDate) as? Date }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.budgetTrackingStartDate)
            reloadWidgets()
        }
    }

    var lastThresholdDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastThresholdDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastThresholdDate) }
    }

    var lastShieldApplyDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastShieldApplyDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastShieldApplyDate) }
    }

    var lastShieldClearDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastShieldClearDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastShieldClearDate) }
    }

    var lastShieldActionDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastShieldActionDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastShieldActionDate) }
    }

    var bypassCount: Int {
        get { defaults.integer(forKey: TimeTankDefaultsKey.bypassCount) }
        set {
            defaults.set(max(0, newValue), forKey: TimeTankDefaultsKey.bypassCount)
            reloadWidgets()
        }
    }

    var budgetedAppUsedDuringBypass: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.budgetedAppUsedDuringBypass) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.budgetedAppUsedDuringBypass) }
    }

    var finalBypassPending: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.finalBypassPending) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.finalBypassPending) }
    }

    var finalBypassConfirmedToday: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.finalBypassConfirmedToday) }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.finalBypassConfirmedToday)
            reloadWidgets()
        }
    }

    var cleaningShieldActive: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.cleaningShieldActive) }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.cleaningShieldActive)
            reloadWidgets()
        }
    }

    var requiredCleaningTaps: Int {
        max(0, Int((pollutionLevel * 10).rounded()))
    }

    var diagnostics: [TimeTankDiagnosticEvent] {
        defaults.stringArray(forKey: TimeTankDefaultsKey.diagnostics)?.compactMap(Self.decodeDiagnostic) ?? []
    }

    var dailySnapshots: [TimeTankDailySnapshot] {
        get {
            guard let data = defaults.data(forKey: TimeTankDefaultsKey.dailySnapshots),
                  let snapshots = try? JSONDecoder().decode([TimeTankDailySnapshot].self, from: data) else {
                return []
            }

            return snapshots.sorted { $0.dayKey > $1.dayKey }
        }
        set {
            let limited = Array(newValue.sorted { $0.dayKey > $1.dayKey }.prefix(370))
            if let data = try? JSONEncoder().encode(limited) {
                defaults.set(data, forKey: TimeTankDefaultsKey.dailySnapshots)
            }
        }
    }

    var lastBudgetSaveDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastBudgetSaveDate) as? Date }
        set {
            defaults.set(newValue, forKey: TimeTankDefaultsKey.lastBudgetSaveDate)
            reloadWidgets()
        }
    }

    var isBudgetLockedForToday: Bool {
        guard let saved = lastBudgetSaveDate else { return false }
        return Calendar.current.isDateInToday(saved)
    }

    var hasBudgetBeenSet: Bool {
        lastBudgetSaveDate != nil
    }

    var appearanceModeRawValue: String {
        get { defaults.string(forKey: TimeTankDefaultsKey.appearanceMode) ?? TimeTankAppearanceMode.light.rawValue }
        set { defaults.set(TimeTankAppearanceMode(rawValue: newValue)?.rawValue ?? TimeTankAppearanceMode.light.rawValue, forKey: TimeTankDefaultsKey.appearanceMode) }
    }

    var selection: FamilyActivitySelection {
        get {
            // Primary read
            if let data = defaults.data(forKey: TimeTankDefaultsKey.selectionData),
               let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                return selection
            }
            // Backup read — written simultaneously on save, different key in case of key corruption
            if let data = defaults.data(forKey: TimeTankDefaultsKey.selectionDataBackup),
               let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                return selection
            }
            return FamilyActivitySelection()
        }
        set {
            // Write to both keys every time — ensures extension processes always have a valid copy
            // even if one key becomes stale or inaccessible across app group boundaries.
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: TimeTankDefaultsKey.selectionData)
                defaults.set(data, forKey: TimeTankDefaultsKey.selectionDataBackup)
            }
            defaults.synchronize()
        }
    }

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    func incrementBypassCount() {
        bypassCount += 1
        incrementPollution()
    }

    func incrementPollution(by amount: Double = TimeTankConstants.pollutionIncrement) {
        if amount == TimeTankConstants.pollutionIncrement {
            pollutionLevel = TimeTankRules.pollutionAfterBypass(currentPollution: pollutionLevel)
        } else {
            pollutionLevel = TimeTankRules.clampedPollution(pollutionLevel + amount)
        }
        lastBypassDate = Date()
    }

    func markBudgetExceeded(now: Date = Date()) {
        isBudgetExceededToday = true
        lastThresholdDate = now
        pollutionLevel = TimeTankRules.pollutionAfterBudgetReached(currentPollution: pollutionLevel)
    }

    func markMonitoringStarted(now: Date = Date()) {
        isMonitoringEnabled = true
        lastMonitoringStartDate = now
        budgetTrackingStartDate = now
        lastScheduleError = nil
    }

    func markShieldApplied(now: Date = Date()) {
        lastShieldApplyDate = now
    }

    func markShieldCleared(now: Date = Date()) {
        lastShieldClearDate = now
    }

    func markShieldAction(now: Date = Date()) {
        lastShieldActionDate = now
    }

    @discardableResult
    func startBypassWindow(windowMinutes: Int, now: Date = Date()) -> Date {
        let expiresAt = Calendar.current.date(byAdding: .minute, value: windowMinutes, to: now) ?? now
        bypassExpiresAt = expiresAt
        budgetedAppUsedDuringBypass = false
        lastBypassDate = now
        return expiresAt
    }

    func clearBypassWindow() {
        bypassExpiresAt = nil
        budgetedAppUsedDuringBypass = false
    }

    func markBudgetedAppUsedDuringBypass() {
        budgetedAppUsedDuringBypass = true
    }

    func isBypassActive(now: Date = Date()) -> Bool {
        guard let bypassExpiresAt else { return false }
        return bypassExpiresAt > now
    }

    func shouldReapplyShield(now: Date = Date()) -> Bool {
        isBudgetExceededToday && !isBypassActive(now: now) && hasSelection && !finalBypassConfirmedToday
    }

    func awardCleanDayIfNeeded(now: Date = Date()) {
        let calendar = Calendar.current
        let todayKey = Self.dayKey(for: now, calendar: calendar)
        let lastKey = defaults.string(forKey: TimeTankDefaultsKey.lastCleanEvaluationDay)

        guard lastKey != todayKey else { return }

        let hadDayToSave = lastKey != nil || isMonitoringEnabled || pollutionLevel > 0.0001 || isBudgetExceededToday || bypassCount > 0
        if hadDayToSave {
            let snapshotDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
            recordDailySnapshot(for: snapshotDay, capturedAt: now)
        }

        if pollutionLevel <= 0.0001 {
            currentsBalance += 1
        }

        // 100% pollution requires manual cleaning — apply cleaning shield, don't auto-reset
        if pollutionLevel >= TimeTankRules.maximumPollution - 0.0001 {
            cleaningShieldActive = true
        } else {
            pollutionLevel = 0
        }

        isBudgetExceededToday = false
        finalBypassConfirmedToday = false
        finalBypassPending = false
        bypassExpiresAt = nil
        bypassCount = 0
        budgetedAppUsedDuringBypass = false
        defaults.set(todayKey, forKey: TimeTankDefaultsKey.lastCleanEvaluationDay)
    }

    func recordDailySnapshot(for date: Date = Date(), capturedAt: Date = Date()) {
        let calendar = Calendar.current
        let key = Self.dayKey(for: date, calendar: calendar)
        let state = TimeTankRules.murkinessState(
            usageProgress: nil,
            isBudgetExceeded: isBudgetExceededToday,
            pollutionLevel: pollutionLevel
        )
        let snapshot = TimeTankDailySnapshot(
            dayKey: key,
            pollutionLevel: pollutionLevel,
            bypassCount: bypassCount,
            stateRawValue: state.rawValue,
            capturedAt: capturedAt
        )

        var snapshotsByKey = Dictionary(uniqueKeysWithValues: dailySnapshots.map { ($0.dayKey, $0) })
        snapshotsByKey[key] = snapshot
        dailySnapshots = Array(snapshotsByKey.values)
    }

    func snapshot(for date: Date, calendar: Calendar = .current) -> TimeTankDailySnapshot? {
        let key = Self.dayKey(for: date, calendar: calendar)
        return dailySnapshots.first { $0.dayKey == key }
    }

    func cleanTank() {
        pollutionLevel = 0
        cleaningShieldActive = false
        recordDiagnostic("Tank cleaned by user.", source: "App")
    }

    func resetProgress() {
        pollutionLevel = 0
        currentsBalance = 0
        lastBypassDate = nil
        bypassExpiresAt = nil
        isBudgetExceededToday = false
        lastScheduleError = nil
        budgetTrackingStartDate = nil
        lastThresholdDate = nil
        lastShieldActionDate = nil
        bypassCount = 0
        budgetedAppUsedDuringBypass = false
        finalBypassPending = false
        finalBypassConfirmedToday = false
        cleaningShieldActive = false
    }

    func recordDiagnostic(_ message: String, source: String, now: Date = Date()) {
        let encoded = Self.encodeDiagnostic(
            TimeTankDiagnosticEvent(timestamp: now, source: source, message: message)
        )
        let existing = defaults.stringArray(forKey: TimeTankDefaultsKey.diagnostics) ?? []
        let updated = Array(([encoded] + existing).prefix(12))
        defaults.set(updated, forKey: TimeTankDefaultsKey.diagnostics)
    }

    func clearDiagnostics() {
        defaults.removeObject(forKey: TimeTankDefaultsKey.diagnostics)
    }

    private func reloadWidgets() {
        defaults.synchronize()
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "TimeTankWidget")
        #endif
    }

    private static func clampPollution(_ value: Double) -> Double {
        TimeTankRules.clampedPollution(value)
    }

    private static func normalizedBudgetMinutes(_ value: Int) -> Int {
        min(TimeTankConstants.maximumBudgetMinutes, max(1, value))
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func encodeDiagnostic(_ event: TimeTankDiagnosticEvent) -> String {
        "\(event.timestamp.timeIntervalSince1970)|\(event.source)|\(event.message)"
    }

    private static func decodeDiagnostic(_ rawValue: String) -> TimeTankDiagnosticEvent? {
        let parts = rawValue.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, let timestamp = TimeInterval(parts[0]) else { return nil }

        return TimeTankDiagnosticEvent(
            timestamp: Date(timeIntervalSince1970: timestamp),
            source: String(parts[1]),
            message: String(parts[2])
        )
    }
}

extension UserDefaults {
    static var timeTankShared: UserDefaults {
        UserDefaults(suiteName: TimeTankConstants.appGroupIdentifier) ?? .standard
    }
}
