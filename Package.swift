// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TimeTankMVPChecks",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TimeTankCoreRules", targets: ["TimeTankCoreRules"]),
        .executable(name: "TimeTankMVPVerifier", targets: ["TimeTankMVPVerifier"])
    ],
    targets: [
        .target(
            name: "TimeTankCoreRules",
            path: "TimeTank/Shared",
            exclude: [
                "ScreenTimeScheduler.swift",
                "ScreenTimeShielding.swift",
                "TimeTankConstants.swift",
                "TimeTankStore.swift"
            ],
            sources: ["TimeTankRules.swift"]
        ),
        .executableTarget(
            name: "TimeTankMVPVerifier",
            dependencies: ["TimeTankCoreRules"],
            path: "Scripts",
            sources: ["verify_mvp_rules.swift"]
        )
    ]
)
