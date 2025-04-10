// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        // Ajouter un produit pour le débogage
        .executable(
            name: "CardAppDebug",
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
                "Models/Data/Core.xcdatamodeld" // Exclure ce fichier car il n'est pas traité correctement
            ],
            resources: [
                .copy("Resources"),
                .process("Persistence/Cards.xcdatamodeld")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                // Ajouter un flag spécifique pour le débogage
                .define("COMPILE_CHECK_MODE", .when(configuration: .debug)),
                // Simplifions les réglages qui pourraient causer des problèmes
                .unsafeFlags(["-Xfrontend", "-enable-bare-slash-regex"]), // Remplace BareSlashRegexLiterals
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                // Utilisation plus compatible de StrictConcurrency
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=none"])
            ]
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core"],
            path: "App",
            exclude: [
                "Resources"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                // Ajouter un flag pour le mode débogage
                .define("COMPILE_CHECK_MODE", .when(configuration: .debug)),
                // Utiliser les mêmes réglages que Core pour la cohérence
                .unsafeFlags(["-Xfrontend", "-enable-bare-slash-regex"]),
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=none"])
            ]
        )
    ]
)
