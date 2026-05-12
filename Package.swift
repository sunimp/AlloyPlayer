// swift-tools-version: 5.10

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
        .library(name: "AlloyHTTPMediaCacheSupport", targets: ["AlloyHTTPMediaCacheSupport"]),
        .library(name: "AlloyUIKitControls", targets: ["AlloyUIKitControls"]),
        .library(name: "AlloySwiftUIControls", targets: ["AlloySwiftUIControls"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sunimp/HTTPMediaCache.git", from: "1.0.1"),
    ],
    targets: [
        .target(name: "AlloyCore"),
        .target(
            name: "AlloyAVPlayer",
            dependencies: ["AlloyCore"]
        ),
        .target(
            name: "AlloyHTTPMediaCacheSupport",
            dependencies: [
                "AlloyCore",
                .product(name: "HTTPMediaCache", package: "HTTPMediaCache"),
            ]
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
            name: "AlloyHTTPMediaCacheSupportTests",
            dependencies: [
                "AlloyHTTPMediaCacheSupport",
                .product(name: "HTTPMediaCache", package: "HTTPMediaCache"),
            ]
        ),
        .testTarget(
            name: "AlloyUIKitControlsTests",
            dependencies: ["AlloyUIKitControls"]
        ),
        .testTarget(
            name: "AlloySwiftUIControlsTests",
            dependencies: ["AlloySwiftUIControls"]
        ),
    ]
)
