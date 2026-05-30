import Foundation

enum TimeTankMurkinessState: String {
    case clean
    case warning
    case spent
    case murky
}

enum TimeTankRules {
    static let warningUsageProgress = 0.8
    static let spentUsageProgress = 1.0
    static let initialSpentPollution = 0.2
    static let bypassPollutionIncrement = 0.2
    static let maximumPollution = 1.0

    static func clampedPollution(_ value: Double) -> Double {
        min(maximumPollution, max(0, value))
    }

    static func pollutionAfterBudgetReached(currentPollution: Double) -> Double {
        max(clampedPollution(currentPollution), initialSpentPollution)
    }

    static func pollutionAfterBypass(currentPollution: Double) -> Double {
        clampedPollution(currentPollution + bypassPollutionIncrement)
    }

    static func usageProgress(usedMinutes: Int, budgetMinutes: Int) -> Double {
        guard budgetMinutes > 0 else { return spentUsageProgress }
        return max(0, Double(usedMinutes) / Double(budgetMinutes))
    }

    static func murkinessState(
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

    static func statusMessage(for state: TimeTankMurkinessState, budgetMinutes: Int) -> String {
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
