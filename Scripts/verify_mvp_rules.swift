import Foundation
import TimeTankCoreRules

struct RuleFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw RuleFailure(description: message)
    }
}

func nearlyEqual(_ left: Double, _ right: Double) -> Bool {
    abs(left - right) < 0.000001
}

@main
struct VerifyMVPRules {
    static func main() throws {
        try expect(TimeTankRules.clampedPollution(-0.25) == 0, "Pollution clamps below zero.")
        try expect(TimeTankRules.clampedPollution(1.25) == 1, "Pollution clamps above one.")

        try expect(
            nearlyEqual(TimeTankRules.pollutionAfterBudgetReached(currentPollution: 0), 0.2),
            "Budget threshold creates initial 20% murkiness."
        )
        try expect(
            nearlyEqual(TimeTankRules.pollutionAfterBudgetReached(currentPollution: 0.6), 0.6),
            "Budget threshold does not reduce existing murkiness."
        )
        try expect(
            nearlyEqual(TimeTankRules.pollutionAfterBypass(currentPollution: 0.2), 0.4),
            "Bypass adds 20% murkiness."
        )
        try expect(
            nearlyEqual(TimeTankRules.pollutionAfterBypass(currentPollution: 0.9), 1.0),
            "Bypass caps murkiness at 100%."
        )

        try expect(
            nearlyEqual(TimeTankRules.usageProgress(usedMinutes: 12, budgetMinutes: 60), 0.2),
            "Usage progress is selected-app minutes divided by selected-app budget."
        )
        try expect(
            nearlyEqual(TimeTankRules.usageProgress(usedMinutes: 1, budgetMinutes: 0), 1.0),
            "Invalid zero budget is treated as spent."
        )

        try expect(
            TimeTankRules.murkinessState(usageProgress: 0.2, isBudgetExceeded: false, pollutionLevel: 0) == .clean,
            "0-79% usage is clean."
        )
        try expect(
            TimeTankRules.murkinessState(usageProgress: 0.8, isBudgetExceeded: false, pollutionLevel: 0) == .warning,
            "80-99% usage is warning."
        )
        try expect(
            TimeTankRules.murkinessState(usageProgress: 1.0, isBudgetExceeded: false, pollutionLevel: 0) == .spent,
            "100% usage is spent."
        )
        try expect(
            TimeTankRules.murkinessState(usageProgress: 0.2, isBudgetExceeded: true, pollutionLevel: 0) == .spent,
            "Budget-exceeded state is spent even without report usage."
        )
        try expect(
            TimeTankRules.murkinessState(usageProgress: 0.2, isBudgetExceeded: true, pollutionLevel: 0.2) == .murky,
            "Any pollution means the tank is murky."
        )

        print("MVP rules verification passed.")
    }
}
