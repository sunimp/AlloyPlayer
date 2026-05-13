// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AlloyPlayer",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "AlloyCore", targets: ["AlloyCore"]),
        .library(name: "AlloyAVPlayer", targets: ["AlloyAVPlayer"]),
        .library(name: "AlloyPlayerUIKit", targets: ["AlloyPlayerUIKit"]),
        .library(name: "AlloyPlayerSwiftUI", targets: ["AlloyPlayerSwiftUI"]),
        .library(name: "AlloyListPlayback", targets: ["AlloyListPlayback"]),
        .library(name: "AlloyPlayerHTTPMediaCacheSupport", targets: ["AlloyPlayerHTTPMediaCacheSupport"]),
        .library(name: "AlloyPlayer", targets: ["AlloyPlayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sunimp/HTTPMediaCache.git", from: "1.0.3"),
    ],
    targets: [
        .target(name: "AlloyCore"),
        .target(
            name: "AlloyAVPlayer",
            dependencies: ["AlloyCore"]
        ),
        .target(
            name: "AlloyPlayerUIKit",
            dependencies: ["AlloyCore", "AlloyAVPlayer"]
        ),
        .target(
            name: "AlloyPlayerSwiftUI",
            dependencies: ["AlloyCore", "AlloyAVPlayer", "AlloyPlayerUIKit"]
        ),
        .target(
            name: "AlloyListPlayback",
            dependencies: ["AlloyCore", "AlloyPlayerUIKit"]
        ),
        .target(
            name: "AlloyPlayerHTTPMediaCacheSupport",
            dependencies: [
                "AlloyCore",
                .product(name: "HTTPMediaCache", package: "HTTPMediaCache"),
            ]
        ),
        .target(
            name: "AlloyPlayer",
            dependencies: ["AlloyCore", "AlloyAVPlayer", "AlloyPlayerUIKit", "AlloyPlayerSwiftUI", "AlloyListPlayback"]
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
            name: "AlloyPlayerUIKitTests",
            dependencies: ["AlloyPlayerUIKit"]
        ),
        .testTarget(
            name: "AlloyPlayerSwiftUITests",
            dependencies: ["AlloyPlayerSwiftUI"]
        ),
        .testTarget(
            name: "AlloyPlayerTests",
            dependencies: ["AlloyPlayer"]
        ),
        .testTarget(
            name: "AlloyListPlaybackTests",
            dependencies: ["AlloyListPlayback"]
        ),
        .testTarget(
            name: "AlloyPlayerHTTPMediaCacheSupportTests",
            dependencies: [
                "AlloyPlayerHTTPMediaCacheSupport",
                .product(name: "HTTPMediaCache", package: "HTTPMediaCache"),
            ]
        ),
    ]
)
