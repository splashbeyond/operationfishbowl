import Foundation

struct AcceptanceFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw AcceptanceFailure(description: message)
    }
}

func read(_ path: String) throws -> String {
    try String(contentsOfFile: path, encoding: .utf8)
}

@main
struct VerifyMVPAcceptance {
    static func main() throws {
        let dashboard = try read("TimeTank/App/TankDashboardView.swift")
        let stats = try read("TimeTank/App/StatsView.swift")
        let store = try read("TimeTank/Shared/TimeTankStore.swift")
        let monitor = try read("TimeTankMonitor/TimeTankMonitorExtension.swift")
        let shieldAction = try read("TimeTankShieldAction/TimeTankShieldActionExtension.swift")
        let settings = try read("TimeTank/App/SettingsView.swift")
        let scheduler = try read("TimeTank/Shared/ScreenTimeScheduler.swift")
        let budget = try read("TimeTank/App/BudgetSetupView.swift")

        try expect(
            !dashboard.contains("DeviceActivityReport"),
            "Dashboard must not host Screen Time reports; Stats owns reports for MVP simplicity."
        )
        try expect(
            dashboard.contains("Distraction Budget"),
            "Dashboard must frame the product around the selected distraction budget."
        )
        try expect(
            stats.contains("DeviceActivityReport"),
            "Stats must host the DeviceActivityReport."
        )
        try expect(
            stats.contains("applications: model.selection.applicationTokens") &&
            stats.contains("categories: model.selection.categoryTokens") &&
            stats.contains("webDomains: model.selection.webDomainTokens"),
            "Stats report must be scoped to the selected distraction bucket."
        )
        try expect(
            store.contains("pollutionAfterBudgetReached"),
            "Budget threshold must create the MVP's initial murkiness."
        )
        try expect(
            store.contains("pollutionAfterBypass"),
            "Bypass must increment murkiness through TimeTankRules."
        )
        try expect(
            monitor.contains("eventDidReachThreshold") &&
            monitor.contains("store.markBudgetExceeded()") &&
            monitor.contains("ScreenTimeShielding.applyShield"),
            "Monitor threshold callback must mark budget spent and apply the shield."
        )
        try expect(
            shieldAction.contains("store.markShieldAction()") &&
            shieldAction.contains("store.incrementPollution()") &&
            shieldAction.contains("startBypassCooldown"),
            "Shield action must log action, increment murkiness, and start bypass cooldown."
        )
        try expect(
            settings.contains("Last shield action") &&
            settings.contains("Threshold reached") &&
            settings.contains("Active schedules"),
            "Settings diagnostics must expose threshold, schedule, and shield-action evidence."
        )
        try expect(
            scheduler.contains("startMonitoring(") &&
            scheduler.contains("TimeTankConstants.dailyActivityName") &&
            scheduler.contains("events: [TimeTankConstants.budgetEventName: event]"),
            "Scheduler must use one daily activity and one budget threshold event."
        )
        try expect(
            budget.contains("[15, 30, 60, 120]") &&
            budget.contains("How long is fair for these apps?"),
            "Budget setup must prioritize simple selected-app budget presets."
        )

        print("MVP acceptance verification passed.")
    }
}
