import FamilyControls
import Foundation

struct TimeTankDiagnosticEvent: Identifiable {
    let timestamp: Date
    let source: String
    let message: String

    var id: String {
        "\(timestamp.timeIntervalSince1970)-\(source)-\(message)"
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
            defaults.set(max(1, newValue), forKey: TimeTankDefaultsKey.dailyBudgetMinutes)
        }
    }

    var pollutionLevel: Double {
        get {
            defaults.object(forKey: TimeTankDefaultsKey.pollutionLevel) as? Double ?? 0
        }
        set {
            defaults.set(Self.clampPollution(newValue), forKey: TimeTankDefaultsKey.pollutionLevel)
        }
    }

    var currentsBalance: Int {
        get { defaults.integer(forKey: TimeTankDefaultsKey.currentsBalance) }
        set { defaults.set(max(0, newValue), forKey: TimeTankDefaultsKey.currentsBalance) }
    }

    var isMonitoringEnabled: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.isMonitoringEnabled) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.isMonitoringEnabled) }
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
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.bypassExpiresAt) }
    }

    var isBudgetExceededToday: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.isBudgetExceededToday) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.isBudgetExceededToday) }
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.hasSeenOnboarding) }
    }

    var simulatorDemoSelectionEnabled: Bool {
        get { defaults.bool(forKey: TimeTankDefaultsKey.simulatorDemoSelectionEnabled) }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.simulatorDemoSelectionEnabled) }
    }

    var lastMonitoringStartDate: Date? {
        get { defaults.object(forKey: TimeTankDefaultsKey.lastMonitoringStartDate) as? Date }
        set { defaults.set(newValue, forKey: TimeTankDefaultsKey.lastMonitoringStartDate) }
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
        set { defaults.set(max(0, newValue), forKey: TimeTankDefaultsKey.bypassCount) }
    }

    var overflowSeconds: TimeInterval {
        get { defaults.double(forKey: TimeTankDefaultsKey.overflowSeconds) }
        set { defaults.set(max(0, newValue), forKey: TimeTankDefaultsKey.overflowSeconds) }
    }

    var diagnostics: [TimeTankDiagnosticEvent] {
        defaults.stringArray(forKey: TimeTankDefaultsKey.diagnostics)?.compactMap(Self.decodeDiagnostic) ?? []
    }

    var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: TimeTankDefaultsKey.selectionData),
                  let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
                return FamilyActivitySelection()
            }

            return selection
        }
        set {
            if let data = try? PropertyListEncoder().encode(newValue) {
                defaults.set(data, forKey: TimeTankDefaultsKey.selectionData)
            }
        }
    }

    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    func incrementBypassCount() {
        bypassCount += 1
        lastBypassDate = Date()
        recalculatePollution()
    }

    func recalculatePollution() {
        guard isBudgetExceededToday else { return }
        pollutionLevel = TimeTankRules.continuousPollution(
            overflowSeconds: overflowSeconds,
            budgetMinutes: dailyBudgetMinutes,
            bypassCount: bypassCount
        )
    }

    func markBudgetExceeded(now: Date = Date()) {
        isBudgetExceededToday = true
        lastThresholdDate = now
        // Pollution rises with actual overflow time + bypasses — no flat initial bump
    }

    func markMonitoringStarted(now: Date = Date()) {
        isMonitoringEnabled = true
        lastMonitoringStartDate = now
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
    func startBypassWindow(now: Date = Date()) -> Date {
        let minutes = TimeTankRules.bypassWindowMinutes(bypassCount: bypassCount, budgetMinutes: dailyBudgetMinutes)
        let expiresAt = Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        bypassExpiresAt = expiresAt
        lastBypassDate = now
        return expiresAt
    }

    func clearBypassWindow() {
        bypassExpiresAt = nil
    }

    func isBypassActive(now: Date = Date()) -> Bool {
        guard let bypassExpiresAt else { return false }
        return bypassExpiresAt > now
    }

    func shouldReapplyShield(now: Date = Date()) -> Bool {
        isBudgetExceededToday && !isBypassActive(now: now) && hasSelection
    }

    func awardCleanDayIfNeeded(now: Date = Date()) {
        let calendar = Calendar.current
        let todayKey = Self.dayKey(for: now, calendar: calendar)
        let lastKey = defaults.string(forKey: TimeTankDefaultsKey.lastCleanEvaluationDay)

        guard lastKey != todayKey else { return }

        if pollutionLevel <= 0.0001 {
            currentsBalance += 1
        }

        pollutionLevel = 0
        isBudgetExceededToday = false
        bypassExpiresAt = nil
        bypassCount = 0
        overflowSeconds = 0
        defaults.set(todayKey, forKey: TimeTankDefaultsKey.lastCleanEvaluationDay)
    }

    func resetProgress() {
        pollutionLevel = 0
        currentsBalance = 0
        lastBypassDate = nil
        bypassExpiresAt = nil
        isBudgetExceededToday = false
        lastScheduleError = nil
        lastThresholdDate = nil
        lastShieldActionDate = nil
        bypassCount = 0
        overflowSeconds = 0
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

    private static func clampPollution(_ value: Double) -> Double {
        TimeTankRules.clampedPollution(value)
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
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
