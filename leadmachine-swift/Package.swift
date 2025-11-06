// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LeadMachineCLI",
    platforms: [
        .macOS("13.0")
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "LeadMachineCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OpenAI", package: "OpenAI"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
    ]
)
