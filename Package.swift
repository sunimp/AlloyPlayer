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
        .library(name: "AlloyUIKitControls", targets: ["AlloyUIKitControls"]),
        .library(name: "AlloySwiftUIControls", targets: ["AlloySwiftUIControls"]),
    ],
    targets: [
        .target(name: "AlloyCore"),
        .target(
            name: "AlloyAVPlayer",
            dependencies: ["AlloyCore"]
        ),
        .target(
            name: "AlloyUIKitControls",
            dependencies: ["AlloyCore"]
        ),
        .target(
            name: "AlloySwiftUIControls",
            dependencies: ["AlloyCore", "AlloyAVPlayer"]
        ),
        .target(
            name: "AlloyPlayer",
            dependencies: ["AlloyCore", "AlloyAVPlayer", "AlloyUIKitControls", "AlloySwiftUIControls"]
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
            name: "AlloyUIKitControlsTests",
            dependencies: ["AlloyUIKitControls"]
        ),
        .testTarget(
            name: "AlloySwiftUIControlsTests",
            dependencies: ["AlloySwiftUIControls"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
