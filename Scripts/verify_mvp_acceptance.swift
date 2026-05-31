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
        let report = try read("TimeTankReport/TimeTankReportExtension.swift")
        let shieldAction = try read("TimeTankShieldAction/TimeTankShieldActionExtension.swift")
        let settings = try read("TimeTank/App/SettingsView.swift")
        let scheduler = try read("TimeTank/Shared/ScreenTimeScheduler.swift")
        let budget = try read("TimeTank/App/BudgetSetupView.swift")
        let project = try read("TimeTank.xcodeproj/project.pbxproj")
        let appEntitlements = try read("TimeTank/TimeTank.entitlements")
        let monitorEntitlements = try read("TimeTankMonitor/TimeTankMonitor.entitlements")
        let actionEntitlements = try read("TimeTankShieldAction/TimeTankShieldAction.entitlements")
        let configEntitlements = try read("TimeTankShieldConfiguration/TimeTankShieldConfiguration.entitlements")
        let reportEntitlements = try read("TimeTankReport/TimeTankReport.entitlements")
        let monitorInfo = try read("TimeTankMonitor/Info.plist")
        let actionInfo = try read("TimeTankShieldAction/Info.plist")
        let configInfo = try read("TimeTankShieldConfiguration/Info.plist")
        let reportInfo = try read("TimeTankReport/Info.plist")

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
            !report.contains("overflowSeconds") &&
            !report.contains("continuousPollution") &&
            !report.contains("sharedDefaults.set"),
            "DeviceActivityReport must not mutate enforcement or murkiness state."
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
            shieldAction.contains("startBypassCooldown") &&
            shieldAction.contains("maximumBypassMinutes: store.bypassLimitMinutes") &&
            !shieldAction.contains("UNNotificationRequest"),
            "Shield action must log action, increment murkiness, start bypass cooldown, and not schedule timer-only notifications."
        )
        try expect(
            monitor.contains("bypassUsageEventName") &&
            monitor.contains("markBudgetedAppUsedDuringBypass") &&
            monitor.contains("UNNotificationRequest"),
            "Bypass notification must be armed only after selected-app usage evidence during bypass."
        )
        try expect(
            settings.contains("Last shield action") &&
            settings.contains("Threshold reached") &&
            settings.contains("Active schedules") &&
            settings.contains("BYPASS CAP") &&
            settings.contains("[15, 30, 60, 120, 240, 480, 720]"),
            "Settings diagnostics must expose threshold, schedule, shield-action evidence, and the user bypass cap."
        )
        try expect(
            stats.contains("weekLog") &&
            stats.contains("MonthFinnLogView") &&
            stats.contains("FinnDayCircle") &&
            stats.contains("TimeTankStore.dayKey"),
            "Stats must show Finn's week log and expand to the month log from saved daily snapshots."
        )
        try expect(
            store.contains("TimeTankDailySnapshot") &&
            store.contains("dailySnapshots") &&
            store.contains("recordDailySnapshot") &&
            store.contains("awardCleanDayIfNeeded"),
            "Store must persist end-of-day Finn snapshots for the Stats log."
        )
        try expect(
            scheduler.contains("startMonitoring(") &&
            scheduler.contains("TimeTankConstants.dailyActivityName") &&
            scheduler.contains("events: [TimeTankConstants.budgetEventName: event]"),
            "Scheduler must use one daily activity and one budget threshold event."
        )
        try expect(
            scheduler.contains("threshold: DateComponents(second: TimeTankConstants.bypassUsageEvidenceSeconds)") &&
            scheduler.contains("events: [TimeTankConstants.bypassUsageEventName: event]"),
            "Bypass DeviceActivity event must detect selected-app usage evidence, not drive timer-only notifications."
        )
        try expect(
            budget.contains("[15, 30, 60, 120]") &&
            budget.contains("How long is fair for these apps?"),
            "Budget setup must prioritize simple selected-app budget presets."
        )
        try expect(
            project.contains("TimeTankReport.appex in Embed App Extensions") &&
            project.contains("TimeTankMonitor.appex in Embed App Extensions") &&
            project.contains("TimeTankShieldAction.appex in Embed App Extensions") &&
            project.contains("TimeTankShieldConfiguration.appex in Embed App Extensions"),
            "All Screen Time extensions must be embedded in the app target."
        )
        try expect(
            project.contains("TimeTankRules.swift") &&
            project.contains("TimeTankRules.swift in Sources"),
            "TimeTankRules must be part of Xcode source membership."
        )
        for (name, entitlements) in [
            ("app", appEntitlements),
            ("monitor", monitorEntitlements),
            ("shield action", actionEntitlements),
            ("shield configuration", configEntitlements),
            ("report", reportEntitlements)
        ] {
            try expect(
                entitlements.contains("com.apple.developer.family-controls") &&
                entitlements.contains("group.com.piperstudio.timetank"),
                "\(name) entitlements must include Family Controls and the shared App Group."
            )
        }
        for (name, info) in [
            ("monitor", monitorInfo),
            ("shield action", actionInfo),
            ("shield configuration", configInfo),
            ("report", reportInfo)
        ] {
            try expect(
                info.contains("CFBundleExecutable") &&
                info.contains("NSExtensionPointIdentifier"),
                "\(name) extension Info.plist must include executable and extension point metadata."
            )
        }

        print("MVP acceptance verification passed.")
    }
}
