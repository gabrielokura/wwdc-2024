// swift-tools-version: 5.8

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Aliens Network",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Aliens Network",
            targets: ["AppModule"],
            bundleIdentifier: "com.gabrielokura.dev.SmartAliens",
            teamIdentifier: "2FT5KGG425",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            appCategory: .games
        )
    ],
    dependencies: [
        .package(url: "https://github.com/troydeville/NEAT-swift", .branch("master"))
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Neat", package: "neat-swift")
            ],
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
