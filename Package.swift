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
        .library(name: "AlloyUIKit", targets: ["AlloyUIKit"]),
        .library(name: "AlloySwiftUI", targets: ["AlloySwiftUI"]),
        .library(name: "AlloyListPlayback", targets: ["AlloyListPlayback"]),
        .library(name: "AlloyHTTPMediaCacheSupport", targets: ["AlloyHTTPMediaCacheSupport"]),
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
            name: "AlloyHTTPMediaCacheSupport",
            dependencies: [
                "AlloyCore",
                .product(name: "HTTPMediaCache", package: "HTTPMediaCache"),
            ]
        ),
        .target(
            name: "AlloyUIKit",
            dependencies: ["AlloyCore"]
        ),
        .target(
            name: "AlloySwiftUI",
            dependencies: ["AlloyCore", "AlloyUIKit"]
        ),
        .target(
            name: "AlloyListPlayback",
            dependencies: ["AlloyCore", "AlloyUIKit"]
        ),
        .target(
            name: "AlloyPlayer",
            dependencies: ["AlloyCore", "AlloyAVPlayer", "AlloyUIKit", "AlloySwiftUI", "AlloyListPlayback"]
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
            name: "AlloyUIKitTests",
            dependencies: ["AlloyUIKit"]
        ),
        .testTarget(
            name: "AlloySwiftUITests",
            dependencies: ["AlloySwiftUI"]
        ),
        .testTarget(
            name: "AlloyPlayerTests",
            dependencies: ["AlloyPlayer"]
        ),
        .testTarget(
            name: "AlloyListPlaybackTests",
            dependencies: ["AlloyListPlayback"]
        ),
    ]
)
