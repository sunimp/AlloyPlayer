// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AlloyPlayer",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "AlloyPlayer", targets: ["AlloyPlayer"]),
        .library(name: "AlloyCore", targets: ["AlloyCore"]),
        .library(name: "AlloyAVPlayer", targets: ["AlloyAVPlayer"]),
        .library(name: "AlloyControlView", targets: ["AlloyControlView"]),
    ],
    targets: [
        .target(name: "AlloyCore"),
        .target(
            name: "AlloyAVPlayer",
            dependencies: ["AlloyCore"]
        ),
        .target(
            name: "AlloyControlView",
            dependencies: ["AlloyCore"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "AlloyPlayer",
            dependencies: ["AlloyCore", "AlloyAVPlayer", "AlloyControlView"]
        ),
        .testTarget(
            name: "AlloyCoreTests",
            dependencies: ["AlloyCore"]
        ),
        .testTarget(
            name: "AlloyAVPlayerTests",
            dependencies: ["AlloyAVPlayer"]
        ),
        .testTarget(
            name: "AlloyControlViewTests",
            dependencies: ["AlloyControlView"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
