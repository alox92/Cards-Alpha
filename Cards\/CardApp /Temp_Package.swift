// swift-tools-version: 6.0
// Version temporaire avec moins de fonctionnalités expérimentales

import PackageDescription

let package = Package(
    name: "CardApp",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Core",
            type: .dynamic,
            targets: ["Core"]),
        .executable(
            name: "App",
            targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Core",
            exclude: [
                "UI/README.md",
                ".DS_Store",
                "Services/Stats/StatisticsView.swift.backup",
                "Models/Data/Core.xcdatamodeld"
            ],
            resources: [
                .copy("Resources"),
                .process("Persistence/Cards.xcdatamodeld")
            ]
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core"],
            path: "App"
        )
    ]
)
