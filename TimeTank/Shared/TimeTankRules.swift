import Foundation

public enum TimeTankMurkinessState: String {
    case clean
    case warning
    case spent
    case murky
}

public enum TimeTankRules {
    public static let warningUsageProgress = 0.8
    public static let spentUsageProgress = 1.0
    public static let initialSpentPollution = 0.2
    public static let bypassPollutionIncrement = 0.2
    public static let maximumPollution = 1.0

    public static func clampedPollution(_ value: Double) -> Double {
        min(maximumPollution, max(0, value))
    }

    public static func pollutionAfterBudgetReached(currentPollution: Double) -> Double {
        max(clampedPollution(currentPollution), initialSpentPollution)
    }

    public static func pollutionAfterBypass(currentPollution: Double) -> Double {
        clampedPollution(currentPollution + bypassPollutionIncrement)
    }

    public static func continuousPollution(overflowSeconds: TimeInterval, budgetMinutes: Int, bypassCount: Int) -> Double {
        guard budgetMinutes > 0 else { return maximumPollution }
        let budgetSeconds = Double(budgetMinutes) * 60.0
        let basePollution = min(1.0, overflowSeconds / budgetSeconds)
        let bypassPenalty = Double(bypassCount) * bypassPollutionIncrement
        return clampedPollution(basePollution + bypassPenalty)
    }

    // Escalating bypass windows: longer grace period each time, but tank fills up.
    // 1-min budget = test mode, always 1-min windows.
    // Production: 15 → 30 → 45 → 60 min based on how many bypasses were actually used.
    public static func bypassWindowMinutes(bypassCount: Int, budgetMinutes: Int) -> Int {
        if budgetMinutes <= 1 { return 1 }
        switch bypassCount {
        case 0:  return 5   // 20% pollution — jarring reminder
        case 1:  return 10  // 40% pollution — pushing it
        case 2:  return 15  // 60% pollution — clearly checked out
        case 3:  return 30  // 80% pollution — nearly failed the day
        default: return 60  // 100% pollution — Finn is suffering, day is lost
        }
    }

    public static func usageProgress(usedMinutes: Int, budgetMinutes: Int) -> Double {
        guard budgetMinutes > 0 else { return spentUsageProgress }
        return max(0, Double(usedMinutes) / Double(budgetMinutes))
    }

    public static func murkinessState(
        usageProgress: Double?,
        isBudgetExceeded: Bool,
        pollutionLevel: Double
    ) -> TimeTankMurkinessState {
        if pollutionLevel > 0 {
            return .murky
        }

        if isBudgetExceeded || (usageProgress ?? 0) >= spentUsageProgress {
            return .spent
        }

        if (usageProgress ?? 0) >= warningUsageProgress {
            return .warning
        }

        return .clean
    }

    public static func statusMessage(for state: TimeTankMurkinessState, budgetMinutes: Int) -> String {
        switch state {
        case .clean:
            return "Your \(budgetMinutes)-minute distraction budget is still clean."
        case .warning:
            return "You are close to today's distraction budget."
        case .spent:
            return "Your distraction budget is spent. The shield is protecting the tank."
        case .murky:
            return "The water is murky because today's boundary was crossed."
        }
    }
}
