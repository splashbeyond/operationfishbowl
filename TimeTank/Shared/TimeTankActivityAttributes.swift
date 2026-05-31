import ActivityKit
import Foundation

struct TimeTankActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var pollutionLevel: Double
        var bypassExpiresAt: Date?
        var isShieldActive: Bool
    }
}
