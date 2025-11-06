// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleFMTest",
    platforms: [
        .macOS("26.0")
    ],
    targets: [
        .executableTarget(
            name: "AppleFMTest"
        ),
    ]
)
