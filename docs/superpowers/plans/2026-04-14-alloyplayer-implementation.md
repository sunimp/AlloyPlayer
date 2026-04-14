# AlloyPlayer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pure Swift video player framework (AlloyPlayer) that provides 100% functional coverage of ZFPlayer, with modern Swift concurrency, Combine event streams, and modular SPM architecture.

**Architecture:** Protocol-driven plugin architecture with 4 SPM targets — AlloyCore (protocols, enums, core orchestrator, infrastructure), AlloyAVPlayer (AVPlayer engine), AlloyControlView (default UI), AlloyPlayer (umbrella re-export). The Player class orchestrates a PlaybackEngine and ControlOverlay through Combine subscriptions and delegate forwarding.

**Tech Stack:** Swift 6.3 (strict concurrency), iOS 15+, SPM, Combine, UIKit + Auto Layout, NWPathMonitor, os.Logger, AVFoundation

**Design Spec:** `docs/superpowers/specs/2026-04-14-alloyplayer-design.md`

---

## Phase 1: Project Infrastructure

### Task 1: Configure Package.swift with multi-target structure

**Files:**
- Modify: `Package.swift`
- Create: `Sources/AlloyCore/.gitkeep` (placeholder until first real file)
- Create: `Sources/AlloyAVPlayer/.gitkeep`
- Create: `Sources/AlloyControlView/.gitkeep`
- Create: `Tests/AlloyCoreTests/.gitkeep`
- Create: `Tests/AlloyAVPlayerTests/.gitkeep`
- Create: `Tests/AlloyControlViewTests/.gitkeep`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p Sources/AlloyCore Sources/AlloyAVPlayer Sources/AlloyControlView Sources/AlloyControlView/Resources
mkdir -p Tests/AlloyCoreTests Tests/AlloyAVPlayerTests Tests/AlloyControlViewTests
# Remove old single-target structure
rm -f Sources/AlloyPlayer/AlloyPlayer.swift
rm -f Tests/AlloyPlayerTests/AlloyPlayerTests.swift
rmdir Tests/AlloyPlayerTests 2>/dev/null || true
```

- [ ] **Step 2: Rewrite Package.swift**

```swift
// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AlloyPlayer",
    platforms: [
        .iOS(.v15),
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
```

- [ ] **Step 3: Create placeholder source files**

Each target needs at least one `.swift` file to compile.

`Sources/AlloyCore/AlloyCore.swift`:
```swift
//
//  AlloyCore.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

// AlloyCore — 协议、枚举、核心控制器、工具类
```

`Sources/AlloyAVPlayer/AlloyAVPlayer.swift`:
```swift
//
//  AlloyAVPlayer.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/4/14.
//

// AlloyAVPlayer — AVPlayer 引擎实现
```

`Sources/AlloyControlView/AlloyControlView.swift`:
```swift
//
//  AlloyControlView.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

// AlloyControlView — 默认控制层 UI
```

`Sources/AlloyPlayer/AlloyPlayer.swift`:
```swift
//
//  AlloyPlayer.swift
//  AlloyPlayer
//
//  Created by Sun on 2026/4/14.
//

@_exported import AlloyCore
@_exported import AlloyAVPlayer
@_exported import AlloyControlView
```

`Sources/AlloyControlView/Resources/.gitkeep`: empty file (SPM requires the directory to exist for `.process("Resources")`)

`Tests/AlloyCoreTests/AlloyCoreTests.swift`:
```swift
import Testing
@testable import AlloyCore

@Test func moduleImports() async throws {
    // 验证模块可正常导入
}
```

`Tests/AlloyAVPlayerTests/AlloyAVPlayerTests.swift`:
```swift
import Testing
@testable import AlloyAVPlayer

@Test func moduleImports() async throws {
    // 验证模块可正常导入
}
```

`Tests/AlloyControlViewTests/AlloyControlViewTests.swift`:
```swift
import Testing
@testable import AlloyControlView

@Test func moduleImports() async throws {
    // 验证模块可正常导入
}
```

- [ ] **Step 4: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

- [ ] **Step 5: Run tests**

Run: `swift test 2>&1 | tail -10`
Expected: All tests passed

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "配置 SPM 多 target 结构

- AlloyCore / AlloyAVPlayer / AlloyControlView / AlloyPlayer 四个 target
- 对应的三个 test target
- AlloyPlayer 作为 umbrella 模块 re-export 所有子模块"
```

---

## Phase 2: AlloyCore Foundation Types

### Task 2: Implement all enums and OptionSets

**Files:**
- Create: `Sources/AlloyCore/Enums.swift`
- Create: `Tests/AlloyCoreTests/EnumsTests.swift`

- [ ] **Step 1: Write tests for enums**

`Tests/AlloyCoreTests/EnumsTests.swift`:
```swift
//
//  EnumsTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Testing
@testable import AlloyCore

@Suite("Enums & OptionSet Tests")
struct EnumsTests {
    @Test func playbackStateRawValues() {
        #expect(PlaybackState.unknown.rawValue == 0)
        #expect(PlaybackState.playing.rawValue == 1)
        #expect(PlaybackState.paused.rawValue == 2)
        #expect(PlaybackState.failed.rawValue == 3)
        #expect(PlaybackState.stopped.rawValue == 4)
    }

    @Test func loadStateOptionSet() {
        let state: LoadState = [.prepare, .playable]
        #expect(state.contains(.prepare))
        #expect(state.contains(.playable))
        #expect(!state.contains(.stalled))
    }

    @Test func disableGestureTypesAll() {
        let all: DisableGestureTypes = .all
        #expect(all.contains(.singleTap))
        #expect(all.contains(.doubleTap))
        #expect(all.contains(.pan))
        #expect(all.contains(.pinch))
        #expect(all.contains(.longPress))
    }

    @Test func interfaceOrientationMaskComposites() {
        let landscape: InterfaceOrientationMask = .landscape
        #expect(landscape.contains(.landscapeLeft))
        #expect(landscape.contains(.landscapeRight))
        #expect(!landscape.contains(.portrait))

        let allButUpsideDown: InterfaceOrientationMask = .allButUpsideDown
        #expect(allButUpsideDown.contains(.portrait))
        #expect(allButUpsideDown.contains(.landscapeLeft))
        #expect(allButUpsideDown.contains(.landscapeRight))
        #expect(!allButUpsideDown.contains(.portraitUpsideDown))
    }

    @Test func reachabilityStatusRawValues() {
        #expect(ReachabilityStatus.unknown.rawValue == -1)
        #expect(ReachabilityStatus.notReachable.rawValue == 0)
        #expect(ReachabilityStatus.wifi.rawValue == 1)
        #expect(ReachabilityStatus.cellular5G.rawValue == 5)
    }

    @Test func scrollAnchorValues() {
        #expect(ScrollAnchor.none.rawValue == 0)
        #expect(ScrollAnchor.top.rawValue == 1)
        #expect(ScrollAnchor.centeredVertically.rawValue == 2)
        #expect(ScrollAnchor.bottom.rawValue == 3)
    }

    @Test func disablePanMovingDirectionAll() {
        let all: DisablePanMovingDirection = .all
        #expect(all.contains(.vertical))
        #expect(all.contains(.horizontal))
    }

    @Test func disablePortraitGestureTypesAll() {
        let all: DisablePortraitGestureTypes = .all
        #expect(all.contains(.tap))
        #expect(all.contains(.pan))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter EnumsTests 2>&1 | tail -5`
Expected: FAIL — types not defined

- [ ] **Step 3: Implement Enums.swift**

`Sources/AlloyCore/Enums.swift`:
```swift
//
//  Enums.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Foundation

// MARK: - 播放状态

/// 播放状态枚举
public enum PlaybackState: Int, Sendable {
    /// 未知
    case unknown
    /// 播放中
    case playing
    /// 已暂停
    case paused
    /// 播放失败
    case failed
    /// 已停止
    case stopped
}

// MARK: - 加载状态

/// 加载状态（支持组合）
public struct LoadState: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let unknown = LoadState([])
    public static let prepare = LoadState(rawValue: 1 << 0)
    public static let playable = LoadState(rawValue: 1 << 1)
    public static let playthroughOK = LoadState(rawValue: 1 << 2)
    public static let stalled = LoadState(rawValue: 1 << 3)
}

// MARK: - 缩放模式

/// 视频缩放模式
public enum ScalingMode: Int, Sendable {
    /// 无缩放
    case none
    /// 等比缩放适配（留黑边）
    case aspectFit
    /// 等比缩放填充（裁剪）
    case aspectFill
    /// 拉伸填充
    case fill
}

// MARK: - 全屏模式

/// 全屏模式
public enum FullScreenMode: Int, Sendable {
    /// 根据视频宽高比自动选择
    case automatic
    /// 强制横屏全屏
    case landscape
    /// 竖屏全屏（上下展开）
    case portrait
}

/// 竖屏全屏模式
public enum PortraitFullScreenMode: Int, Sendable {
    /// 拉伸填满
    case scaleToFill
    /// 等比适配
    case scaleAspectFit
}

// MARK: - 手势相关

/// 手势类型
public enum GestureType: Int, Sendable {
    case unknown
    case singleTap
    case doubleTap
    case pan
    case pinch
}

/// 禁用手势类型（支持组合）
public struct DisableGestureTypes: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let singleTap = DisableGestureTypes(rawValue: 1 << 0)
    public static let doubleTap = DisableGestureTypes(rawValue: 1 << 1)
    public static let pan = DisableGestureTypes(rawValue: 1 << 2)
    public static let pinch = DisableGestureTypes(rawValue: 1 << 3)
    public static let longPress = DisableGestureTypes(rawValue: 1 << 4)
    public static let all: DisableGestureTypes = [.singleTap, .doubleTap, .pan, .pinch, .longPress]
}

/// 滑动方向
public enum PanDirection: Int, Sendable {
    case unknown
    case vertical
    case horizontal
}

/// 滑动位置（屏幕左半/右半）
public enum PanLocation: Int, Sendable {
    case unknown
    case left
    case right
}

/// 滑动移动方向
public enum PanMovingDirection: Int, Sendable {
    case unknown
    case top
    case left
    case bottom
    case right
}

/// 禁用滑动方向（支持组合）
public struct DisablePanMovingDirection: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let vertical = DisablePanMovingDirection(rawValue: 1 << 0)
    public static let horizontal = DisablePanMovingDirection(rawValue: 1 << 1)
    public static let all: DisablePanMovingDirection = [.vertical, .horizontal]
}

/// 长按手势阶段
public enum LongPressPhase: Int, Sendable {
    case began
    case changed
    case ended
}

// MARK: - 屏幕方向

/// 支持的屏幕方向（支持组合）
public struct InterfaceOrientationMask: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let portrait = InterfaceOrientationMask(rawValue: 1 << 0)
    public static let landscapeLeft = InterfaceOrientationMask(rawValue: 1 << 1)
    public static let landscapeRight = InterfaceOrientationMask(rawValue: 1 << 2)
    public static let portraitUpsideDown = InterfaceOrientationMask(rawValue: 1 << 3)
    public static let landscape: InterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
    public static let all: InterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    public static let allButUpsideDown: InterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
}

/// 禁用竖屏全屏手势类型
public struct DisablePortraitGestureTypes: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let tap = DisablePortraitGestureTypes(rawValue: 1 << 0)
    public static let pan = DisablePortraitGestureTypes(rawValue: 1 << 1)
    public static let all: DisablePortraitGestureTypes = [.tap, .pan]
}

// MARK: - 滚动视图相关

/// 滚动方向
public enum ScrollDirection: Int, Sendable {
    case none
    case up
    case down
    case left
    case right
}

/// 滚动视图方向
public enum ScrollViewDirection: Int, Sendable {
    case vertical
    case horizontal
}

/// 播放器挂载模式
public enum AttachmentMode: Int, Sendable {
    /// 挂载到普通视图
    case view
    /// 挂载到列表 Cell
    case cell
}

/// 滚动锚点位置
public enum ScrollAnchor: Int, Sendable {
    case none
    case top
    case centeredVertically
    case bottom
    case left
    case centeredHorizontally
    case right
}

// MARK: - 网络状态

/// 网络可达性状态
public enum ReachabilityStatus: Int, Sendable {
    case unknown = -1
    case notReachable = 0
    case wifi = 1
    case cellular2G = 2
    case cellular3G = 3
    case cellular4G = 4
    case cellular5G = 5
}

// MARK: - 其他

/// 前后台状态
public enum BackgroundState: Int, Sendable {
    case foreground
    case background
}

/// 加载动画类型
public enum LoadingType: Int, Sendable {
    /// 保持显示
    case keep
    /// 淡出消失
    case fadeOut
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter EnumsTests 2>&1 | tail -10`
Expected: All tests passed

- [ ] **Step 5: Commit**

```bash
git add Sources/AlloyCore/Enums.swift Tests/AlloyCoreTests/EnumsTests.swift
git commit -m "实现所有枚举与 OptionSet 类型

- PlaybackState, LoadState, ScalingMode, FullScreenMode 等 20+ 类型
- 全部符合 Sendable 协议（Swift 6 并发安全）
- NS_OPTIONS 统一改用 OptionSet"
```

---

### Task 3: Implement Utilities

**Files:**
- Create: `Sources/AlloyCore/Utilities.swift`
- Create: `Tests/AlloyCoreTests/UtilitiesTests.swift`

- [ ] **Step 1: Write tests**

`Tests/AlloyCoreTests/UtilitiesTests.swift`:
```swift
//
//  UtilitiesTests.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Testing
@testable import AlloyCore

@Suite("Utilities Tests")
struct UtilitiesTests {
    @Test func timeFormatterShortFormat() {
        #expect(TimeFormatter.string(from: 0) == "00:00")
        #expect(TimeFormatter.string(from: 59) == "00:59")
        #expect(TimeFormatter.string(from: 60) == "01:00")
        #expect(TimeFormatter.string(from: 125) == "02:05")
        #expect(TimeFormatter.string(from: 3599) == "59:59")
    }

    @Test func timeFormatterLongFormat() {
        #expect(TimeFormatter.string(from: 3600) == "01:00:00")
        #expect(TimeFormatter.string(from: 3661) == "01:01:01")
        #expect(TimeFormatter.string(from: 7200) == "02:00:00")
    }

    @Test func timeFormatterNegative() {
        #expect(TimeFormatter.string(from: -1) == "00:00")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter UtilitiesTests 2>&1 | tail -5`
Expected: FAIL

- [ ] **Step 3: Implement Utilities.swift**

`Sources/AlloyCore/Utilities.swift`:
```swift
//
//  Utilities.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit
import os

// MARK: - 时间格式化

/// 将秒数格式化为时间字符串
public enum TimeFormatter: Sendable {
    /// 将秒数格式化为 "mm:ss" 或 "HH:mm:ss"
    public static func string(from seconds: Int) -> String {
        guard seconds > 0 else { return "00:00" }
        if seconds < 3600 {
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        } else {
            return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
    }
}

// MARK: - 图片生成

/// 纯色图片生成工具
public enum ImageGenerator: Sendable {
    /// 生成指定颜色和尺寸的纯色图片
    @MainActor
    public static func image(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - 日志

/// AlloyPlayer 统一日志
public let alloyLogger = Logger(subsystem: "com.alloyplayer", category: "AlloyPlayer")
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter UtilitiesTests 2>&1 | tail -10`
Expected: All tests passed

- [ ] **Step 5: Commit**

```bash
git add Sources/AlloyCore/Utilities.swift Tests/AlloyCoreTests/UtilitiesTests.swift
git commit -m "实现工具类

- TimeFormatter: 秒数格式化为 mm:ss / HH:mm:ss
- ImageGenerator: 纯色图片生成
- alloyLogger: 基于 os.Logger 的统一日志"
```

---

### Task 4: Implement RenderView

**Files:**
- Create: `Sources/AlloyCore/RenderView.swift`

- [ ] **Step 1: Implement RenderView**

`Sources/AlloyCore/RenderView.swift`:
```swift
//
//  RenderView.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 播放器渲染视图容器
///
/// 承载播放引擎的渲染层（如 AVPlayerLayer），并提供封面图视图。
/// 通过 `scalingMode` 控制视频缩放方式。
@MainActor
public class RenderView: UIView {

    // MARK: - 子视图

    /// 播放引擎的实际渲染视图（由引擎设置）
    public var playerView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let playerView {
                insertSubview(playerView, at: 0)
                playerView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    playerView.topAnchor.constraint(equalTo: topAnchor),
                    playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
                ])
            }
        }
    }

    /// 封面图视图
    public private(set) lazy var coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iv)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: topAnchor),
            iv.leadingAnchor.constraint(equalTo: leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        return iv
    }()

    // MARK: - 属性

    /// 视频缩放模式
    public var scalingMode: ScalingMode = .aspectFit

    /// 视频原始尺寸
    public var presentationSize: CGSize = .zero

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

- [ ] **Step 2: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
git add Sources/AlloyCore/RenderView.swift
git commit -m "实现 RenderView 渲染视图容器

- 承载引擎渲染视图，支持封面图
- Auto Layout 约束自动布局"
```

---

### Task 5: Define PlaybackEngine protocol

**Files:**
- Create: `Sources/AlloyCore/PlaybackEngine.swift`

- [ ] **Step 1: Implement PlaybackEngine protocol**

`Sources/AlloyCore/PlaybackEngine.swift`:
```swift
//
//  PlaybackEngine.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

/// 播放引擎协议
///
/// 定义视频播放引擎的标准接口。
/// 内置实现为 `AVPlayerManager`（AlloyAVPlayer 模块），
/// 也可自定义实现对接第三方播放器。
@MainActor
public protocol PlaybackEngine: AnyObject {

    // MARK: - 渲染

    /// 播放器渲染视图
    var renderView: RenderView { get }

    // MARK: - 状态

    /// 播放状态
    var playbackState: PlaybackState { get }

    /// 加载状态
    var loadState: LoadState { get }

    /// 是否正在播放
    var isPlaying: Bool { get }

    /// 是否已准备好播放
    var isPreparedToPlay: Bool { get }

    // MARK: - 控制属性

    /// 音量 (0.0 ~ 1.0)
    var volume: Float { get set }

    /// 是否静音
    var isMuted: Bool { get set }

    /// 播放速率 (0.5 ~ 2.0)
    var rate: Float { get set }

    /// 视频缩放模式
    var scalingMode: ScalingMode { get set }

    /// 是否自动播放
    var shouldAutoPlay: Bool { get set }

    // MARK: - 时间

    /// 当前播放时间（秒）
    var currentTime: TimeInterval { get }

    /// 总时长（秒）
    var totalTime: TimeInterval { get }

    /// 已缓冲时长（秒）
    var bufferTime: TimeInterval { get }

    /// 跳转目标时间（秒）
    var seekTime: TimeInterval { get set }

    // MARK: - 资源

    /// 视频资源 URL
    var assetURL: URL? { get set }

    /// 视频原始尺寸
    var presentationSize: CGSize { get }

    // MARK: - Combine 事件流

    /// 播放状态变化
    var statePublisher: AnyPublisher<PlaybackState, Never> { get }

    /// 加载状态变化
    var loadStatePublisher: AnyPublisher<LoadState, Never> { get }

    /// 播放时间变化 (current, total)
    var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> { get }

    /// 缓冲时间变化
    var bufferTimePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// 准备播放
    var prepareToPlayPublisher: AnyPublisher<URL, Never> { get }

    /// 准备就绪
    var readyToPlayPublisher: AnyPublisher<URL, Never> { get }

    /// 播放失败
    var playFailedPublisher: AnyPublisher<any Error, Never> { get }

    /// 播放完成
    var didPlayToEndPublisher: AnyPublisher<Void, Never> { get }

    /// 视频尺寸变化
    var presentationSizePublisher: AnyPublisher<CGSize, Never> { get }

    // MARK: - 控制方法

    /// 准备播放
    func prepareToPlay()

    /// 重新加载播放器
    func reloadPlayer()

    /// 开始播放
    func play()

    /// 暂停播放
    func pause()

    /// 重新播放（从头开始）
    func replay()

    /// 停止播放并释放资源
    func stop()

    /// 跳转到指定时间
    /// - Parameter time: 目标时间（秒）
    /// - Returns: 是否跳转成功
    func seek(to time: TimeInterval) async -> Bool

    // MARK: - 截图

    /// 获取当前帧截图（同步）
    func thumbnailImageAtCurrentTime() -> UIImage?

    /// 获取当前帧截图（异步）
    func thumbnailImageAtCurrentTime() async -> UIImage?
}

// MARK: - 默认实现

public extension PlaybackEngine {
    func thumbnailImageAtCurrentTime() -> UIImage? { nil }
    func thumbnailImageAtCurrentTime() async -> UIImage? { nil }
}
```

- [ ] **Step 2: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
git add Sources/AlloyCore/PlaybackEngine.swift
git commit -m "定义 PlaybackEngine 播放引擎协议

- 完整的属性、方法、Combine 事件流定义
- @MainActor 标记确保 Swift 6 并发安全
- 截图方法提供默认空实现"
```

---

### Task 6: Define ControlOverlay protocol

**Files:**
- Create: `Sources/AlloyCore/ControlOverlay.swift`

注意：ControlOverlay 引用了 Player、OrientationManager、GestureManager 等类型，需要使用前向声明或延迟实现。此处先定义协议，Player 等类在后续任务中实现。

- [ ] **Step 1: Implement ControlOverlay protocol**

`Sources/AlloyCore/ControlOverlay.swift`:
```swift
//
//  ControlOverlay.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 播放器控制层协议
///
/// 定义控制层 UI 与播放器之间的通信接口。
/// 所有方法均有默认空实现，使用者只需实现关心的回调。
/// 内置实现为 `DefaultControlOverlay`（AlloyControlView 模块）。
@MainActor
public protocol ControlOverlay: UIView {

    /// 关联的播放控制器
    var player: Player? { get set }

    // MARK: - 播放状态

    /// 准备播放
    func player(_ player: Player, prepareToPlay assetURL: URL)

    /// 播放状态变化
    func player(_ player: Player, didChangePlaybackState state: PlaybackState)

    /// 加载状态变化
    func player(_ player: Player, didChangeLoadState state: LoadState)

    // MARK: - 进度

    /// 播放时间更新
    func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval)

    /// 缓冲时间更新
    func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval)

    /// 拖动进度时调用
    func player(_ player: Player, draggingTime: TimeInterval, totalTime: TimeInterval)

    /// 播放完成
    func playerDidPlayToEnd(_ player: Player)

    /// 播放失败
    func player(_ player: Player, didFailWithError error: any Error)

    // MARK: - 锁屏

    /// 锁屏状态变化
    func player(_ player: Player, didChangeLockState isLocked: Bool)

    // MARK: - 旋转

    /// 即将旋转
    func player(_ player: Player, willChangeOrientation observer: OrientationManager)

    /// 旋转完成
    func player(_ player: Player, didChangeOrientation observer: OrientationManager)

    // MARK: - 网络

    /// 网络状态变化
    func player(_ player: Player, didChangeReachability status: ReachabilityStatus)

    // MARK: - 视频尺寸

    /// 视频尺寸变化
    func player(_ player: Player, didChangePresentationSize size: CGSize)

    // MARK: - 手势

    /// 手势触发条件判断
    func gestureTriggerCondition(
        _ gesture: GestureManager,
        type: GestureType,
        recognizer: UIGestureRecognizer,
        touch: UITouch
    ) -> Bool

    /// 单击
    func gestureSingleTapped(_ gesture: GestureManager)

    /// 双击
    func gestureDoubleTapped(_ gesture: GestureManager)

    /// 滑动开始
    func gestureBeganPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)

    /// 滑动中
    func gestureChangedPan(
        _ gesture: GestureManager,
        direction: PanDirection,
        location: PanLocation,
        velocity: CGPoint
    )

    /// 滑动结束
    func gestureEndedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)

    /// 捏合缩放
    func gesturePinched(_ gesture: GestureManager, scale: Float)

    /// 长按
    func longPressed(_ gesture: GestureManager, state: LongPressPhase)

    // MARK: - 列表播放

    /// 播放器即将出现在滚动视图中
    func playerWillAppearInScrollView(_ player: Player)

    /// 播放器已出现在滚动视图中
    func playerDidAppearInScrollView(_ player: Player)

    /// 播放器即将从滚动视图中消失
    func playerWillDisappearInScrollView(_ player: Player)

    /// 播放器已从滚动视图中消失
    func playerDidDisappearInScrollView(_ player: Player)

    /// 播放器出现百分比
    func player(_ player: Player, appearingPercent: CGFloat)

    /// 播放器消失百分比
    func player(_ player: Player, disappearingPercent: CGFloat)

    /// 小窗显示状态变化
    func player(_ player: Player, floatViewShow isShow: Bool)
}

// MARK: - 默认空实现

public extension ControlOverlay {
    func player(_ player: Player, prepareToPlay assetURL: URL) {}
    func player(_ player: Player, didChangePlaybackState state: PlaybackState) {}
    func player(_ player: Player, didChangeLoadState state: LoadState) {}
    func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {}
    func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval) {}
    func player(_ player: Player, draggingTime: TimeInterval, totalTime: TimeInterval) {}
    func playerDidPlayToEnd(_ player: Player) {}
    func player(_ player: Player, didFailWithError error: any Error) {}
    func player(_ player: Player, didChangeLockState isLocked: Bool) {}
    func player(_ player: Player, willChangeOrientation observer: OrientationManager) {}
    func player(_ player: Player, didChangeOrientation observer: OrientationManager) {}
    func player(_ player: Player, didChangeReachability status: ReachabilityStatus) {}
    func player(_ player: Player, didChangePresentationSize size: CGSize) {}
    func gestureTriggerCondition(_ gesture: GestureManager, type: GestureType, recognizer: UIGestureRecognizer, touch: UITouch) -> Bool { true }
    func gestureSingleTapped(_ gesture: GestureManager) {}
    func gestureDoubleTapped(_ gesture: GestureManager) {}
    func gestureBeganPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation) {}
    func gestureChangedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation, velocity: CGPoint) {}
    func gestureEndedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation) {}
    func gesturePinched(_ gesture: GestureManager, scale: Float) {}
    func longPressed(_ gesture: GestureManager, state: LongPressPhase) {}
    func playerWillAppearInScrollView(_ player: Player) {}
    func playerDidAppearInScrollView(_ player: Player) {}
    func playerWillDisappearInScrollView(_ player: Player) {}
    func playerDidDisappearInScrollView(_ player: Player) {}
    func player(_ player: Player, appearingPercent: CGFloat) {}
    func player(_ player: Player, disappearingPercent: CGFloat) {}
    func player(_ player: Player, floatViewShow isShow: Bool) {}
}
```

注意：此文件引用了 `Player`、`OrientationManager`、`GestureManager`，这些类尚未创建。编译会失败，将在后续 Task 创建这些类后一起通过编译。此处先提交协议定义。

- [ ] **Step 2: Commit (编译将在依赖类型创建后通过)**

```bash
git add Sources/AlloyCore/ControlOverlay.swift
git commit -m "定义 ControlOverlay 控制层协议

- 完整的播放状态、进度、手势、旋转、列表播放回调
- 所有方法提供默认空实现
- 引用 Player/OrientationManager/GestureManager（后续 Task 实现）"
```

---

## Phase 3: AlloyCore Infrastructure

### Task 7: Implement KVOManager

**Files:**
- Create: `Sources/AlloyCore/KVOManager.swift`

- [ ] **Step 1: Implement KVOManager**

`Sources/AlloyCore/KVOManager.swift`:
```swift
//
//  KVOManager.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Foundation

/// 安全的 KVO 管理器
///
/// 基于 Swift 强类型 KeyPath API，自动在 deinit 时移除所有观察。
@MainActor
public final class KVOManager {

    private var observations: [NSKeyValueObservation] = []

    public init() {}

    /// 添加 KVO 观察
    /// - Parameters:
    ///   - object: 被观察对象
    ///   - keyPath: 观察的 KeyPath
    ///   - options: 观察选项
    ///   - handler: 变化回调
    public func observe<Object: NSObject, Value>(
        _ object: Object,
        keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [.new],
        handler: @escaping (Object, NSKeyValueObservedChange<Value>) -> Void
    ) {
        let observation = object.observe(keyPath, options: options, changeHandler: handler)
        observations.append(observation)
    }

    /// 移除所有观察
    public func invalidate() {
        observations.forEach { $0.invalidate() }
        observations.removeAll()
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/KVOManager.swift
git commit -m "实现 KVOManager 安全 KVO 管理器

- 基于 Swift KeyPath API，类型安全
- 自动在 deinit 时移除所有观察"
```

---

### Task 8: Implement SystemEventObserver

**Files:**
- Create: `Sources/AlloyCore/SystemEventObserver.swift`

- [ ] **Step 1: Implement SystemEventObserver**

`Sources/AlloyCore/SystemEventObserver.swift`:
```swift
//
//  SystemEventObserver.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import AVFoundation
import Combine
import UIKit

/// 系统事件观察者
///
/// 监听应用前后台切换、音频路由变化、音量变化、音频中断等系统事件。
@MainActor
public final class SystemEventObserver {

    // MARK: - 状态

    /// 当前前后台状态
    public private(set) var backgroundState: BackgroundState = .foreground

    // MARK: - 音频路由变化原因

    /// 音频路由变化原因
    public enum AudioRouteChangeReason: Sendable {
        /// 新设备可用（如耳机插入）
        case newDeviceAvailable
        /// 旧设备不可用（如耳机拔出）
        case oldDeviceUnavailable
        /// 音频类别变化
        case categoryChanged
    }

    // MARK: - Combine Subjects

    private let _willResignActive = PassthroughSubject<Void, Never>()
    private let _didBecomeActive = PassthroughSubject<Void, Never>()
    private let _audioRouteChange = PassthroughSubject<AudioRouteChangeReason, Never>()
    private let _volumeChanged = PassthroughSubject<Float, Never>()
    private let _audioInterruption = PassthroughSubject<AVAudioSession.InterruptionType, Never>()

    // MARK: - Combine 事件流

    /// 应用即将进入非活跃状态
    public var willResignActivePublisher: AnyPublisher<Void, Never> { _willResignActive.eraseToAnyPublisher() }
    /// 应用已进入活跃状态
    public var didBecomeActivePublisher: AnyPublisher<Void, Never> { _didBecomeActive.eraseToAnyPublisher() }
    /// 音频路由变化
    public var audioRouteChangePublisher: AnyPublisher<AudioRouteChangeReason, Never> { _audioRouteChange.eraseToAnyPublisher() }
    /// 系统音量变化
    public var volumeChangedPublisher: AnyPublisher<Float, Never> { _volumeChanged.eraseToAnyPublisher() }
    /// 音频中断
    public var audioInterruptionPublisher: AnyPublisher<AVAudioSession.InterruptionType, Never> { _audioInterruption.eraseToAnyPublisher() }

    // MARK: - 内部状态

    private var isObserving = false

    // MARK: - 初始化

    public init() {}

    // MARK: - 方法

    /// 开始监听系统事件
    public func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        let nc = NotificationCenter.default

        nc.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(handleVolumeChange(_:)),
            name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
    }

    /// 停止监听系统事件
    public func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 通知处理

    @objc private func handleWillResignActive() {
        backgroundState = .background
        _willResignActive.send()
    }

    @objc private func handleDidBecomeActive() {
        backgroundState = .foreground
        _didBecomeActive.send()
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        switch reason {
        case .newDeviceAvailable:
            _audioRouteChange.send(.newDeviceAvailable)
        case .oldDeviceUnavailable:
            _audioRouteChange.send(.oldDeviceUnavailable)
        case .categoryChange:
            _audioRouteChange.send(.categoryChanged)
        default:
            break
        }
    }

    @objc private func handleVolumeChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let volume = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? Float
        else { return }
        _volumeChanged.send(volume)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        _audioInterruption.send(type)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/SystemEventObserver.swift
git commit -m "实现 SystemEventObserver 系统事件观察者

- 监听应用前后台、音频路由、音量、音频中断
- 通过 Combine Publisher 暴露事件流"
```

---

### Task 9: Implement ReachabilityMonitor

**Files:**
- Create: `Sources/AlloyCore/ReachabilityMonitor.swift`

- [ ] **Step 1: Implement ReachabilityMonitor**

`Sources/AlloyCore/ReachabilityMonitor.swift`:
```swift
//
//  ReachabilityMonitor.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import CoreTelephony
import Network

/// 网络可达性监控
///
/// 基于 NWPathMonitor 实现，监控网络状态变化。
/// 支持区分 WiFi / 蜂窝网络（2G/3G/4G/5G）。
@MainActor
public final class ReachabilityMonitor {

    // MARK: - 单例

    public static let shared = ReachabilityMonitor()

    // MARK: - 状态

    /// 当前网络状态
    public private(set) var currentStatus: ReachabilityStatus = .unknown

    /// 是否可达
    public var isReachable: Bool {
        currentStatus != .notReachable && currentStatus != .unknown
    }

    /// 是否通过 WiFi 可达
    public var isReachableViaWiFi: Bool {
        currentStatus == .wifi
    }

    /// 是否通过蜂窝网络可达
    public var isReachableViaCellular: Bool {
        switch currentStatus {
        case .cellular2G, .cellular3G, .cellular4G, .cellular5G: true
        default: false
        }
    }

    // MARK: - Combine

    private let _status = CurrentValueSubject<ReachabilityStatus, Never>(.unknown)

    /// 网络状态变化事件流
    public var statusPublisher: AnyPublisher<ReachabilityStatus, Never> {
        _status.eraseToAnyPublisher()
    }

    // MARK: - 内部

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.alloyplayer.reachability")
    private let telephonyInfo = CTTelephonyNetworkInfo()
    private var isMonitoring = false

    // MARK: - 初始化

    private init() {}

    // MARK: - 方法

    /// 开始监控网络状态
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }

    /// 停止监控网络状态
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
    }

    // MARK: - 内部方法

    private func handlePathUpdate(_ path: NWPath) {
        let status: ReachabilityStatus
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                status = .wifi
            } else if path.usesInterfaceType(.cellular) {
                status = detectCellularGeneration()
            } else {
                status = .wifi // 有线等其他连接方式
            }
        } else {
            status = .notReachable
        }

        guard status != currentStatus else { return }
        currentStatus = status
        _status.send(status)
    }

    private nonisolated func detectCellularGeneration() -> ReachabilityStatus {
        let radioTech: String?
        if let providers = telephonyInfo.serviceCurrentRadioAccessTechnology {
            radioTech = providers.values.first
        } else {
            radioTech = nil
        }

        guard let tech = radioTech else { return .cellular4G }

        switch tech {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return .cellular2G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .cellular3G
        case CTRadioAccessTechnologyLTE:
            return .cellular4G
        default:
            // NR / NRNonStandalone (5G)
            if tech.contains("NR") {
                return .cellular5G
            }
            return .cellular4G
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/ReachabilityMonitor.swift
git commit -m "实现 ReachabilityMonitor 网络监控

- 基于 NWPathMonitor 实现
- 区分 WiFi / 2G / 3G / 4G / 5G
- 通过 Combine CurrentValueSubject 暴露状态变化"
```

---

### Task 10: Implement FloatingView

**Files:**
- Create: `Sources/AlloyCore/FloatingView.swift`

- [ ] **Step 1: Implement FloatingView**

`Sources/AlloyCore/FloatingView.swift`:
```swift
//
//  FloatingView.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 小窗浮窗视图
///
/// 支持拖拽移动，自动限制在父视图安全区域内。
@MainActor
public final class FloatingView: UIView {

    // MARK: - 属性

    /// 父视图（弱引用）
    public weak var parentView: UIView? {
        didSet {
            guard let parentView else { return }
            if superview !== parentView {
                parentView.addSubview(self)
            }
        }
    }

    /// 安全边距
    public var safeInsets: UIEdgeInsets = .zero

    // MARK: - 内部

    private lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        return pan
    }()

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(panGesture)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 拖拽处理

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .changed, let parentView else { return }

        let translation = gesture.translation(in: parentView)
        var newCenter = CGPoint(
            x: center.x + translation.x,
            y: center.y + translation.y
        )

        // 限制在父视图安全区域内
        let halfWidth = bounds.width / 2
        let halfHeight = bounds.height / 2
        let minX = halfWidth + safeInsets.left
        let maxX = parentView.bounds.width - halfWidth - safeInsets.right
        let minY = halfHeight + safeInsets.top
        let maxY = parentView.bounds.height - halfHeight - safeInsets.bottom

        newCenter.x = max(minX, min(maxX, newCenter.x))
        newCenter.y = max(minY, min(maxY, newCenter.y))

        center = newCenter
        gesture.setTranslation(.zero, in: parentView)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/FloatingView.swift
git commit -m "实现 FloatingView 小窗浮窗

- 拖拽手势移动
- 自动限制在父视图安全区域内"
```

---

### Task 11: Implement GestureManager

**Files:**
- Create: `Sources/AlloyCore/GestureManager.swift`

- [ ] **Step 1: Implement GestureManager**

`Sources/AlloyCore/GestureManager.swift`:
```swift
//
//  GestureManager.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

/// 手势管理器
///
/// 管理播放器视图上的单击、双击、滑动、捏合、长按手势，
/// 通过 Combine Publisher 分发手势事件。
@MainActor
public final class GestureManager: NSObject {

    // MARK: - 手势识别器

    public private(set) lazy var singleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delaysTouchesBegan = true
        tap.delegate = self
        return tap
    }()

    public private(set) lazy var doubleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        tap.numberOfTapsRequired = 2
        tap.numberOfTouchesRequired = 1
        tap.delaysTouchesBegan = true
        tap.delegate = self
        return tap
    }()

    public private(set) lazy var pan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = true
        pan.delaysTouchesBegan = true
        pan.delegate = self
        return pan
    }()

    public private(set) lazy var pinch: UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delaysTouchesBegan = true
        pinch.delegate = self
        return pinch
    }()

    public private(set) lazy var longPress: UILongPressGestureRecognizer = {
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        lp.delaysTouchesBegan = true
        lp.delegate = self
        return lp
    }()

    // MARK: - 状态

    public private(set) var panDirection: PanDirection = .unknown
    public private(set) var panLocation: PanLocation = .unknown
    public private(set) var panMovingDirection: PanMovingDirection = .unknown

    // MARK: - 配置

    /// 禁用的手势类型
    public var disabledGestureTypes: DisableGestureTypes = []

    /// 禁用的滑动方向
    public var disabledPanMovingDirection: DisablePanMovingDirection = []

    /// 手势触发条件过滤
    public var triggerCondition: ((_ type: GestureType, _ recognizer: UIGestureRecognizer, _ touch: UITouch) -> Bool)?

    // MARK: - Combine Subjects

    private let _singleTap = PassthroughSubject<Void, Never>()
    private let _doubleTap = PassthroughSubject<Void, Never>()
    private let _panBegan = PassthroughSubject<(direction: PanDirection, location: PanLocation), Never>()
    private let _panChanged = PassthroughSubject<(direction: PanDirection, location: PanLocation, velocity: CGPoint), Never>()
    private let _panEnded = PassthroughSubject<(direction: PanDirection, location: PanLocation), Never>()
    private let _pinch = PassthroughSubject<Float, Never>()
    private let _longPress = PassthroughSubject<LongPressPhase, Never>()

    // MARK: - Combine 事件流

    public var singleTapPublisher: AnyPublisher<Void, Never> { _singleTap.eraseToAnyPublisher() }
    public var doubleTapPublisher: AnyPublisher<Void, Never> { _doubleTap.eraseToAnyPublisher() }
    public var panBeganPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation), Never> { _panBegan.eraseToAnyPublisher() }
    public var panChangedPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation, velocity: CGPoint), Never> { _panChanged.eraseToAnyPublisher() }
    public var panEndedPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation), Never> { _panEnded.eraseToAnyPublisher() }
    public var pinchPublisher: AnyPublisher<Float, Never> { _pinch.eraseToAnyPublisher() }
    public var longPressPublisher: AnyPublisher<LongPressPhase, Never> { _longPress.eraseToAnyPublisher() }

    // MARK: - 方法

    /// 将手势绑定到指定视图
    public func attach(to view: UIView) {
        view.isUserInteractionEnabled = true
        singleTap.require(toFail: doubleTap)
        pan.require(toFail: singleTap)
        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(longPress)
    }

    /// 从指定视图移除手势
    public func detach(from view: UIView) {
        view.removeGestureRecognizer(singleTap)
        view.removeGestureRecognizer(doubleTap)
        view.removeGestureRecognizer(pan)
        view.removeGestureRecognizer(pinch)
        view.removeGestureRecognizer(longPress)
    }

    // MARK: - 手势处理

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        _singleTap.send()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        _doubleTap.send()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let velocity = gesture.velocity(in: view)
        let location = gesture.location(in: view)

        switch gesture.state {
        case .began:
            // 判断滑动方向：比较水平与垂直速度
            panDirection = abs(velocity.x) > abs(velocity.y) ? .horizontal : .vertical
            // 判断滑动位置：屏幕左半或右半
            panLocation = location.x > view.bounds.width / 2 ? .right : .left
            _panBegan.send((direction: panDirection, location: panLocation))

        case .changed:
            // 更新移动方向
            switch panDirection {
            case .horizontal:
                panMovingDirection = velocity.x > 0 ? .right : .left
            case .vertical:
                panMovingDirection = velocity.y > 0 ? .bottom : .top
            default:
                break
            }
            _panChanged.send((direction: panDirection, location: panLocation, velocity: velocity))

        case .ended, .cancelled, .failed:
            _panEnded.send((direction: panDirection, location: panLocation))
            panDirection = .unknown
            panLocation = .unknown
            panMovingDirection = .unknown

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .ended {
            _pinch.send(Float(gesture.scale))
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            _longPress.send(.began)
        case .changed:
            _longPress.send(.changed)
        case .ended, .cancelled, .failed:
            _longPress.send(.ended)
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GestureManager: UIGestureRecognizerDelegate {

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        let type = gestureType(for: gestureRecognizer)

        // 检查禁用类型
        switch type {
        case .singleTap where disabledGestureTypes.contains(.singleTap): return false
        case .doubleTap where disabledGestureTypes.contains(.doubleTap): return false
        case .pan where disabledGestureTypes.contains(.pan): return false
        case .pinch where disabledGestureTypes.contains(.pinch): return false
        default: break
        }

        // 长按检查
        if gestureRecognizer === longPress, disabledGestureTypes.contains(.longPress) {
            return false
        }

        // 外部条件过滤
        if let condition = triggerCondition {
            return condition(type, gestureRecognizer, touch)
        }

        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === pan, let view = gestureRecognizer.view {
            let velocity = pan.velocity(in: view)
            if abs(velocity.x) > abs(velocity.y) {
                // 水平滑动
                if disabledPanMovingDirection.contains(.horizontal) { return false }
            } else {
                // 垂直滑动
                if disabledPanMovingDirection.contains(.vertical) { return false }
            }
        }
        return true
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // 捏合手势不与其他手势同时识别
        if gestureRecognizer is UIPinchGestureRecognizer || otherGestureRecognizer is UIPinchGestureRecognizer {
            return false
        }
        return true
    }

    // MARK: - 辅助方法

    private func gestureType(for recognizer: UIGestureRecognizer) -> GestureType {
        switch recognizer {
        case singleTap: return .singleTap
        case doubleTap: return .doubleTap
        case pan: return .pan
        case pinch: return .pinch
        default: return .unknown
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/GestureManager.swift
git commit -m "实现 GestureManager 手势管理器

- 单击、双击、滑动、捏合、长按五种手势
- Pan 方向检测（水平/垂直、左/右半屏）
- 禁用手势类型和方向的 OptionSet 配置
- Combine Publisher 事件分发"
```

---

## Phase 4: Orientation System

### Task 12: Implement LandscapeWindow and LandscapeController

**Files:**
- Create: `Sources/AlloyCore/LandscapeWindow.swift`
- Create: `Sources/AlloyCore/LandscapeController.swift`

- [ ] **Step 1: Implement LandscapeWindow and LandscapeController**

`Sources/AlloyCore/LandscapeWindow.swift`:
```swift
//
//  LandscapeWindow.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 横屏全屏专用窗口
final class LandscapeWindow: UIWindow {

    weak var rotationHandler: LandscapeRotationHandler?

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        backgroundColor = .black
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

`Sources/AlloyCore/LandscapeController.swift`:
```swift
//
//  LandscapeController.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 横屏全屏视图控制器
final class LandscapeController: UIViewController {

    // MARK: - 配置

    var isDisableAnimations = false
    var isStatusBarHidden = false
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var statusBarAnimation: UIStatusBarAnimation = .fade

    // MARK: - 重写

    override var prefersStatusBarHidden: Bool { isStatusBarHidden }
    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { statusBarAnimation }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    override var shouldAutorotate: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/LandscapeWindow.swift Sources/AlloyCore/LandscapeController.swift
git commit -m "实现 LandscapeWindow 和 LandscapeController

- LandscapeWindow: 横屏全屏专用窗口
- LandscapeController: 横屏 VC，支持状态栏配置"
```

---

### Task 13: Implement PortraitController and transition animations

**Files:**
- Create: `Sources/AlloyCore/PortraitController.swift`
- Create: `Sources/AlloyCore/FullScreenTransition.swift`
- Create: `Sources/AlloyCore/InteractiveDismissTransition.swift`

- [ ] **Step 1: Implement PortraitController**

`Sources/AlloyCore/PortraitController.swift`:
```swift
//
//  PortraitController.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

/// 竖屏全屏视图控制器
///
/// 通过 modal present 实现竖屏全屏效果。
final class PortraitController: UIViewController {

    // MARK: - 视图

    /// 播放器内容视图
    var contentView: UIView?

    /// 原始容器视图
    var containerView: UIView?

    // MARK: - 配置

    var isStatusBarHidden = false
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var statusBarAnimation: UIStatusBarAnimation = .fade
    var disabledPortraitGestureTypes: DisablePortraitGestureTypes = []
    var presentationSize: CGSize = .zero
    var isFullScreenAnimation = true
    var animationDuration: TimeInterval = 0.3

    // MARK: - 回调

    var orientationWillChange: ((Bool) -> Void)?
    var orientationDidChange: ((Bool) -> Void)?

    // MARK: - 内部

    private var fullScreenTransition: FullScreenTransition?
    private var interactiveTransition: InteractiveDismissTransition?

    // MARK: - 重写

    override var prefersStatusBarHidden: Bool { isStatusBarHidden }
    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { statusBarAnimation }
    override var shouldAutorotate: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension PortraitController: UIViewControllerTransitioningDelegate {

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let contentView, let containerView else { return nil }
        let transition = FullScreenTransition(isPresenting: true, contentView: contentView, containerView: containerView)
        transition.duration = animationDuration
        fullScreenTransition = transition
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let contentView, let containerView else { return nil }
        let transition = FullScreenTransition(isPresenting: false, contentView: contentView, containerView: containerView)
        transition.duration = animationDuration
        fullScreenTransition = transition
        return transition
    }

    func interactionControllerForDismissal(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        guard let interactiveTransition, interactiveTransition.isInteracting else { return nil }
        return interactiveTransition
    }
}
```

- [ ] **Step 2: Implement FullScreenTransition**

`Sources/AlloyCore/FullScreenTransition.swift`:
```swift
//
//  FullScreenTransition.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 全屏转场动画
final class FullScreenTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let isPresenting: Bool
    let contentView: UIView
    let containerView: UIView
    var duration: TimeInterval = 0.3

    init(isPresenting: Bool, contentView: UIView, containerView: UIView) {
        self.isPresenting = isPresenting
        self.contentView = contentView
        self.containerView = containerView
        super.init()
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresent(using: transitionContext)
        } else {
            animateDismiss(using: transitionContext)
        }
    }

    private func animatePresent(using context: any UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to) else {
            context.completeTransition(false)
            return
        }

        let container = context.containerView
        container.addSubview(toView)
        toView.frame = container.bounds

        // 记录原始 frame
        let startFrame = containerView.convert(containerView.bounds, to: container)
        contentView.frame = startFrame

        container.addSubview(contentView)

        UIView.animate(withDuration: duration, animations: {
            self.contentView.frame = container.bounds
        }, completion: { finished in
            toView.addSubview(self.contentView)
            self.contentView.frame = toView.bounds
            context.completeTransition(!context.transitionWasCancelled)
        })
    }

    private func animateDismiss(using context: any UIViewControllerContextTransitioning) {
        let container = context.containerView
        let targetFrame = containerView.convert(containerView.bounds, to: container)

        container.addSubview(contentView)
        contentView.frame = container.bounds

        UIView.animate(withDuration: duration, animations: {
            self.contentView.frame = targetFrame
        }, completion: { finished in
            self.containerView.addSubview(self.contentView)
            self.contentView.frame = self.containerView.bounds
            context.completeTransition(!context.transitionWasCancelled)
        })
    }
}
```

- [ ] **Step 3: Implement InteractiveDismissTransition**

`Sources/AlloyCore/InteractiveDismissTransition.swift`:
```swift
//
//  InteractiveDismissTransition.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 交互式退出转场
///
/// 通过手势驱动竖屏全屏的退出动画。
final class InteractiveDismissTransition: UIPercentDrivenInteractiveTransition {

    // MARK: - 状态

    var isInteracting = false
    var disabledPortraitGestureTypes: DisablePortraitGestureTypes = []

    // MARK: - 视图

    weak var contentView: UIView?
    weak var containerView: UIView?
    weak var viewController: UIViewController?

    // MARK: - 内部

    private var panGesture: UIPanGestureRecognizer?
    private var startPoint: CGPoint = .zero

    // MARK: - 方法

    func updateViews(contentView: UIView, containerView: UIView) {
        self.contentView = contentView
        self.containerView = containerView
        setupPanGesture()
    }

    private func setupPanGesture() {
        guard !disabledPortraitGestureTypes.contains(.pan) else { return }
        if let old = panGesture {
            contentView?.removeGestureRecognizer(old)
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        contentView?.addGestureRecognizer(pan)
        panGesture = pan
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: view)
        let progress = min(max(translation.y / view.bounds.height, 0), 1)

        switch gesture.state {
        case .began:
            isInteracting = true
            startPoint = gesture.location(in: view)
            viewController?.dismiss(animated: true)

        case .changed:
            update(progress)

        case .ended, .cancelled:
            isInteracting = false
            if progress > 0.3 || gesture.velocity(in: view).y > 500 {
                finish()
            } else {
                cancel()
            }

        default:
            break
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add Sources/AlloyCore/PortraitController.swift Sources/AlloyCore/FullScreenTransition.swift Sources/AlloyCore/InteractiveDismissTransition.swift
git commit -m "实现竖屏全屏系统

- PortraitController: 竖屏全屏 VC + UIViewControllerTransitioningDelegate
- FullScreenTransition: present/dismiss 转场动画
- InteractiveDismissTransition: 手势驱动退出"
```

---

### Task 14: Implement LandscapeRotationHandler

**Files:**
- Create: `Sources/AlloyCore/LandscapeRotationHandler.swift`

- [ ] **Step 1: Implement LandscapeRotationHandler**

`Sources/AlloyCore/LandscapeRotationHandler.swift`:
```swift
//
//  LandscapeRotationHandler.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 横屏旋转处理器
///
/// 内部按 iOS 版本差异分策略：
/// - iOS 16+: 基于 `UIWindowScene.requestGeometryUpdate`
/// - iOS 15: 基于 `UIDevice.setValue` + `supportedInterfaceOrientations`
final class LandscapeRotationHandler {

    // MARK: - 状态

    var currentOrientation: UIInterfaceOrientation = .portrait
    var isAllowOrientationRotation = true
    var isScreenLocked = false
    var isDisableAnimations = false
    var supportedOrientations: InterfaceOrientationMask = .allButUpsideDown
    var isActiveDeviceObserver = false

    // MARK: - 视图

    weak var contentView: UIView?
    weak var containerView: UIView?
    private var window: LandscapeWindow?
    private var landscapeController: LandscapeController?

    // MARK: - 回调

    var orientationWillChange: ((UIInterfaceOrientation) -> Void)?
    var orientationDidChange: ((UIInterfaceOrientation) -> Void)?

    // MARK: - 方法

    func updateViews(contentView: UIView, containerView: UIView) {
        self.contentView = contentView
        self.containerView = containerView
    }

    var fullScreenContainerView: UIView? {
        landscapeController?.view
    }

    /// 旋转到指定方向
    func rotate(
        to orientation: UIInterfaceOrientation,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard isAllowOrientationRotation, !isScreenLocked else {
            completion?()
            return
        }
        guard isSupported(orientation) else {
            completion?()
            return
        }
        guard orientation != currentOrientation else {
            completion?()
            return
        }

        orientationWillChange?(orientation)

        let isToFullScreen = orientation.isLandscape
        let previousOrientation = currentOrientation
        currentOrientation = orientation

        if isToFullScreen {
            rotateToLandscape(orientation: orientation, animated: animated) { [weak self] in
                self?.orientationDidChange?(orientation)
                completion?()
            }
        } else {
            rotateToPortrait(from: previousOrientation, animated: animated) { [weak self] in
                self?.orientationDidChange?(orientation)
                completion?()
            }
        }
    }

    /// 处理设备方向变化
    func handleDeviceOrientationChange() {
        guard isActiveDeviceObserver, isAllowOrientationRotation, !isScreenLocked else { return }

        let deviceOrientation = UIDevice.current.orientation
        let interfaceOrientation: UIInterfaceOrientation
        switch deviceOrientation {
        case .portrait: interfaceOrientation = .portrait
        case .landscapeLeft: interfaceOrientation = .landscapeRight
        case .landscapeRight: interfaceOrientation = .landscapeLeft
        case .portraitUpsideDown: interfaceOrientation = .portraitUpsideDown
        default: return
        }

        guard isSupported(interfaceOrientation) else { return }
        rotate(to: interfaceOrientation, animated: true)
    }

    // MARK: - 内部方法

    private func isSupported(_ orientation: UIInterfaceOrientation) -> Bool {
        switch orientation {
        case .portrait: supportedOrientations.contains(.portrait)
        case .landscapeLeft: supportedOrientations.contains(.landscapeLeft)
        case .landscapeRight: supportedOrientations.contains(.landscapeRight)
        case .portraitUpsideDown: supportedOrientations.contains(.portraitUpsideDown)
        default: false
        }
    }

    private func rotateToLandscape(
        orientation: UIInterfaceOrientation,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        guard let contentView else {
            completion()
            return
        }

        let controller = ensureLandscapeController()
        let window = ensureWindow()

        // 在 iOS 16+ 使用 requestGeometryUpdate
        if #available(iOS 16.0, *) {
            let mask: UIInterfaceOrientationMask = orientation == .landscapeLeft ? .landscapeLeft : .landscapeRight
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
            window.windowScene?.requestGeometryUpdate(preferences)
            controller.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }

        let duration = animated ? 0.3 : 0.0
        controller.view.addSubview(contentView)

        UIView.animate(withDuration: duration, animations: {
            contentView.frame = controller.view.bounds
        }, completion: { _ in
            completion()
        })
    }

    private func rotateToPortrait(
        from previousOrientation: UIInterfaceOrientation,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        guard let contentView, let containerView else {
            completion()
            return
        }

        if #available(iOS 16.0, *) {
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            window?.windowScene?.requestGeometryUpdate(preferences)
            landscapeController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }

        let duration = animated ? 0.3 : 0.0

        UIView.animate(withDuration: duration, animations: {
            contentView.frame = containerView.bounds
        }, completion: { [weak self] _ in
            containerView.addSubview(contentView)
            contentView.frame = containerView.bounds
            self?.cleanupWindow()
            completion()
        })
    }

    private func ensureLandscapeController() -> LandscapeController {
        if let existing = landscapeController { return existing }
        let controller = LandscapeController()
        landscapeController = controller
        return controller
    }

    private func ensureWindow() -> LandscapeWindow {
        if let existing = window { return existing }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else {
            fatalError("No UIWindowScene available")
        }
        let win = LandscapeWindow(windowScene: scene)
        win.rotationHandler = self
        win.rootViewController = landscapeController
        win.isHidden = false
        win.makeKeyAndVisible()
        window = win
        return win
    }

    private func cleanupWindow() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        landscapeController = nil
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/LandscapeRotationHandler.swift
git commit -m "实现 LandscapeRotationHandler 横屏旋转处理

- iOS 16+ 使用 requestGeometryUpdate
- iOS 15 使用 UIDevice.setValue
- 支持方向掩码过滤、锁屏守护
- 自动创建/销毁 LandscapeWindow"
```

---

### Task 15: Implement OrientationManager

**Files:**
- Create: `Sources/AlloyCore/OrientationManager.swift`

- [ ] **Step 1: Implement OrientationManager**

`Sources/AlloyCore/OrientationManager.swift`:
```swift
//
//  OrientationManager.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

/// 屏幕旋转管理器
///
/// 协调横屏旋转和竖屏全屏两种全屏方式。
@MainActor
public final class OrientationManager {

    // MARK: - 视图

    /// 容器视图
    public weak var containerView: UIView?

    /// 全屏容器视图
    public var fullScreenContainerView: UIView? {
        if isFullScreen {
            return fullScreenMode == .portrait
                ? portraitController?.view
                : landscapeHandler.fullScreenContainerView
        }
        return nil
    }

    // MARK: - 状态

    /// 是否处于全屏
    public private(set) var isFullScreen = false

    /// 当前屏幕方向
    public private(set) var currentOrientation: UIInterfaceOrientation = .portrait

    // MARK: - 配置

    /// 全屏模式
    public var fullScreenMode: FullScreenMode = .automatic

    /// 竖屏全屏模式
    public var portraitFullScreenMode: PortraitFullScreenMode = .scaleAspectFit

    /// 动画时长
    public var animationDuration: TimeInterval = 0.3

    /// 锁屏
    public var isScreenLocked = false {
        didSet { landscapeHandler.isScreenLocked = isScreenLocked }
    }

    /// 是否允许旋转
    public var isAllowOrientationRotation = true {
        didSet { landscapeHandler.isAllowOrientationRotation = isAllowOrientationRotation }
    }

    /// 支持的方向
    public var supportedOrientations: InterfaceOrientationMask = .allButUpsideDown {
        didSet { landscapeHandler.supportedOrientations = supportedOrientations }
    }

    /// 全屏状态栏隐藏
    public var isFullScreenStatusBarHidden = true

    /// 全屏状态栏样式
    public var fullScreenStatusBarStyle: UIStatusBarStyle = .lightContent

    /// 全屏状态栏动画
    public var fullScreenStatusBarAnimation: UIStatusBarAnimation = .fade

    /// 视频尺寸
    public var presentationSize: CGSize = .zero

    /// 竖屏全屏禁用手势类型
    public var disabledPortraitGestureTypes: DisablePortraitGestureTypes = []

    // MARK: - Combine

    private let _orientationWillChange = PassthroughSubject<Bool, Never>()
    private let _orientationDidChange = PassthroughSubject<Bool, Never>()

    /// 即将旋转 (参数: isFullScreen)
    public var orientationWillChangePublisher: AnyPublisher<Bool, Never> { _orientationWillChange.eraseToAnyPublisher() }

    /// 旋转完成 (参数: isFullScreen)
    public var orientationDidChangePublisher: AnyPublisher<Bool, Never> { _orientationDidChange.eraseToAnyPublisher() }

    // MARK: - 内部

    private let landscapeHandler = LandscapeRotationHandler()
    private var portraitController: PortraitController?
    private var deviceOrientationObserver: NSObjectProtocol?

    // MARK: - 初始化

    public init() {
        landscapeHandler.orientationWillChange = { [weak self] _ in
            guard let self else { return }
            let willBeFullScreen = !self.isFullScreen
            self._orientationWillChange.send(willBeFullScreen)
        }
        landscapeHandler.orientationDidChange = { [weak self] orientation in
            guard let self else { return }
            self.isFullScreen = orientation.isLandscape
            self.currentOrientation = orientation
            self._orientationDidChange.send(self.isFullScreen)
        }
    }

    // MARK: - 视图绑定

    /// 更新渲染视图与容器视图
    public func updateViews(renderView: RenderView, containerView: UIView) {
        self.containerView = containerView
        landscapeHandler.updateViews(contentView: renderView, containerView: containerView)
    }

    // MARK: - 设备方向监听

    /// 开始监听设备方向变化
    public func addDeviceOrientationObserver() {
        guard deviceOrientationObserver == nil else { return }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        landscapeHandler.isActiveDeviceObserver = true

        deviceOrientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.landscapeHandler.handleDeviceOrientationChange()
        }
    }

    /// 停止监听设备方向变化
    public func removeDeviceOrientationObserver() {
        landscapeHandler.isActiveDeviceObserver = false
        if let observer = deviceOrientationObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceOrientationObserver = nil
        }
    }

    // MARK: - 旋转方法

    /// 旋转到指定方向
    public func rotate(to orientation: UIInterfaceOrientation, animated: Bool) async {
        await withCheckedContinuation { continuation in
            rotate(to: orientation, animated: animated) {
                continuation.resume()
            }
        }
    }

    /// 旋转到指定方向（带回调）
    public func rotate(to orientation: UIInterfaceOrientation, animated: Bool, completion: (() -> Void)?) {
        landscapeHandler.rotate(to: orientation, animated: animated, completion: completion)
    }

    /// 进入/退出竖屏全屏
    public func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) async {
        await withCheckedContinuation { continuation in
            enterPortraitFullScreen(fullScreen, animated: animated) {
                continuation.resume()
            }
        }
    }

    private func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool, completion: (() -> Void)?) {
        _orientationWillChange.send(fullScreen)

        if fullScreen {
            presentPortraitFullScreen(animated: animated) { [weak self] in
                self?.isFullScreen = true
                self?._orientationDidChange.send(true)
                completion?()
            }
        } else {
            dismissPortraitFullScreen(animated: animated) { [weak self] in
                self?.isFullScreen = false
                self?._orientationDidChange.send(false)
                completion?()
            }
        }
    }

    /// 智能进入/退出全屏（根据 fullScreenMode 自动选择横屏或竖屏）
    public func enterFullScreen(_ fullScreen: Bool, animated: Bool) async {
        switch fullScreenMode {
        case .landscape:
            if fullScreen {
                await rotate(to: .landscapeRight, animated: animated)
            } else {
                await rotate(to: .portrait, animated: animated)
            }
        case .portrait:
            await enterPortraitFullScreen(fullScreen, animated: animated)
        case .automatic:
            // 根据视频宽高比选择：宽 > 高 → 横屏，否则竖屏
            if presentationSize.width > presentationSize.height {
                if fullScreen {
                    await rotate(to: .landscapeRight, animated: animated)
                } else {
                    await rotate(to: .portrait, animated: animated)
                }
            } else {
                await enterPortraitFullScreen(fullScreen, animated: animated)
            }
        }
    }

    // MARK: - 竖屏全屏内部方法

    private func presentPortraitFullScreen(animated: Bool, completion: (() -> Void)?) {
        guard let containerView, let contentView = landscapeHandler.contentView else {
            completion?()
            return
        }

        let controller = PortraitController()
        controller.contentView = contentView
        controller.containerView = containerView
        controller.animationDuration = animationDuration
        controller.presentationSize = presentationSize
        controller.disabledPortraitGestureTypes = disabledPortraitGestureTypes
        controller.isStatusBarHidden = isFullScreenStatusBarHidden
        controller.statusBarStyle = fullScreenStatusBarStyle
        controller.modalPresentationStyle = .custom
        portraitController = controller

        guard let presenting = UIApplication.shared.topViewController else {
            completion?()
            return
        }

        presenting.present(controller, animated: animated) {
            completion?()
        }
    }

    private func dismissPortraitFullScreen(animated: Bool, completion: (() -> Void)?) {
        portraitController?.dismiss(animated: animated) { [weak self] in
            self?.portraitController = nil
            completion?()
        }
    }

    deinit {
        if let observer = deviceOrientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - UIApplication 扩展（查找顶层 VC）

private extension UIApplication {
    @MainActor
    var topViewController: UIViewController? {
        guard let scene = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
            var top = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
```

- [ ] **Step 2: Verify build**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeded (或因 Player/GestureManager 未定义而暂时失败，将在 Task 17 一并解决)

- [ ] **Step 3: Commit**

```bash
git add Sources/AlloyCore/OrientationManager.swift
git commit -m "实现 OrientationManager 屏幕旋转管理器

- 协调横屏旋转和竖屏全屏两种模式
- fullScreenMode=automatic 根据视频宽高比自动选择
- async/await 和回调两种 API
- 设备方向监听自动管理"
```

---

### Task 16: Implement ScrollView+Player extension

**Files:**
- Create: `Sources/AlloyCore/ScrollView+Player.swift`

- [ ] **Step 1: Implement ScrollView+Player**

`Sources/AlloyCore/ScrollView+Player.swift`:
```swift
//
//  ScrollView+Player.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import ObjectiveC
import UIKit

// MARK: - UIScrollView 播放器扩展

extension UIScrollView {

    // MARK: - Associated Keys

    private enum AssociatedKeys {
        static var scrollViewDirection = "alloy_scrollViewDirection"
        static var lastOffsetY = "alloy_lastOffsetY"
        static var lastOffsetX = "alloy_lastOffsetX"
        static var scrollDirection = "alloy_scrollDirection"
    }

    // MARK: - 公开属性

    /// 滚动视图方向（纵向/横向）
    public var scrollViewDirection: ScrollViewDirection {
        get {
            (objc_getAssociatedObject(self, &AssociatedKeys.scrollViewDirection) as? Int)
                .flatMap(ScrollViewDirection.init(rawValue:)) ?? .vertical
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.scrollViewDirection, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 当前滚动方向
    public internal(set) var scrollDirection: ScrollDirection {
        get {
            (objc_getAssociatedObject(self, &AssociatedKeys.scrollDirection) as? Int)
                .flatMap(ScrollDirection.init(rawValue:)) ?? .none
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.scrollDirection, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - 内部属性

    var lastOffsetY: CGFloat {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastOffsetY) as? CGFloat ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastOffsetY, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var lastOffsetX: CGFloat {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastOffsetX) as? CGFloat ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastOffsetX, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - Cell 查找

    /// 获取指定 IndexPath 对应的 Cell
    public func cell(at indexPath: IndexPath) -> UIView? {
        if let tableView = self as? UITableView {
            return tableView.cellForRow(at: indexPath)
        } else if let collectionView = self as? UICollectionView {
            return collectionView.cellForItem(at: indexPath)
        }
        return nil
    }

    /// 获取 Cell 对应的 IndexPath
    public func indexPath(for cell: UIView) -> IndexPath? {
        if let tableView = self as? UITableView, let tableCell = cell as? UITableViewCell {
            return tableView.indexPath(for: tableCell)
        } else if let collectionView = self as? UICollectionView, let collectionCell = cell as? UICollectionViewCell {
            return collectionView.indexPath(for: collectionCell)
        }
        return nil
    }

    // MARK: - 滚动

    /// 滚动到指定 IndexPath
    public func scroll(
        to indexPath: IndexPath,
        at anchor: ScrollAnchor,
        animated: Bool
    ) async {
        await withCheckedContinuation { continuation in
            scroll(to: indexPath, at: anchor, animated: animated) {
                continuation.resume()
            }
        }
    }

    func scroll(
        to indexPath: IndexPath,
        at anchor: ScrollAnchor,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        if let tableView = self as? UITableView {
            let position: UITableView.ScrollPosition = switch anchor {
            case .top: .top
            case .centeredVertically: .middle
            case .bottom: .bottom
            default: .none
            }
            tableView.scrollToRow(at: indexPath, at: position, animated: animated)
        } else if let collectionView = self as? UICollectionView {
            let position: UICollectionView.ScrollPosition = switch anchor {
            case .top: .top
            case .centeredVertically: .centeredVertically
            case .bottom: .bottom
            case .left: .left
            case .centeredHorizontally: .centeredHorizontally
            case .right: .right
            default: []
            }
            collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
        }

        if animated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion?()
            }
        } else {
            completion?()
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/ScrollView+Player.swift
git commit -m "实现 UIScrollView 播放器扩展

- 滚动方向追踪
- Cell 查找（TableView/CollectionView）
- 滚动到指定 IndexPath（async/await）"
```

---

## Phase 5: Player Controller

### Task 17: Implement Player core class

**Files:**
- Create: `Sources/AlloyCore/Player.swift`

- [ ] **Step 1: Implement Player.swift**

`Sources/AlloyCore/Player.swift`:
```swift
//
//  Player.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

/// 播放器主控制器
///
/// 协调播放引擎（PlaybackEngine）、控制层（ControlOverlay）、
/// 手势管理（GestureManager）和旋转管理（OrientationManager）。
@MainActor
public final class Player {

    // MARK: - 组件

    /// 容器视图
    public weak var containerView: UIView? {
        didSet { layoutPlayerSubViews() }
    }

    /// 播放引擎
    public var engine: PlaybackEngine {
        didSet { setupEngine() }
    }

    /// 控制层
    public var controlOverlay: (UIView & ControlOverlay)? {
        didSet {
            oldValue?.removeFromSuperview()
            controlOverlay?.player = self
            layoutPlayerSubViews()
        }
    }

    /// 旋转管理器
    public private(set) var orientationManager = OrientationManager()

    /// 手势管理器
    public private(set) var gestureManager = GestureManager()

    /// 系统事件观察者
    public private(set) var systemEventObserver: SystemEventObserver?

    /// 挂载模式
    public private(set) var attachmentMode: AttachmentMode

    // MARK: - 播放状态

    /// 当前播放时间
    public var currentTime: TimeInterval { engine.currentTime }

    /// 总时长
    public var totalTime: TimeInterval { engine.totalTime }

    /// 缓冲时长
    public var bufferTime: TimeInterval { engine.bufferTime }

    /// 播放进度 (0...1)
    public var progress: Float {
        guard totalTime > 0 else { return 0 }
        return Float(currentTime / totalTime)
    }

    /// 缓冲进度 (0...1)
    public var bufferProgress: Float {
        guard totalTime > 0 else { return 0 }
        return Float(bufferTime / totalTime)
    }

    /// 是否全屏
    public var isFullScreen: Bool { orientationManager.isFullScreen }

    // MARK: - 播放控制

    /// 音量
    public var volume: Float {
        get { engine.volume }
        set { engine.volume = newValue }
    }

    /// 静音
    public var isMuted: Bool {
        get { engine.isMuted }
        set { engine.isMuted = newValue }
    }

    /// 屏幕亮度
    public var brightness: Float {
        get { Float(UIScreen.main.brightness) }
        set { UIScreen.main.brightness = CGFloat(newValue) }
    }

    /// 播放速率
    public var rate: Float {
        get { engine.rate }
        set { engine.rate = newValue }
    }

    // MARK: - 资源管理

    /// 当前播放 URL
    public var assetURL: URL? {
        get { engine.assetURL }
        set {
            engine.assetURL = newValue
            if newValue != nil {
                setupNotification()
                engine.prepareToPlay()
            }
        }
    }

    /// 播放列表
    public var assetURLs: [URL]?

    /// 当前播放索引
    public var currentPlayIndex: Int = 0

    /// 是否为第一个资源
    public var isFirstAsset: Bool { currentPlayIndex == 0 }

    /// 是否为最后一个资源
    public var isLastAsset: Bool {
        guard let urls = assetURLs else { return true }
        return currentPlayIndex >= urls.count - 1
    }

    // MARK: - 行为配置

    /// 恢复播放记录
    public var shouldResumePlayRecord = false

    /// 进入后台时暂停
    public var pauseWhenAppResignActive = true

    /// 被外部事件暂停
    public var isPausedByEvent = false

    /// VC 是否不可见
    public var isViewControllerDisappear = false {
        didSet {
            if isViewControllerDisappear {
                removeDeviceOrientationObserver()
            } else {
                addDeviceOrientationObserver()
            }
        }
    }

    /// 自定义音频会话
    public var useCustomAudioSession = false

    /// 停止时退出全屏
    public var exitFullScreenWhenStop = true

    // MARK: - 锁屏 & 状态栏

    /// 锁屏
    public var isScreenLocked: Bool {
        get { orientationManager.isScreenLocked }
        set {
            orientationManager.isScreenLocked = newValue
            controlOverlay?.player(self, didChangeLockState: newValue)
        }
    }

    /// 状态栏隐藏
    public var isStatusBarHidden: Bool {
        get { orientationManager.isFullScreenStatusBarHidden }
        set { orientationManager.isFullScreenStatusBarHidden = newValue }
    }

    /// 全屏状态栏样式
    public var fullScreenStatusBarStyle: UIStatusBarStyle {
        get { orientationManager.fullScreenStatusBarStyle }
        set { orientationManager.fullScreenStatusBarStyle = newValue }
    }

    /// 全屏状态栏动画
    public var fullScreenStatusBarAnimation: UIStatusBarAnimation {
        get { orientationManager.fullScreenStatusBarAnimation }
        set { orientationManager.fullScreenStatusBarAnimation = newValue }
    }

    // MARK: - 手势配置

    /// 禁用的手势类型
    public var disabledGestureTypes: DisableGestureTypes {
        get { gestureManager.disabledGestureTypes }
        set { gestureManager.disabledGestureTypes = newValue }
    }

    /// 禁用的滑动方向
    public var disabledPanMovingDirection: DisablePanMovingDirection {
        get { gestureManager.disabledPanMovingDirection }
        set { gestureManager.disabledPanMovingDirection = newValue }
    }

    // MARK: - Combine Subjects（Player 独有事件）

    private let _orientationWillChange = PassthroughSubject<Bool, Never>()
    private let _orientationDidChange = PassthroughSubject<Bool, Never>()

    // MARK: - Combine 事件流

    /// 播放状态变化（透传 engine）
    public var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { engine.statePublisher }
    /// 加载状态变化
    public var loadStatePublisher: AnyPublisher<LoadState, Never> { engine.loadStatePublisher }
    /// 播放时间变化
    public var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> { engine.playTimePublisher }
    /// 缓冲时间变化
    public var bufferTimePublisher: AnyPublisher<TimeInterval, Never> { engine.bufferTimePublisher }
    /// 播放失败
    public var playFailedPublisher: AnyPublisher<any Error, Never> { engine.playFailedPublisher }
    /// 播放完成
    public var didPlayToEndPublisher: AnyPublisher<Void, Never> { engine.didPlayToEndPublisher }
    /// 视频尺寸变化
    public var presentationSizePublisher: AnyPublisher<CGSize, Never> { engine.presentationSizePublisher }
    /// 即将旋转
    public var orientationWillChangePublisher: AnyPublisher<Bool, Never> { orientationManager.orientationWillChangePublisher }
    /// 旋转完成
    public var orientationDidChangePublisher: AnyPublisher<Bool, Never> { orientationManager.orientationDidChangePublisher }

    // MARK: - 内部状态

    private var cancellables = Set<AnyCancellable>()
    private var volumeSlider: UISlider?
    private static var playRecords: [String: TimeInterval] = [:]

    // MARK: - 列表播放属性（在 Player+ScrollView.swift 中扩展）

    weak var scrollView: UIScrollView?

    // MARK: - 初始化

    /// 普通模式初始化
    public init(engine: PlaybackEngine, containerView: UIView) {
        self.engine = engine
        self.attachmentMode = .view
        self.containerView = containerView
        commonInit()
    }

    /// 列表模式初始化（通过 tag 查找容器）
    public init(scrollView: UIScrollView, engine: PlaybackEngine, containerViewTag: Int) {
        self.engine = engine
        self.attachmentMode = .cell
        self.scrollView = scrollView
        self._containerViewTag = containerViewTag
        commonInit()
    }

    /// 列表模式初始化（直接传入容器）
    public init(scrollView: UIScrollView, engine: PlaybackEngine, containerView: UIView) {
        self.engine = engine
        self.attachmentMode = .cell
        self.scrollView = scrollView
        self.containerView = containerView
        commonInit()
    }

    private func commonInit() {
        setupEngine()
        setupGesture()
        setupOrientation()
        configureVolume()
        ReachabilityMonitor.shared.startMonitoring()
        subscribeReachability()
    }

    deinit {
        engine.stop()
        systemEventObserver?.stopObserving()
    }

    // MARK: - 内部 Setup

    private func setupEngine() {
        // 移除旧手势
        gestureManager.detach(from: engine.renderView)
        // 绑定新手势
        gestureManager.attach(to: engine.renderView)
        // 订阅引擎事件
        subscribeEngine()
        // 布局
        layoutPlayerSubViews()
    }

    private func setupGesture() {
        // 手势回调转发给 controlOverlay
        gestureManager.triggerCondition = { [weak self] type, recognizer, touch in
            guard let self, let overlay = self.controlOverlay else { return true }
            return overlay.gestureTriggerCondition(self.gestureManager, type: type, recognizer: recognizer, touch: touch)
        }

        gestureManager.singleTapPublisher.sink { [weak self] in
            guard let self else { return }
            self.controlOverlay?.gestureSingleTapped(self.gestureManager)
        }.store(in: &cancellables)

        gestureManager.doubleTapPublisher.sink { [weak self] in
            guard let self else { return }
            self.controlOverlay?.gestureDoubleTapped(self.gestureManager)
        }.store(in: &cancellables)

        gestureManager.panBeganPublisher.sink { [weak self] event in
            guard let self else { return }
            self.controlOverlay?.gestureBeganPan(self.gestureManager, direction: event.direction, location: event.location)
        }.store(in: &cancellables)

        gestureManager.panChangedPublisher.sink { [weak self] event in
            guard let self else { return }
            self.controlOverlay?.gestureChangedPan(self.gestureManager, direction: event.direction, location: event.location, velocity: event.velocity)
        }.store(in: &cancellables)

        gestureManager.panEndedPublisher.sink { [weak self] event in
            guard let self else { return }
            self.controlOverlay?.gestureEndedPan(self.gestureManager, direction: event.direction, location: event.location)
        }.store(in: &cancellables)

        gestureManager.pinchPublisher.sink { [weak self] scale in
            guard let self else { return }
            self.controlOverlay?.gesturePinched(self.gestureManager, scale: scale)
        }.store(in: &cancellables)

        gestureManager.longPressPublisher.sink { [weak self] state in
            guard let self else { return }
            self.controlOverlay?.longPressed(self.gestureManager, state: state)
        }.store(in: &cancellables)
    }

    private func setupOrientation() {
        if let containerView {
            orientationManager.updateViews(renderView: engine.renderView, containerView: containerView)
        }
        orientationManager.orientationWillChangePublisher.sink { [weak self] isFullScreen in
            guard let self else { return }
            self.controlOverlay?.player(self, willChangeOrientation: self.orientationManager)
        }.store(in: &cancellables)

        orientationManager.orientationDidChangePublisher.sink { [weak self] isFullScreen in
            guard let self else { return }
            self.controlOverlay?.player(self, didChangeOrientation: self.orientationManager)
            self.layoutPlayerSubViews()
        }.store(in: &cancellables)
    }

    private func subscribeEngine() {
        // 清理旧订阅
        cancellables.removeAll()
        setupGesture()
        setupOrientation()

        engine.statePublisher.sink { [weak self] state in
            guard let self else { return }
            self.controlOverlay?.player(self, didChangePlaybackState: state)
        }.store(in: &cancellables)

        engine.loadStatePublisher.sink { [weak self] state in
            guard let self else { return }
            self.controlOverlay?.player(self, didChangeLoadState: state)
        }.store(in: &cancellables)

        engine.playTimePublisher.sink { [weak self] time in
            guard let self else { return }
            self.controlOverlay?.player(self, didUpdateTime: time.current, totalTime: time.total)
        }.store(in: &cancellables)

        engine.bufferTimePublisher.sink { [weak self] bufferTime in
            guard let self else { return }
            self.controlOverlay?.player(self, didUpdateBufferTime: bufferTime)
        }.store(in: &cancellables)

        engine.prepareToPlayPublisher.sink { [weak self] url in
            guard let self else { return }
            self.controlOverlay?.player(self, prepareToPlay: url)
        }.store(in: &cancellables)

        engine.playFailedPublisher.sink { [weak self] error in
            guard let self else { return }
            self.controlOverlay?.player(self, didFailWithError: error)
        }.store(in: &cancellables)

        engine.didPlayToEndPublisher.sink { [weak self] in
            guard let self else { return }
            self.controlOverlay?.playerDidPlayToEnd(self)
        }.store(in: &cancellables)

        engine.presentationSizePublisher.sink { [weak self] size in
            guard let self else { return }
            self.orientationManager.presentationSize = size
            self.controlOverlay?.player(self, didChangePresentationSize: size)
        }.store(in: &cancellables)
    }

    private func subscribeReachability() {
        ReachabilityMonitor.shared.statusPublisher.sink { [weak self] status in
            guard let self else { return }
            self.controlOverlay?.player(self, didChangeReachability: status)
        }.store(in: &cancellables)
    }

    private func setupNotification() {
        systemEventObserver?.stopObserving()
        let observer = SystemEventObserver()
        systemEventObserver = observer
        observer.startObserving()

        observer.willResignActivePublisher.sink { [weak self] in
            guard let self, self.pauseWhenAppResignActive else { return }
            self.isPausedByEvent = true
            self.engine.pause()
        }.store(in: &cancellables)

        observer.didBecomeActivePublisher.sink { [weak self] in
            guard let self, self.isPausedByEvent else { return }
            self.isPausedByEvent = false
            if self.engine.shouldAutoPlay {
                self.engine.play()
            }
        }.store(in: &cancellables)
    }

    private func configureVolume() {
        // 系统音量控制
    }

    private func layoutPlayerSubViews() {
        guard let containerView else { return }
        let renderView = engine.renderView

        if renderView.superview !== containerView {
            containerView.addSubview(renderView)
        }
        renderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            renderView.topAnchor.constraint(equalTo: containerView.topAnchor),
            renderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            renderView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        if let overlay = controlOverlay {
            if overlay.superview !== renderView {
                renderView.addSubview(overlay)
            }
            overlay.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: renderView.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: renderView.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: renderView.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: renderView.bottomAnchor),
            ])
        }

        orientationManager.updateViews(renderView: renderView, containerView: containerView)
    }

    // MARK: - 列表播放内部属性

    var _containerViewTag: Int = 0
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/Player.swift
git commit -m "实现 Player 主控制器

- 协调 PlaybackEngine + ControlOverlay + GestureManager + OrientationManager
- Combine 订阅引擎事件并转发给控制层
- 普通模式和列表模式两种初始化
- 前后台暂停/恢复、网络状态监控"
```

---

### Task 18: Implement Player+Playback

**Files:**
- Create: `Sources/AlloyCore/Player+Playback.swift`

- [ ] **Step 1: Implement Player+Playback**

`Sources/AlloyCore/Player+Playback.swift`:
```swift
//
//  Player+Playback.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Foundation

// MARK: - 播放控制扩展

extension Player {

    /// 停止播放
    public func stop() {
        engine.stop()
        systemEventObserver?.stopObserving()
        systemEventObserver = nil

        if exitFullScreenWhenStop, isFullScreen {
            Task {
                await orientationManager.enterFullScreen(false, animated: true)
            }
        }
    }

    /// 替换播放引擎
    public func replaceEngine(_ newEngine: PlaybackEngine) {
        engine.stop()
        engine = newEngine
    }

    /// 播放下一个
    public func playNext() {
        guard let urls = assetURLs, currentPlayIndex < urls.count - 1 else { return }
        currentPlayIndex += 1
        assetURL = urls[currentPlayIndex]
    }

    /// 播放上一个
    public func playPrevious() {
        guard let urls = assetURLs, currentPlayIndex > 0 else { return }
        currentPlayIndex -= 1
        assetURL = urls[currentPlayIndex]
    }

    /// 播放指定索引
    public func play(at index: Int) {
        guard let urls = assetURLs, index >= 0, index < urls.count else { return }
        currentPlayIndex = index
        assetURL = urls[index]
    }

    /// 跳转到指定时间
    @discardableResult
    public func seek(to time: TimeInterval) async -> Bool {
        await engine.seek(to: time)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/Player+Playback.swift
git commit -m "实现 Player+Playback 播放控制扩展

- stop/replaceEngine/playNext/playPrevious/play(at:)
- seek(to:) async 跳转"
```

---

### Task 19: Implement Player+Orientation

**Files:**
- Create: `Sources/AlloyCore/Player+Orientation.swift`

- [ ] **Step 1: Implement Player+Orientation**

`Sources/AlloyCore/Player+Orientation.swift`:
```swift
//
//  Player+Orientation.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - 旋转/全屏扩展

extension Player {

    /// 允许旋转
    public var isAllowOrientationRotation: Bool {
        get { orientationManager.isAllowOrientationRotation }
        set { orientationManager.isAllowOrientationRotation = newValue }
    }

    /// 开始监听设备方向变化
    public func addDeviceOrientationObserver() {
        orientationManager.addDeviceOrientationObserver()
    }

    /// 停止监听设备方向变化
    public func removeDeviceOrientationObserver() {
        orientationManager.removeDeviceOrientationObserver()
    }

    /// 旋转到指定方向
    public func rotate(to orientation: UIInterfaceOrientation, animated: Bool) async {
        await orientationManager.rotate(to: orientation, animated: animated)
    }

    /// 进入/退出竖屏全屏
    public func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) async {
        await orientationManager.enterPortraitFullScreen(fullScreen, animated: animated)
    }

    /// 智能进入/退出全屏
    public func enterFullScreen(_ fullScreen: Bool, animated: Bool) async {
        await orientationManager.enterFullScreen(fullScreen, animated: animated)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyCore/Player+Orientation.swift
git commit -m "实现 Player+Orientation 旋转/全屏扩展

- 代理到 OrientationManager
- rotate/enterPortraitFullScreen/enterFullScreen async API"
```

---

### Task 20: Implement Player+ScrollView

**Files:**
- Create: `Sources/AlloyCore/Player+ScrollView.swift`

- [ ] **Step 1: Implement Player+ScrollView**

`Sources/AlloyCore/Player+ScrollView.swift`:
```swift
//
//  Player+ScrollView.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

// MARK: - 列表播放扩展

extension Player {

    // MARK: - 小窗

    /// 小窗视图
    public var floatingView: FloatingView? { _floatingView }

    /// 小窗是否可见
    public var isFloatingViewVisible: Bool { _isFloatingViewVisible }

    /// 将播放器添加到 Cell
    public func addPlayerView(to cell: UIView) {
        let container = cell.viewWithTag(_containerViewTag)
        if let container {
            containerView = container
        }
    }

    /// 将播放器添加到指定容器视图
    public func addPlayerView(to containerView: UIView) {
        self.containerView = containerView
    }

    /// 将播放器添加到小窗
    public func addPlayerViewToFloatingView() {
        guard let view = ensureFloatingView() else { return }
        _isFloatingViewVisible = true
        view.addSubview(engine.renderView)
        engine.renderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            engine.renderView.topAnchor.constraint(equalTo: view.topAnchor),
            engine.renderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            engine.renderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            engine.renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        controlOverlay?.player(self, floatViewShow: true)
    }

    // MARK: - 列表配置

    /// 是否自动播放
    public var shouldAutoPlay: Bool {
        get { _shouldAutoPlay }
        set { _shouldAutoPlay = newValue }
    }

    /// 移动网络下自动播放
    public var autoPlayOnWWAN: Bool {
        get { _autoPlayOnWWAN }
        set { _autoPlayOnWWAN = newValue }
    }

    /// 当前正在播放的 IndexPath
    public var playingIndexPath: IndexPath? { _playingIndexPath }

    /// 应该播放的 IndexPath
    public var shouldPlayIndexPath: IndexPath? { _shouldPlayIndexPath }

    /// 容器视图 Tag
    public var containerViewTag: Int { _containerViewTag }

    /// 不可见时停止播放
    public var stopWhileNotVisible: Bool {
        get { _stopWhileNotVisible }
        set { _stopWhileNotVisible = newValue }
    }

    /// 消失多少百分比后触发消失回调
    public var disappearPercent: CGFloat {
        get { _disappearPercent }
        set { _disappearPercent = newValue }
    }

    /// 出现多少百分比后触发出现回调
    public var appearPercent: CGFloat {
        get { _appearPercent }
        set { _appearPercent = newValue }
    }

    /// 分段 URL 数据源
    public var sectionAssetURLs: [[URL]]? {
        get { _sectionAssetURLs }
        set { _sectionAssetURLs = newValue }
    }

    // MARK: - 列表播放事件 Publishers

    public var playerAppearingPublisher: AnyPublisher<(IndexPath, CGFloat), Never> { _playerAppearing.eraseToAnyPublisher() }
    public var playerDisappearingPublisher: AnyPublisher<(IndexPath, CGFloat), Never> { _playerDisappearing.eraseToAnyPublisher() }
    public var playerWillAppearPublisher: AnyPublisher<IndexPath, Never> { _playerWillAppear.eraseToAnyPublisher() }
    public var playerDidAppearPublisher: AnyPublisher<IndexPath, Never> { _playerDidAppear.eraseToAnyPublisher() }
    public var playerWillDisappearPublisher: AnyPublisher<IndexPath, Never> { _playerWillDisappear.eraseToAnyPublisher() }
    public var playerDidDisappearPublisher: AnyPublisher<IndexPath, Never> { _playerDidDisappear.eraseToAnyPublisher() }
    public var scrollViewDidEndScrollingPublisher: AnyPublisher<IndexPath, Never> { _scrollViewDidEndScrolling.eraseToAnyPublisher() }

    // MARK: - 播放指定位置

    /// 播放指定 IndexPath
    public func play(at indexPath: IndexPath) {
        play(at: indexPath, scrollTo: .none, animated: false)
    }

    /// 播放指定 IndexPath 并滚动
    public func play(at indexPath: IndexPath, scrollTo position: ScrollAnchor, animated: Bool) async {
        _playingIndexPath = indexPath
        if let scrollView, position != .none {
            await scrollView.scroll(to: indexPath, at: position, animated: animated)
        }
        if let cell = scrollView?.cell(at: indexPath) {
            addPlayerView(to: cell)
        }
        if let urls = _sectionAssetURLs,
           indexPath.section < urls.count,
           indexPath.row < urls[indexPath.section].count
        {
            assetURL = urls[indexPath.section][indexPath.row]
        }
    }

    /// 播放指定 IndexPath 和 URL
    public func play(at indexPath: IndexPath, assetURL: URL) {
        _playingIndexPath = indexPath
        if let cell = scrollView?.cell(at: indexPath) {
            addPlayerView(to: cell)
        }
        self.assetURL = assetURL
    }

    /// 播放指定 IndexPath、URL 并滚动
    public func play(at indexPath: IndexPath, assetURL: URL, scrollTo position: ScrollAnchor, animated: Bool) async {
        _playingIndexPath = indexPath
        if let scrollView, position != .none {
            await scrollView.scroll(to: indexPath, at: position, animated: animated)
        }
        if let cell = scrollView?.cell(at: indexPath) {
            addPlayerView(to: cell)
        }
        self.assetURL = assetURL
    }

    // MARK: - 滚动过滤

    /// 滚动停止时过滤应播放的 Cell
    public func filterShouldPlayCellWhileScrolled() -> IndexPath? {
        // 简化实现：查找最靠近屏幕中心的 Cell
        guard let scrollView else { return nil }
        let visibleCells: [IndexPath]
        if let tableView = scrollView as? UITableView {
            visibleCells = tableView.indexPathsForVisibleRows ?? []
        } else if let collectionView = scrollView as? UICollectionView {
            visibleCells = collectionView.indexPathsForVisibleItems
        } else {
            return nil
        }
        return visibleCells.first
    }

    /// 滚动中过滤应播放的 Cell
    public func filterShouldPlayCellWhileScrolling() -> IndexPath? {
        filterShouldPlayCellWhileScrolled()
    }

    /// 停止当前播放视图
    public func stopCurrentPlayingView() {
        stop()
        _isFloatingViewVisible = false
        _floatingView?.removeFromSuperview()
    }

    /// 停止当前播放 Cell
    public func stopCurrentPlayingCell() {
        stop()
        _playingIndexPath = nil
    }

    // MARK: - 内部存储

    private var _floatingView: FloatingView? {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.floatingView) as? FloatingView }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.floatingView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var _isFloatingViewVisible: Bool {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.isFloatingViewVisible) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.isFloatingViewVisible, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _shouldAutoPlay: Bool {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.shouldAutoPlay) as? Bool ?? true }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.shouldAutoPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _autoPlayOnWWAN: Bool {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.autoPlayOnWWAN) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.autoPlayOnWWAN, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _playingIndexPath: IndexPath? {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.playingIndexPath) as? IndexPath }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.playingIndexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _shouldPlayIndexPath: IndexPath? {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.shouldPlayIndexPath) as? IndexPath }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.shouldPlayIndexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _stopWhileNotVisible: Bool {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.stopWhileNotVisible) as? Bool ?? true }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.stopWhileNotVisible, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _disappearPercent: CGFloat {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.disappearPercent) as? CGFloat ?? 0.8 }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.disappearPercent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _appearPercent: CGFloat {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.appearPercent) as? CGFloat ?? 0.0 }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.appearPercent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var _sectionAssetURLs: [[URL]]? {
        get { objc_getAssociatedObject(self, &ScrollViewKeys.sectionAssetURLs) as? [[URL]] }
        set { objc_setAssociatedObject(self, &ScrollViewKeys.sectionAssetURLs, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - Subjects

    let _playerAppearing = PassthroughSubject<(IndexPath, CGFloat), Never>()
    let _playerDisappearing = PassthroughSubject<(IndexPath, CGFloat), Never>()
    let _playerWillAppear = PassthroughSubject<IndexPath, Never>()
    let _playerDidAppear = PassthroughSubject<IndexPath, Never>()
    let _playerWillDisappear = PassthroughSubject<IndexPath, Never>()
    let _playerDidDisappear = PassthroughSubject<IndexPath, Never>()
    let _scrollViewDidEndScrolling = PassthroughSubject<IndexPath, Never>()

    // MARK: - 辅助

    private func ensureFloatingView() -> FloatingView? {
        if let existing = _floatingView { return existing }
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else { return nil }

        let floatView = FloatingView(frame: CGRect(x: keyWindow.bounds.width - 212, y: keyWindow.bounds.height - 168, width: 192, height: 108))
        floatView.parentView = keyWindow
        floatView.safeInsets = keyWindow.safeAreaInsets
        _floatingView = floatView
        return floatView
    }

    private func play(at indexPath: IndexPath, scrollTo position: ScrollAnchor, animated: Bool) {
        Task {
            await play(at: indexPath, scrollTo: position, animated: animated)
        }
    }
}

// MARK: - Associated Keys

import ObjectiveC

private enum ScrollViewKeys {
    static var floatingView = "alloy_floatingView"
    static var isFloatingViewVisible = "alloy_isFloatingViewVisible"
    static var shouldAutoPlay = "alloy_shouldAutoPlay"
    static var autoPlayOnWWAN = "alloy_autoPlayOnWWAN"
    static var playingIndexPath = "alloy_playingIndexPath"
    static var shouldPlayIndexPath = "alloy_shouldPlayIndexPath"
    static var stopWhileNotVisible = "alloy_stopWhileNotVisible"
    static var disappearPercent = "alloy_disappearPercent"
    static var appearPercent = "alloy_appearPercent"
    static var sectionAssetURLs = "alloy_sectionAssetURLs"
}
```

- [ ] **Step 2: Verify build**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded（AlloyCore 模块编译通过）

- [ ] **Step 3: Commit**

```bash
git add Sources/AlloyCore/Player+ScrollView.swift
git commit -m "实现 Player+ScrollView 列表播放扩展

- 小窗管理（FloatingView）
- 列表播放配置（自动播放、消失百分比等）
- play(at:)/play(at:assetURL:) 系列方法
- Combine Publishers 列表播放事件"
```

---

## Phase 6: AlloyAVPlayer

### Task 21: Implement AVPlayerManager

**Files:**
- Create: `Sources/AlloyAVPlayer/AVPlayerManager.swift`

- [ ] **Step 1: Implement AVPlayerManager**

此文件较长（AVFoundation 集成），包含 KVO 观察、周期性时间更新、缓冲管理、截图等完整功能。

`Sources/AlloyAVPlayer/AVPlayerManager.swift`:
```swift
//
//  AVPlayerManager.swift
//  AlloyAVPlayer
//
//  Created by Sun on 2026/4/14.
//

import AlloyCore
import AVFoundation
import Combine
import UIKit

/// AVPlayer 播放引擎
///
/// 基于 AVFoundation 实现的 `PlaybackEngine`，是框架内置的默认播放引擎。
@MainActor
public final class AVPlayerManager: PlaybackEngine {

    // MARK: - AVFoundation 对象

    public private(set) var asset: AVURLAsset?
    public private(set) var playerItem: AVPlayerItem?
    public private(set) var player: AVPlayer?
    public private(set) var playerLayer: AVPlayerLayer?

    // MARK: - 配置

    /// 时间刷新间隔（默认 0.1s）
    public var timeRefreshInterval: TimeInterval = 0.1

    /// 自定义请求头
    public var requestHeaders: [String: String]?

    // MARK: - PlaybackEngine 属性

    public let renderView = RenderView()

    public private(set) var playbackState: PlaybackState = .unknown {
        didSet { if playbackState != oldValue { _state.send(playbackState) } }
    }
    public private(set) var loadState: LoadState = .unknown {
        didSet { if loadState != oldValue { _loadState.send(loadState) } }
    }
    public var isPlaying: Bool { playbackState == .playing }
    public private(set) var isPreparedToPlay = false

    public var volume: Float {
        get { player?.volume ?? 0 }
        set { player?.volume = newValue }
    }
    public var isMuted: Bool {
        get { player?.isMuted ?? false }
        set { player?.isMuted = newValue }
    }
    public var rate: Float {
        get { player?.rate ?? 1 }
        set { player?.rate = newValue }
    }
    public var scalingMode: ScalingMode = .aspectFit {
        didSet { updateVideoGravity() }
    }
    public var shouldAutoPlay = true

    public private(set) var currentTime: TimeInterval = 0
    public private(set) var totalTime: TimeInterval = 0
    public private(set) var bufferTime: TimeInterval = 0
    public var seekTime: TimeInterval = 0

    public var assetURL: URL? {
        didSet {
            if assetURL != oldValue {
                stop()
                if assetURL != nil { prepareToPlay() }
            }
        }
    }
    public private(set) var presentationSize: CGSize = .zero {
        didSet { if presentationSize != oldValue { _presentationSize.send(presentationSize) } }
    }

    // MARK: - Combine Subjects

    private let _state = PassthroughSubject<PlaybackState, Never>()
    private let _loadState = PassthroughSubject<LoadState, Never>()
    private let _playTime = PassthroughSubject<(current: TimeInterval, total: TimeInterval), Never>()
    private let _bufferTime = PassthroughSubject<TimeInterval, Never>()
    private let _prepareToPlay = PassthroughSubject<URL, Never>()
    private let _readyToPlay = PassthroughSubject<URL, Never>()
    private let _playFailed = PassthroughSubject<any Error, Never>()
    private let _didPlayToEnd = PassthroughSubject<Void, Never>()
    private let _presentationSize = PassthroughSubject<CGSize, Never>()

    // MARK: - Combine 事件流

    public var statePublisher: AnyPublisher<PlaybackState, Never> { _state.eraseToAnyPublisher() }
    public var loadStatePublisher: AnyPublisher<LoadState, Never> { _loadState.eraseToAnyPublisher() }
    public var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> { _playTime.eraseToAnyPublisher() }
    public var bufferTimePublisher: AnyPublisher<TimeInterval, Never> { _bufferTime.eraseToAnyPublisher() }
    public var prepareToPlayPublisher: AnyPublisher<URL, Never> { _prepareToPlay.eraseToAnyPublisher() }
    public var readyToPlayPublisher: AnyPublisher<URL, Never> { _readyToPlay.eraseToAnyPublisher() }
    public var playFailedPublisher: AnyPublisher<any Error, Never> { _playFailed.eraseToAnyPublisher() }
    public var didPlayToEndPublisher: AnyPublisher<Void, Never> { _didPlayToEnd.eraseToAnyPublisher() }
    public var presentationSizePublisher: AnyPublisher<CGSize, Never> { _presentationSize.eraseToAnyPublisher() }

    // MARK: - 内部状态

    private var kvoManager = KVOManager()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var isBuffering = false
    private var isReadyToPlay = false

    // MARK: - 初始化

    public init() {}

    deinit {
        stop()
    }

    // MARK: - PlaybackEngine 方法

    public func prepareToPlay() {
        guard let url = assetURL else { return }
        initializePlayer(url: url)
    }

    public func reloadPlayer() {
        guard let url = assetURL else { return }
        stop()
        assetURL = url
    }

    public func play() {
        guard isPreparedToPlay else { return }
        player?.play()
        player?.rate = rate
        playbackState = .playing
    }

    public func pause() {
        player?.pause()
        playbackState = .paused
    }

    public func replay() {
        seekTime = 0
        Task {
            _ = await seek(to: 0)
            play()
        }
    }

    public func stop() {
        kvoManager.invalidate()
        removeTimeObserver()
        removeEndObserver()

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()

        player = nil
        playerItem = nil
        asset = nil
        playerLayer = nil

        isPreparedToPlay = false
        isBuffering = false
        isReadyToPlay = false
        currentTime = 0
        totalTime = 0
        bufferTime = 0
        playbackState = .stopped
        loadState = .unknown
    }

    public func seek(to time: TimeInterval) async -> Bool {
        guard let player, let item = playerItem else { return false }
        let timescale = item.asset.duration.timescale
        let cmTime = CMTime(seconds: time, preferredTimescale: timescale)

        return await withCheckedContinuation { continuation in
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                continuation.resume(returning: finished)
            }
        }
    }

    public func thumbnailImageAtCurrentTime() -> UIImage? {
        guard let asset else { return nil }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: currentTime, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - 内部方法

    private func initializePlayer(url: URL) {
        var options: [String: Any]?
        if let headers = requestHeaders {
            options = ["AVURLAssetHTTPHeaderFieldsKey": headers]
        }

        let newAsset = AVURLAsset(url: url, options: options)
        asset = newAsset

        let newItem = AVPlayerItem(asset: newAsset)
        newItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        playerItem = newItem

        let newPlayer: AVPlayer
        if let existing = player {
            existing.replaceCurrentItem(with: newItem)
            newPlayer = existing
        } else {
            newPlayer = AVPlayer(playerItem: newItem)
            player = newPlayer
        }
        newPlayer.automaticallyWaitsToMinimizeStalling = false

        let newLayer = AVPlayerLayer(player: newPlayer)
        playerLayer?.removeFromSuperlayer()
        playerLayer = newLayer
        renderView.layer.insertSublayer(newLayer, at: 0)
        updateVideoGravity()

        loadState = .prepare
        _prepareToPlay.send(url)

        setupKVO(for: newItem)
        addTimeObserver(player: newPlayer)
        addEndObserver(item: newItem)

        layoutPlayerLayer()
    }

    private func setupKVO(for item: AVPlayerItem) {
        kvoManager.invalidate()
        kvoManager = KVOManager()

        kvoManager.observe(item, keyPath: \.status) { [weak self] _, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                self.isReadyToPlay = true
                self.isPreparedToPlay = true
                self.totalTime = CMTimeGetSeconds(item.duration)
                self.loadState = .playable

                if self.seekTime > 0 {
                    Task { [weak self] in
                        guard let self else { return }
                        _ = await self.seek(to: self.seekTime)
                        self.seekTime = 0
                    }
                }

                if let url = self.assetURL {
                    self._readyToPlay.send(url)
                }

                if self.shouldAutoPlay {
                    self.play()
                }

            case .failed:
                self.playbackState = .failed
                if let error = item.error {
                    self._playFailed.send(error)
                }

            default:
                break
            }
        }

        kvoManager.observe(item, keyPath: \.isPlaybackBufferEmpty) { [weak self] _, _ in
            guard let self, item.isPlaybackBufferEmpty else { return }
            self.loadState = .stalled
            self.bufferingSomeSecond()
        }

        kvoManager.observe(item, keyPath: \.isPlaybackLikelyToKeepUp) { [weak self] _, _ in
            guard let self, item.isPlaybackLikelyToKeepUp else { return }
            self.loadState = [.playable, .playthroughOK]
            if self.isPlaying {
                self.player?.play()
            }
        }

        kvoManager.observe(item, keyPath: \.loadedTimeRanges) { [weak self] _, _ in
            self?.updateBufferTime()
        }

        kvoManager.observe(item, keyPath: \.presentationSize) { [weak self] _, _ in
            guard let self else { return }
            self.presentationSize = item.presentationSize
            self.renderView.presentationSize = item.presentationSize
        }
    }

    private func addTimeObserver(player: AVPlayer) {
        removeTimeObserver()
        let interval = CMTime(seconds: timeRefreshInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let item = self.playerItem else { return }
            let current = CMTimeGetSeconds(time)
            let total = CMTimeGetSeconds(item.duration)
            guard current >= 0, total > 0 else { return }
            self.currentTime = current
            self.totalTime = total
            self._playTime.send((current: current, total: total))
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func addEndObserver(item: AVPlayerItem) {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.playbackState = .stopped
            self._didPlayToEnd.send()
        }
    }

    private func removeEndObserver() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }

    private func updateBufferTime() {
        guard let item = playerItem,
              let range = item.loadedTimeRanges.first?.timeRangeValue
        else { return }
        let start = CMTimeGetSeconds(range.start)
        let duration = CMTimeGetSeconds(range.duration)
        let newBufferTime = start + duration
        bufferTime = newBufferTime
        _bufferTime.send(newBufferTime)
    }

    private func bufferingSomeSecond() {
        guard !isBuffering else { return }
        isBuffering = true
        player?.pause()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            self.isBuffering = false
            guard let item = self.playerItem else { return }
            if item.isPlaybackLikelyToKeepUp {
                if self.isPlaying {
                    self.player?.play()
                }
            } else {
                self.bufferingSomeSecond()
            }
        }
    }

    private func updateVideoGravity() {
        let gravity: AVLayerVideoGravity = switch scalingMode {
        case .none, .aspectFit: .resizeAspect
        case .aspectFill: .resizeAspectFill
        case .fill: .resize
        }
        playerLayer?.videoGravity = gravity
    }

    private func layoutPlayerLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = renderView.bounds
        CATransaction.commit()

        // 监听 renderView 布局变化
        renderView.layoutSubviewsCallback = { [weak self] in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.playerLayer?.frame = self?.renderView.bounds ?? .zero
            CATransaction.commit()
        }
    }
}
```

注意：`RenderView` 需要添加一个 `layoutSubviewsCallback` 回调。

- [ ] **Step 2: 更新 RenderView 添加布局回调**

在 `Sources/AlloyCore/RenderView.swift` 中添加：

```swift
// 在 RenderView 类中添加
/// 布局变化回调（内部使用）
var layoutSubviewsCallback: (() -> Void)?

override public func layoutSubviews() {
    super.layoutSubviews()
    layoutSubviewsCallback?()
}
```

- [ ] **Step 3: Verify build**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded

- [ ] **Step 4: Commit**

```bash
git add Sources/AlloyAVPlayer/AVPlayerManager.swift Sources/AlloyCore/RenderView.swift
git commit -m "实现 AVPlayerManager 播放引擎

- 完整的 PlaybackEngine 协议实现
- KVO 观察 AVPlayerItem 状态/缓冲/尺寸
- 周期性时间更新（addPeriodicTimeObserver）
- 缓冲管理策略（3s 延迟重试）
- 同步截图支持"
```

---

## Phase 7: AlloyControlView

由于 AlloyControlView 模块包含大量 UI 组件，以下将关键组件逐一实现。每个 Task 实现一个或一组相关组件。

### Task 22: Implement LoadingIndicator

**Files:**
- Create: `Sources/AlloyControlView/LoadingIndicator.swift`

- [ ] **Step 1: Implement LoadingIndicator**

`Sources/AlloyControlView/LoadingIndicator.swift`:
```swift
//
//  LoadingIndicator.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import AlloyCore
import UIKit

/// 加载动画指示器
///
/// 圆形旋转加载动画，支持 keep（持续旋转）和 fadeOut（渐隐）两种动画类型。
@MainActor
public final class LoadingIndicator: UIView {

    // MARK: - 属性

    /// 动画类型
    public var animationType: LoadingType = .keep

    /// 线条颜色
    public var lineColor: UIColor = .white {
        didSet { shapeLayer.strokeColor = lineColor.cgColor }
    }

    /// 线条宽度
    public var lineWidth: CGFloat = 1.5 {
        didSet { shapeLayer.lineWidth = lineWidth }
    }

    /// 停止时隐藏
    public var hidesWhenStopped = true

    /// 动画时长
    public var animationDuration: TimeInterval = 1.0

    /// 是否正在动画
    public private(set) var isAnimating = false

    // MARK: - 内部

    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = lineColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = lineWidth
        layer.lineCap = .round
        layer.strokeStart = 0.1
        layer.strokeEnd = 1.0
        return layer
    }()

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = hidesWhenStopped
        layer.addSublayer(shapeLayer)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        shapeLayer.path = path.cgPath
    }

    // MARK: - 方法

    /// 开始动画
    public func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        isHidden = false

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = animationDuration
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        shapeLayer.add(rotation, forKey: "rotation")

        if animationType == .fadeOut {
            addFadeOutAnimation()
        }
    }

    /// 停止动画
    public func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        shapeLayer.removeAllAnimations()
        if hidesWhenStopped { isHidden = true }
    }

    private func addFadeOutAnimation() {
        let strokeEnd = CABasicAnimation(keyPath: "strokeEnd")
        strokeEnd.fromValue = 0
        strokeEnd.toValue = 1.0
        strokeEnd.duration = animationDuration / 1.5
        strokeEnd.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let strokeStart = CABasicAnimation(keyPath: "strokeStart")
        strokeStart.fromValue = 0
        strokeStart.toValue = 0.25
        strokeStart.duration = animationDuration / 1.5
        strokeStart.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let strokeStartLate = CABasicAnimation(keyPath: "strokeStart")
        strokeStartLate.fromValue = 0.25
        strokeStartLate.toValue = 1.0
        strokeStartLate.beginTime = animationDuration / 1.5
        strokeStartLate.duration = animationDuration / 3
        strokeStartLate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let group = CAAnimationGroup()
        group.duration = animationDuration
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        group.animations = [strokeEnd, strokeStart, strokeStartLate]
        shapeLayer.add(group, forKey: "fadeOut")
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/LoadingIndicator.swift
git commit -m "实现 LoadingIndicator 加载动画

- CAShapeLayer 圆形旋转动画
- 支持 keep/fadeOut 两种动画类型"
```

---

### Task 23: Implement ProgressSlider

**Files:**
- Create: `Sources/AlloyControlView/ProgressSlider.swift`

- [ ] **Step 1: Implement ProgressSlider**

由于此文件较长，包含完整的自定义滑块实现（三层轨道 + 滑块 + 加载动画 + 拖拽/点击手势），核心结构如下：

`Sources/AlloyControlView/ProgressSlider.swift`:
```swift
//
//  ProgressSlider.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import AlloyCore
import Combine
import UIKit

/// 自定义进度滑块
///
/// 三层轨道结构：背景轨道 → 缓冲轨道 → 播放进度轨道 + 滑块按钮。
/// 支持拖拽、点击跳转、加载动画。
@MainActor
public final class ProgressSlider: UIView {

    // MARK: - 子视图

    /// 滑块按钮
    public private(set) var thumbButton = UIButton(type: .custom)

    // MARK: - 轨道外观

    public var maximumTrackTintColor: UIColor = UIColor(white: 0.5, alpha: 0.3) { didSet { bgTrack.backgroundColor = maximumTrackTintColor } }
    public var minimumTrackTintColor: UIColor = .white { didSet { progressTrack.backgroundColor = minimumTrackTintColor } }
    public var bufferTrackTintColor: UIColor = UIColor(white: 1.0, alpha: 0.5) { didSet { bufferTrack.backgroundColor = bufferTrackTintColor } }
    public var loadingTintColor: UIColor = .white { didSet { loadingBar.backgroundColor = loadingTintColor } }

    public var maximumTrackImage: UIImage?
    public var minimumTrackImage: UIImage?
    public var bufferTrackImage: UIImage?

    // MARK: - 值

    public var value: Float = 0 {
        didSet { setNeedsLayout() }
    }

    public var bufferValue: Float = 0 {
        didSet { setNeedsLayout() }
    }

    // MARK: - 配置

    public var isTapEnabled = true
    public var isAnimated = true
    public var trackHeight: CGFloat = 2
    public var trackCornerRadius: CGFloat = 1
    public var isThumbHidden = false { didSet { thumbButton.isHidden = isThumbHidden } }
    public private(set) var isDragging = false
    public private(set) var isForward = false
    public var thumbSize = CGSize(width: 19, height: 19)

    // MARK: - Delegate

    public weak var delegate: ProgressSliderDelegate?

    // MARK: - Combine Subjects

    private let _touchBegan = PassthroughSubject<Float, Never>()
    private let _valueChanged = PassthroughSubject<Float, Never>()
    private let _touchEnded = PassthroughSubject<Float, Never>()
    private let _tapped = PassthroughSubject<Float, Never>()

    public var touchBeganPublisher: AnyPublisher<Float, Never> { _touchBegan.eraseToAnyPublisher() }
    public var valueChangedPublisher: AnyPublisher<Float, Never> { _valueChanged.eraseToAnyPublisher() }
    public var touchEndedPublisher: AnyPublisher<Float, Never> { _touchEnded.eraseToAnyPublisher() }
    public var tappedPublisher: AnyPublisher<Float, Never> { _tapped.eraseToAnyPublisher() }

    // MARK: - 内部视图

    private let bgTrack = UIView()
    private let bufferTrack = UIView()
    private let progressTrack = UIView()
    private let loadingBar = UIView()
    private var previousValue: Float = 0

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        bgTrack.backgroundColor = maximumTrackTintColor
        bufferTrack.backgroundColor = bufferTrackTintColor
        progressTrack.backgroundColor = minimumTrackTintColor
        loadingBar.backgroundColor = loadingTintColor
        loadingBar.isHidden = true

        addSubview(bgTrack)
        addSubview(bufferTrack)
        addSubview(progressTrack)
        addSubview(loadingBar)
        addSubview(thumbButton)

        thumbButton.adjustsImageWhenHighlighted = false
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        thumbButton.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        bgTrack.isUserInteractionEnabled = true
        bgTrack.addGestureRecognizer(tap)
    }

    // MARK: - 布局

    override public func layoutSubviews() {
        super.layoutSubviews()
        let trackY = (bounds.height - trackHeight) / 2
        let trackWidth = bounds.width - thumbSize.width

        bgTrack.frame = CGRect(x: thumbSize.width / 2, y: trackY, width: trackWidth, height: trackHeight)
        bgTrack.layer.cornerRadius = trackCornerRadius

        let bufferWidth = trackWidth * CGFloat(min(max(bufferValue, 0), 1))
        bufferTrack.frame = CGRect(x: bgTrack.frame.minX, y: trackY, width: bufferWidth, height: trackHeight)
        bufferTrack.layer.cornerRadius = trackCornerRadius

        let clampedValue = CGFloat(min(max(value, 0), 1))
        let progressWidth = trackWidth * clampedValue
        progressTrack.frame = CGRect(x: bgTrack.frame.minX, y: trackY, width: progressWidth, height: trackHeight)
        progressTrack.layer.cornerRadius = trackCornerRadius

        let thumbX = bgTrack.frame.minX + progressWidth - thumbSize.width / 2
        let thumbY = (bounds.height - thumbSize.height) / 2
        thumbButton.frame = CGRect(x: thumbX, y: thumbY, width: thumbSize.width, height: thumbSize.height)
    }

    // MARK: - 手势处理

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let trackWidth = bounds.width - thumbSize.width
        guard trackWidth > 0 else { return }
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            isDragging = true
            previousValue = value
            _touchBegan.send(value)
            delegate?.sliderTouchBegan(self, value: value)
            UIView.animate(withDuration: 0.2) {
                self.thumbButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }

        case .changed:
            let delta = Float(translation.x / trackWidth)
            let newValue = min(max(previousValue + delta, 0), 1)
            isForward = newValue > value
            value = newValue
            _valueChanged.send(value)
            delegate?.sliderValueChanged(self, value: value)

        case .ended, .cancelled, .failed:
            isDragging = false
            _touchEnded.send(value)
            delegate?.sliderTouchEnded(self, value: value)
            UIView.animate(withDuration: 0.2) {
                self.thumbButton.transform = .identity
            }

        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isTapEnabled else { return }
        let point = gesture.location(in: bgTrack)
        let trackWidth = bgTrack.bounds.width
        guard trackWidth > 0 else { return }
        let newValue = Float(point.x / trackWidth)
        value = min(max(newValue, 0), 1)
        _tapped.send(value)
        delegate?.sliderTapped(self, value: value)
    }

    // MARK: - 公开方法

    /// 开始加载动画
    public func startLoading() {
        progressTrack.isHidden = true
        bufferTrack.isHidden = true
        thumbButton.isHidden = true
        loadingBar.isHidden = false

        let trackWidth = bgTrack.bounds.width
        loadingBar.frame = CGRect(x: bgTrack.frame.minX, y: bgTrack.frame.minY, width: 0, height: trackHeight)

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scaleX")
        scaleAnimation.fromValue = 0
        scaleAnimation.toValue = trackWidth / 10

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0

        let group = CAAnimationGroup()
        group.duration = 0.4
        group.repeatCount = .infinity
        group.animations = [scaleAnimation, opacityAnimation]
        loadingBar.layer.add(group, forKey: "loading")
    }

    /// 停止加载动画
    public func stopLoading() {
        loadingBar.layer.removeAllAnimations()
        loadingBar.isHidden = true
        progressTrack.isHidden = false
        bufferTrack.isHidden = false
        thumbButton.isHidden = isThumbHidden
    }

    /// 设置滑块图片
    public func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        thumbButton.setImage(image, for: state)
    }

    /// 设置滑块背景图片
    public func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        thumbButton.setBackgroundImage(image, for: state)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/ProgressSlider.swift
git commit -m "实现 ProgressSlider 自定义进度条

- 三层轨道（背景/缓冲/进度）+ 滑块
- 拖拽和点击手势
- 加载动画
- Combine + Delegate 双通道事件"
```

---

### Task 24: Implement BufferingIndicator and NetworkSpeedMonitor

**Files:**
- Create: `Sources/AlloyControlView/NetworkSpeedMonitor.swift`
- Create: `Sources/AlloyControlView/BufferingIndicator.swift`

- [ ] **Step 1: Implement NetworkSpeedMonitor**

`Sources/AlloyControlView/NetworkSpeedMonitor.swift`:
```swift
//
//  NetworkSpeedMonitor.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import Combine
import Foundation

/// 网速监控器
///
/// 通过读取系统网络接口统计数据计算上传/下载速度。
@MainActor
public final class NetworkSpeedMonitor {

    public private(set) var downloadSpeed: String = "0 KB/s"
    public private(set) var uploadSpeed: String = "0 KB/s"

    private let _speed = PassthroughSubject<(download: String, upload: String), Never>()
    public var speedPublisher: AnyPublisher<(download: String, upload: String), Never> { _speed.eraseToAnyPublisher() }

    private var timer: Timer?
    private var lastBytesReceived: UInt64 = 0
    private var lastBytesSent: UInt64 = 0

    public init() {}

    public func startMonitoring() {
        let (rx, tx) = getNetworkBytes()
        lastBytesReceived = rx
        lastBytesSent = tx
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        let (rx, tx) = getNetworkBytes()
        let rxDiff = rx > lastBytesReceived ? rx - lastBytesReceived : 0
        let txDiff = tx > lastBytesSent ? tx - lastBytesSent : 0
        lastBytesReceived = rx
        lastBytesSent = tx
        downloadSpeed = formatBytes(rxDiff)
        uploadSpeed = formatBytes(txDiff)
        _speed.send((download: downloadSpeed, upload: uploadSpeed))
    }

    private nonisolated func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var rx: UInt64 = 0
        var tx: UInt64 = 0
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            guard ptr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            let data = unsafeBitCast(ptr.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            rx += UInt64(data.pointee.ifi_ibytes)
            tx += UInt64(data.pointee.ifi_obytes)
        }
        return (rx, tx)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B/s" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB/s", Double(bytes) / 1024) }
        return String(format: "%.1f MB/s", Double(bytes) / 1024 / 1024)
    }
}
```

- [ ] **Step 2: Implement BufferingIndicator**

`Sources/AlloyControlView/BufferingIndicator.swift`:
```swift
//
//  BufferingIndicator.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 缓冲指示器
///
/// 组合 LoadingIndicator（菊花动画）+ 网速标签。
@MainActor
public final class BufferingIndicator: UIView {

    public private(set) var loadingView: LoadingIndicator = {
        let v = LoadingIndicator()
        v.lineWidth = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    public private(set) var speedLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(loadingView)
        addSubview(speedLabel)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            loadingView.widthAnchor.constraint(equalToConstant: 44),
            loadingView.heightAnchor.constraint(equalToConstant: 44),
            speedLabel.topAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: 4),
            speedLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func startAnimating() { loadingView.startAnimating(); isHidden = false }
    public func stopAnimating() { loadingView.stopAnimating(); isHidden = true }
}
```

- [ ] **Step 3: Commit**

```bash
git add Sources/AlloyControlView/NetworkSpeedMonitor.swift Sources/AlloyControlView/BufferingIndicator.swift
git commit -m "实现 BufferingIndicator 和 NetworkSpeedMonitor

- NetworkSpeedMonitor: 基于系统网络接口读取实时网速
- BufferingIndicator: 组合菊花动画 + 网速标签"
```

---

### Task 25: Implement VolumeAndBrightnessHUD

**Files:**
- Create: `Sources/AlloyControlView/VolumeAndBrightnessHUD.swift`

- [ ] **Step 1: Implement VolumeAndBrightnessHUD**

`Sources/AlloyControlView/VolumeAndBrightnessHUD.swift`:
```swift
//
//  VolumeAndBrightnessHUD.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import MediaPlayer
import UIKit

/// 音量/亮度浮层提示
@MainActor
public final class VolumeAndBrightnessHUD: UIView {

    public enum HUDType: Sendable { case volume, brightness }

    public private(set) var hudType: HUDType = .volume

    public private(set) var progressView: UIProgressView = {
        let v = UIProgressView(progressViewStyle: .default)
        v.trackTintColor = UIColor(white: 0.5, alpha: 0.3)
        v.progressTintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    public private(set) var iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.tintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var volumeView: MPVolumeView?
    private var hideTimer: Timer?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.7)
        layer.cornerRadius = 8
        clipsToBounds = true
        isHidden = true

        addSubview(iconImageView)
        addSubview(progressView)
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            progressView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func update(progress: CGFloat, type: HUDType) {
        hudType = type
        progressView.progress = Float(max(0, min(1, progress)))
        let config = UIImage.SymbolConfiguration(pointSize: 16)
        iconImageView.image = switch type {
        case .volume: UIImage(systemName: progress > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill", withConfiguration: config)
        case .brightness: UIImage(systemName: "sun.max.fill", withConfiguration: config)
        }
        show()
    }

    public func addSystemVolumeView() {
        guard volumeView == nil else { return }
        let v = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
        v.isHidden = false
        addSubview(v)
        volumeView = v
    }

    public func removeSystemVolumeView() {
        volumeView?.removeFromSuperview()
        volumeView = nil
    }

    private func show() {
        isHidden = false
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.isHidden = true }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/VolumeAndBrightnessHUD.swift
git commit -m "实现 VolumeAndBrightnessHUD 音量亮度提示

- SF Symbols 图标 + UIProgressView
- 自动 1.5s 后隐藏
- MPVolumeView 系统音量覆盖"
```

---

### Task 26: Implement CustomStatusBar

**Files:**
- Create: `Sources/AlloyControlView/CustomStatusBar.swift`

- [ ] **Step 1: Implement CustomStatusBar**

`Sources/AlloyControlView/CustomStatusBar.swift`:
```swift
//
//  CustomStatusBar.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import UIKit

/// 横屏自定义状态栏
///
/// 显示时间和电池信息，用于全屏模式下替代系统状态栏。
@MainActor
public final class CustomStatusBar: UIView {

    public var refreshInterval: TimeInterval = 3.0

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let batteryIcon: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var timer: Timer?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        UIDevice.current.isBatteryMonitoringEnabled = true
        addSubview(timeLabel)
        addSubview(batteryIcon)
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            batteryIcon.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 6),
            batteryIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            batteryIcon.widthAnchor.constraint(equalToConstant: 22),
            batteryIcon.heightAnchor.constraint(equalToConstant: 12),
        ])
        updateDisplay()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func startTimer() {
        stopTimer()
        updateDisplay()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateDisplay() }
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateDisplay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: Date())

        let level = UIDevice.current.batteryLevel
        let config = UIImage.SymbolConfiguration(pointSize: 12)
        batteryIcon.image = switch UIDevice.current.batteryState {
        case .charging, .full:
            UIImage(systemName: "battery.100.bolt", withConfiguration: config)
        default:
            UIImage(systemName: level > 0.5 ? "battery.75" : (level > 0.2 ? "battery.25" : "battery.0"), withConfiguration: config)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/CustomStatusBar.swift
git commit -m "实现 CustomStatusBar 横屏自定义状态栏

- 显示当前时间 + 电池图标
- 定时刷新"
```

---

### Task 27: Implement FloatingControlPanel

**Files:**
- Create: `Sources/AlloyControlView/FloatingControlPanel.swift`

- [ ] **Step 1: Implement FloatingControlPanel**

`Sources/AlloyControlView/FloatingControlPanel.swift`:
```swift
//
//  FloatingControlPanel.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import Combine
import UIKit

/// 小窗控制面板
///
/// 显示在浮窗上的简易控制层，包含关闭按钮。
@MainActor
public final class FloatingControlPanel: UIView {

    private let _closeTap = PassthroughSubject<Void, Never>()
    public var closeTapPublisher: AnyPublisher<Void, Never> { _closeTap.eraseToAnyPublisher() }

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func closeTapped() { _closeTap.send() }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/FloatingControlPanel.swift
git commit -m "实现 FloatingControlPanel 小窗控制面板

- 关闭按钮 + Combine Publisher"
```

---

### Task 28: Implement PortraitControlPanel

**Files:**
- Create: `Sources/AlloyControlView/PortraitControlPanel.swift`

- [ ] **Step 1: Implement PortraitControlPanel**

`Sources/AlloyControlView/PortraitControlPanel.swift`:
```swift
//
//  PortraitControlPanel.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import AlloyCore
import Combine
import UIKit

/// 竖屏控制面板
@MainActor
public final class PortraitControlPanel: UIView {

    // MARK: - 子视图

    public private(set) var topToolBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    public private(set) var bottomToolBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    public private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public private(set) var playPauseButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    public private(set) var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public private(set) var slider: ProgressSlider = {
        let v = ProgressSlider()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    public private(set) var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public private(set) var fullScreenButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 14)
        btn.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 属性

    public weak var player: Player?
    public var shouldSeekToPlay = false
    public var fullScreenMode: FullScreenMode = .automatic

    // MARK: - Combine

    private let _sliderValueChanging = PassthroughSubject<(value: CGFloat, isForward: Bool), Never>()
    private let _sliderValueChanged = PassthroughSubject<CGFloat, Never>()
    public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never> { _sliderValueChanging.eraseToAnyPublisher() }
    public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never> { _sliderValueChanged.eraseToAnyPublisher() }

    // MARK: - 内部

    private var cancellables = Set<AnyCancellable>()
    private var isControlVisible = false

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupSlider()
        setupActions()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        // 顶部工具栏
        let topGradient = GradientView()
        topGradient.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topGradient)
        addSubview(topToolBar)
        topToolBar.addSubview(titleLabel)

        // 底部工具栏
        let bottomGradient = GradientView(isTopToBottom: false)
        bottomGradient.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomGradient)
        addSubview(bottomToolBar)
        bottomToolBar.addSubview(playPauseButton)
        bottomToolBar.addSubview(currentTimeLabel)
        bottomToolBar.addSubview(slider)
        bottomToolBar.addSubview(totalTimeLabel)
        bottomToolBar.addSubview(fullScreenButton)

        NSLayoutConstraint.activate([
            topGradient.topAnchor.constraint(equalTo: topAnchor),
            topGradient.leadingAnchor.constraint(equalTo: leadingAnchor),
            topGradient.trailingAnchor.constraint(equalTo: trailingAnchor),
            topGradient.heightAnchor.constraint(equalToConstant: 80),

            topToolBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            topToolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topToolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topToolBar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: topToolBar.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),

            bottomGradient.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomGradient.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomGradient.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomGradient.heightAnchor.constraint(equalToConstant: 80),

            bottomToolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            bottomToolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomToolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomToolBar.heightAnchor.constraint(equalToConstant: 44),

            playPauseButton.leadingAnchor.constraint(equalTo: bottomToolBar.leadingAnchor, constant: 12),
            playPauseButton.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 30),
            playPauseButton.heightAnchor.constraint(equalToConstant: 30),

            currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 48),

            fullScreenButton.trailingAnchor.constraint(equalTo: bottomToolBar.trailingAnchor, constant: -12),
            fullScreenButton.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            fullScreenButton.widthAnchor.constraint(equalToConstant: 30),
            fullScreenButton.heightAnchor.constraint(equalToConstant: 30),

            totalTimeLabel.trailingAnchor.constraint(equalTo: fullScreenButton.leadingAnchor, constant: -8),
            totalTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            totalTimeLabel.widthAnchor.constraint(equalToConstant: 48),

            slider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 4),
            slider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -4),
            slider.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            slider.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    private func setupSlider() {
        slider.valueChangedPublisher.sink { [weak self] value in
            guard let self else { return }
            self._sliderValueChanging.send((value: CGFloat(value), isForward: self.slider.isForward))
        }.store(in: &cancellables)

        slider.touchEndedPublisher.sink { [weak self] value in
            self?._sliderValueChanged.send(CGFloat(value))
        }.store(in: &cancellables)
    }

    private func setupActions() {
        playPauseButton.addTarget(self, action: #selector(playOrPauseTapped), for: .touchUpInside)
        fullScreenButton.addTarget(self, action: #selector(fullScreenTapped), for: .touchUpInside)
    }

    @objc private func playOrPauseTapped() { playOrPause() }

    @objc private func fullScreenTapped() {
        guard let player else { return }
        Task { await player.enterFullScreen(!player.isFullScreen, animated: true) }
    }

    // MARK: - 公开方法

    public func resetControlView() {
        slider.value = 0
        slider.bufferValue = 0
        currentTimeLabel.text = "00:00"
        totalTimeLabel.text = "00:00"
        titleLabel.text = nil
    }

    public func showControlView() {
        isControlVisible = true
        UIView.animate(withDuration: 0.25) {
            self.topToolBar.alpha = 1
            self.bottomToolBar.alpha = 1
        }
    }

    public func hideControlView() {
        isControlVisible = false
        UIView.animate(withDuration: 0.25) {
            self.topToolBar.alpha = 0
            self.bottomToolBar.alpha = 0
        }
    }

    public func show(title: String?, fullScreenMode: FullScreenMode) {
        titleLabel.text = title
        self.fullScreenMode = fullScreenMode
    }

    public func updatePlayButtonState(isPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 16)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        playPauseButton.tintColor = .white
    }

    public func updateTime(current: TimeInterval, total: TimeInterval) {
        currentTimeLabel.text = TimeFormatter.string(from: Int(current))
        totalTimeLabel.text = TimeFormatter.string(from: Int(total))
        if !slider.isDragging, total > 0 {
            slider.value = Float(current / total)
        }
    }

    public func updateBufferTime(_ bufferTime: TimeInterval) {
        guard let player, player.totalTime > 0 else { return }
        slider.bufferValue = Float(bufferTime / player.totalTime)
    }

    public func updateSlider(value: CGFloat, currentTimeString: String) {
        slider.value = Float(value)
        currentTimeLabel.text = currentTimeString
    }

    public func sliderDidEndChanging() {
        // 恢复定时隐藏等
    }

    public func playOrPause() {
        guard let player else { return }
        if player.engine.isPlaying {
            player.engine.pause()
        } else {
            player.engine.play()
        }
    }

    func shouldRespondToGesture(at point: CGPoint, type: GestureType, touch: UITouch) -> Bool {
        let bottomRect = bottomToolBar.frame
        let topRect = topToolBar.frame
        // 工具栏区域内的触摸不响应播放器手势
        if isControlVisible, (bottomRect.contains(point) || topRect.contains(point)) {
            return false
        }
        return true
    }
}

// MARK: - GradientView（内部辅助）

private final class GradientView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let isTopToBottom: Bool

    init(isTopToBottom: Bool = true) {
        self.isTopToBottom = isTopToBottom
        super.init(frame: .zero)
        layer.addSublayer(gradientLayer)
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(isTopToBottom ? 0.6 : 0).cgColor,
            UIColor.black.withAlphaComponent(isTopToBottom ? 0 : 0.6).cgColor,
        ]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/PortraitControlPanel.swift
git commit -m "实现 PortraitControlPanel 竖屏控制面板

- 顶部/底部工具栏 + 渐变背景
- 播放/暂停、进度条、时间标签、全屏按钮
- Combine 事件流 + Auto Layout"
```

---

### Task 29: Implement LandscapeControlPanel

**Files:**
- Create: `Sources/AlloyControlView/LandscapeControlPanel.swift`

- [ ] **Step 1: Implement LandscapeControlPanel**

`Sources/AlloyControlView/LandscapeControlPanel.swift`:
```swift
//
//  LandscapeControlPanel.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import AlloyCore
import Combine
import UIKit

/// 横屏控制面板
///
/// 相比竖屏增加了返回按钮和锁屏按钮。
@MainActor
public final class LandscapeControlPanel: UIView {

    // MARK: - 子视图

    public private(set) var topToolBar: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    public private(set) var bottomToolBar: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()

    public private(set) var backButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    public private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public private(set) var playPauseButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    public private(set) var currentTimeLabel: UILabel = {
        let l = UILabel(); l.textColor = .white; l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        l.text = "00:00"; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    public private(set) var slider: ProgressSlider = { let v = ProgressSlider(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()

    public private(set) var totalTimeLabel: UILabel = {
        let l = UILabel(); l.textColor = .white; l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        l.text = "00:00"; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    public private(set) var lockButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 18)
        btn.setImage(UIImage(systemName: "lock.open.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 属性

    public weak var player: Player?
    public var shouldSeekToPlay = false
    public var shouldShowCustomStatusBar = false
    public var fullScreenMode: FullScreenMode = .automatic

    // MARK: - Combine

    private let _sliderValueChanging = PassthroughSubject<(value: CGFloat, isForward: Bool), Never>()
    private let _sliderValueChanged = PassthroughSubject<CGFloat, Never>()
    private let _backButtonTap = PassthroughSubject<Void, Never>()
    public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never> { _sliderValueChanging.eraseToAnyPublisher() }
    public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never> { _sliderValueChanged.eraseToAnyPublisher() }
    public var backButtonTapPublisher: AnyPublisher<Void, Never> { _backButtonTap.eraseToAnyPublisher() }

    private var cancellables = Set<AnyCancellable>()
    private var isControlVisible = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupSlider()
        setupActions()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        addSubview(topToolBar)
        addSubview(bottomToolBar)
        addSubview(lockButton)

        topToolBar.addSubview(backButton)
        topToolBar.addSubview(titleLabel)
        bottomToolBar.addSubview(playPauseButton)
        bottomToolBar.addSubview(currentTimeLabel)
        bottomToolBar.addSubview(slider)
        bottomToolBar.addSubview(totalTimeLabel)

        NSLayoutConstraint.activate([
            topToolBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            topToolBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            topToolBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            topToolBar.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: topToolBar.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: topToolBar.centerYAnchor),

            bottomToolBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            bottomToolBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            bottomToolBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            bottomToolBar.heightAnchor.constraint(equalToConstant: 44),

            playPauseButton.leadingAnchor.constraint(equalTo: bottomToolBar.leadingAnchor, constant: 12),
            playPauseButton.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 30),
            playPauseButton.heightAnchor.constraint(equalToConstant: 30),

            currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 52),

            totalTimeLabel.trailingAnchor.constraint(equalTo: bottomToolBar.trailingAnchor, constant: -12),
            totalTimeLabel.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            totalTimeLabel.widthAnchor.constraint(equalToConstant: 52),

            slider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 4),
            slider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -4),
            slider.centerYAnchor.constraint(equalTo: bottomToolBar.centerYAnchor),
            slider.heightAnchor.constraint(equalToConstant: 30),

            lockButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            lockButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            lockButton.widthAnchor.constraint(equalToConstant: 40),
            lockButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func setupSlider() {
        slider.valueChangedPublisher.sink { [weak self] value in
            guard let self else { return }
            self._sliderValueChanging.send((value: CGFloat(value), isForward: self.slider.isForward))
        }.store(in: &cancellables)
        slider.touchEndedPublisher.sink { [weak self] value in
            self?._sliderValueChanged.send(CGFloat(value))
        }.store(in: &cancellables)
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playOrPauseTapped), for: .touchUpInside)
        lockButton.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
    }

    @objc private func backTapped() { _backButtonTap.send() }

    @objc private func playOrPauseTapped() {
        guard let player else { return }
        if player.engine.isPlaying { player.engine.pause() } else { player.engine.play() }
    }

    @objc private func lockTapped() {
        guard let player else { return }
        player.isScreenLocked.toggle()
        let config = UIImage.SymbolConfiguration(pointSize: 18)
        let name = player.isScreenLocked ? "lock.fill" : "lock.open.fill"
        lockButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
    }

    // MARK: - 公开方法（与 PortraitControlPanel 对称）

    public func resetControlView() {
        slider.value = 0; slider.bufferValue = 0
        currentTimeLabel.text = "00:00"; totalTimeLabel.text = "00:00"; titleLabel.text = nil
    }

    public func showControlView() { isControlVisible = true; UIView.animate(withDuration: 0.25) { self.topToolBar.alpha = 1; self.bottomToolBar.alpha = 1; self.lockButton.alpha = 1 } }
    public func hideControlView() { isControlVisible = false; UIView.animate(withDuration: 0.25) { self.topToolBar.alpha = 0; self.bottomToolBar.alpha = 0 } }

    public func show(title: String?, fullScreenMode: FullScreenMode) { titleLabel.text = title; self.fullScreenMode = fullScreenMode }

    public func updatePlayButtonState(isPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 16)
        playPauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill", withConfiguration: config), for: .normal)
        playPauseButton.tintColor = .white
    }

    public func updateTime(current: TimeInterval, total: TimeInterval) {
        currentTimeLabel.text = TimeFormatter.string(from: Int(current))
        totalTimeLabel.text = TimeFormatter.string(from: Int(total))
        if !slider.isDragging, total > 0 { slider.value = Float(current / total) }
    }

    public func updateBufferTime(_ bufferTime: TimeInterval) {
        guard let player, player.totalTime > 0 else { return }
        slider.bufferValue = Float(bufferTime / player.totalTime)
    }

    public func updateSlider(value: CGFloat, currentTimeString: String) { slider.value = Float(value); currentTimeLabel.text = currentTimeString }
    public func sliderDidEndChanging() {}

    public func updatePresentationSize(_ size: CGSize) {}
    public func updateOrientation(_ observer: OrientationManager) {}

    func shouldRespondToGesture(at point: CGPoint, type: GestureType, touch: UITouch) -> Bool {
        if isControlVisible, (bottomToolBar.frame.contains(point) || topToolBar.frame.contains(point)) { return false }
        return true
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/AlloyControlView/LandscapeControlPanel.swift
git commit -m "实现 LandscapeControlPanel 横屏控制面板

- 返回按钮 + 锁屏按钮
- 与 PortraitControlPanel 对称的进度控制
- Combine 事件流"
```

---

### Task 30: Implement DefaultControlOverlay

**Files:**
- Create: `Sources/AlloyControlView/DefaultControlOverlay.swift`

- [ ] **Step 1: Implement DefaultControlOverlay**

这是 AlloyControlView 模块的核心组装类，将所有子组件组合并实现 `ControlOverlay` 协议。由于代码量大，此处提供完整结构和关键逻辑：

`Sources/AlloyControlView/DefaultControlOverlay.swift`:
```swift
//
//  DefaultControlOverlay.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

import AlloyCore
import Combine
import UIKit

/// 默认控制层
///
/// 组装竖屏面板、横屏面板、缓冲指示器、进度条等所有子组件，
/// 实现 ControlOverlay 协议的完整控制逻辑。
@MainActor
public final class DefaultControlOverlay: UIView, ControlOverlay {

    // MARK: - ControlOverlay

    public weak var player: Player?

    // MARK: - 子视图

    public private(set) var portraitPanel = PortraitControlPanel()
    public private(set) var landscapePanel = LandscapeControlPanel()
    public private(set) var bufferingIndicator = BufferingIndicator()
    public private(set) var bottomProgress: ProgressSlider = {
        let v = ProgressSlider()
        v.trackHeight = 1
        v.isThumbHidden = true
        v.isTapEnabled = false
        v.maximumTrackTintColor = .clear
        v.minimumTrackTintColor = .white
        v.bufferTrackTintColor = UIColor(white: 1, alpha: 0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    public private(set) var coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    public private(set) var backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    public private(set) var backgroundEffectView: UIVisualEffectView?
    public private(set) var floatingPanel = FloatingControlPanel()
    public private(set) var failButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("加载失败，点击重试", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.isHidden = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // 快进 HUD
    public private(set) var seekHUDView: UIView = { let v = UIView(); v.backgroundColor = UIColor(white: 0, alpha: 0.7); v.layer.cornerRadius = 8; v.isHidden = true; v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    public private(set) var seekTimeLabel = UILabel()
    public private(set) var seekProgressView = ProgressSlider()
    public private(set) var seekDirectionImageView = UIImageView()

    // MARK: - 配置

    public var isSeekHUDAnimated = true
    public var isBackgroundEffectVisible = false
    public var shouldSeekToPlay = true
    public var isControlViewVisible: Bool { isShowing }
    public var autoHideInterval: TimeInterval = 2.5
    public var autoFadeInterval: TimeInterval = 0.25
    public var shouldShowControlOnHorizontalPan = true
    public var shouldShowControlOnPrepare = false
    public var shouldShowLoadingOnPrepare = true
    public var isCustomDisablePanMovingDirection = false
    public var shouldShowCustomStatusBar = false
    public var fullScreenMode: FullScreenMode = .automatic

    // MARK: - Combine

    private let _backButtonTap = PassthroughSubject<Void, Never>()
    private let _controlVisibility = PassthroughSubject<Bool, Never>()
    public var backButtonTapPublisher: AnyPublisher<Void, Never> { _backButtonTap.eraseToAnyPublisher() }
    public var controlVisibilityPublisher: AnyPublisher<Bool, Never> { _controlVisibility.eraseToAnyPublisher() }

    // MARK: - 内部状态

    private var isShowing = false
    private var sumTime: TimeInterval = 0
    private var autoHideWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    private var volumeBrightnessHUD = VolumeAndBrightnessHUD()

    // MARK: - 初始化

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupBindings()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        // 背景
        addSubview(backgroundImageView)
        addSubview(coverImageView)

        // 控制面板
        portraitPanel.translatesAutoresizingMaskIntoConstraints = false
        landscapePanel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(portraitPanel)
        addSubview(landscapePanel)
        landscapePanel.isHidden = true

        // 缓冲、失败
        bufferingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bufferingIndicator)
        addSubview(failButton)

        // 底部进度
        addSubview(bottomProgress)

        // 快进 HUD
        addSubview(seekHUDView)

        // 音量亮度
        volumeBrightnessHUD.translatesAutoresizingMaskIntoConstraints = false
        addSubview(volumeBrightnessHUD)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            portraitPanel.topAnchor.constraint(equalTo: topAnchor),
            portraitPanel.leadingAnchor.constraint(equalTo: leadingAnchor),
            portraitPanel.trailingAnchor.constraint(equalTo: trailingAnchor),
            portraitPanel.bottomAnchor.constraint(equalTo: bottomAnchor),

            landscapePanel.topAnchor.constraint(equalTo: topAnchor),
            landscapePanel.leadingAnchor.constraint(equalTo: leadingAnchor),
            landscapePanel.trailingAnchor.constraint(equalTo: trailingAnchor),
            landscapePanel.bottomAnchor.constraint(equalTo: bottomAnchor),

            bufferingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            bufferingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            bufferingIndicator.widthAnchor.constraint(equalToConstant: 80),
            bufferingIndicator.heightAnchor.constraint(equalToConstant: 80),

            failButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            failButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            bottomProgress.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomProgress.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomProgress.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomProgress.heightAnchor.constraint(equalToConstant: 2),

            seekHUDView.centerXAnchor.constraint(equalTo: centerXAnchor),
            seekHUDView.centerYAnchor.constraint(equalTo: centerYAnchor),
            seekHUDView.widthAnchor.constraint(equalToConstant: 140),
            seekHUDView.heightAnchor.constraint(equalToConstant: 80),

            volumeBrightnessHUD.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            volumeBrightnessHUD.centerXAnchor.constraint(equalTo: centerXAnchor),
            volumeBrightnessHUD.widthAnchor.constraint(equalToConstant: 200),
            volumeBrightnessHUD.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    private func setupBindings() {
        landscapePanel.backButtonTapPublisher.sink { [weak self] in
            guard let self, let player = self.player else { return }
            Task { await player.enterFullScreen(false, animated: true) }
            self._backButtonTap.send()
        }.store(in: &cancellables)

        failButton.addTarget(self, action: #selector(failButtonTapped), for: .touchUpInside)
    }

    @objc private func failButtonTapped() { player?.engine.reloadPlayer() }

    // MARK: - 公开方法

    public func show(title: String?, coverURL: URL? = nil, placeholderImage: UIImage? = nil, fullScreenMode: FullScreenMode) {
        self.fullScreenMode = fullScreenMode
        portraitPanel.show(title: title, fullScreenMode: fullScreenMode)
        landscapePanel.show(title: title, fullScreenMode: fullScreenMode)
        if let placeholder = placeholderImage { coverImageView.image = placeholder }
    }

    public func show(title: String?, coverImage: UIImage?, fullScreenMode: FullScreenMode) {
        self.fullScreenMode = fullScreenMode
        portraitPanel.show(title: title, fullScreenMode: fullScreenMode)
        landscapePanel.show(title: title, fullScreenMode: fullScreenMode)
        if let image = coverImage { coverImageView.image = image }
    }

    public func resetControlView() {
        portraitPanel.resetControlView()
        landscapePanel.resetControlView()
        bottomProgress.value = 0; bottomProgress.bufferValue = 0
        coverImageView.isHidden = false
        failButton.isHidden = true
        seekHUDView.isHidden = true
        bufferingIndicator.stopAnimating()
    }

    // MARK: - 显示/隐藏控制层

    private func showControlView() {
        isShowing = true
        _controlVisibility.send(true)
        bottomProgress.isHidden = true
        if player?.isFullScreen == true {
            landscapePanel.showControlView()
        } else {
            portraitPanel.showControlView()
        }
        scheduleAutoHide()
    }

    private func hideControlView() {
        isShowing = false
        _controlVisibility.send(false)
        bottomProgress.isHidden = false
        portraitPanel.hideControlView()
        landscapePanel.hideControlView()
        cancelAutoHide()
    }

    private func scheduleAutoHide() {
        cancelAutoHide()
        let work = DispatchWorkItem { [weak self] in self?.hideControlView() }
        autoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHideInterval, execute: work)
    }

    private func cancelAutoHide() {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
    }

    // MARK: - ControlOverlay 回调

    public func player(_ player: Player, didChangePlaybackState state: PlaybackState) {
        portraitPanel.updatePlayButtonState(isPlaying: state == .playing)
        landscapePanel.updatePlayButtonState(isPlaying: state == .playing)

        switch state {
        case .playing:
            failButton.isHidden = true
            bufferingIndicator.stopAnimating()
        case .failed:
            failButton.isHidden = false
            bufferingIndicator.stopAnimating()
        default:
            break
        }
    }

    public func player(_ player: Player, didChangeLoadState state: LoadState) {
        if state.contains(.playthroughOK) || state.contains(.playable) {
            coverImageView.isHidden = true
            bufferingIndicator.stopAnimating()
        }
        if state.contains(.stalled), player.engine.isPlaying {
            bufferingIndicator.startAnimating()
        }
        if state.contains(.prepare) {
            if shouldShowLoadingOnPrepare { bufferingIndicator.startAnimating() }
            if shouldShowControlOnPrepare { showControlView() }
        }
    }

    public func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {
        portraitPanel.updateTime(current: currentTime, total: totalTime)
        landscapePanel.updateTime(current: currentTime, total: totalTime)
        if !portraitPanel.slider.isDragging, totalTime > 0 {
            bottomProgress.value = Float(currentTime / totalTime)
        }
    }

    public func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval) {
        portraitPanel.updateBufferTime(bufferTime)
        landscapePanel.updateBufferTime(bufferTime)
        if player.totalTime > 0 {
            bottomProgress.bufferValue = Float(bufferTime / player.totalTime)
        }
    }

    public func player(_ player: Player, willChangeOrientation observer: OrientationManager) {
        // 提前切换面板
    }

    public func player(_ player: Player, didChangeOrientation observer: OrientationManager) {
        let isLandscape = player.isFullScreen && fullScreenMode != .portrait
        portraitPanel.isHidden = isLandscape
        landscapePanel.isHidden = !isLandscape
    }

    // MARK: - 手势回调

    public func gestureSingleTapped(_ gesture: GestureManager) {
        if isShowing { hideControlView() } else { showControlView() }
    }

    public func gestureDoubleTapped(_ gesture: GestureManager) {
        if player?.isFullScreen == true {
            landscapePanel.playOrPause()
        } else {
            portraitPanel.playOrPause()
        }
    }

    public func gestureBeganPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation) {
        if direction == .horizontal {
            sumTime = player?.currentTime ?? 0
        }
    }

    public func gestureChangedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation, velocity: CGPoint) {
        guard let player else { return }
        switch direction {
        case .horizontal:
            sumTime += TimeInterval(velocity.x) / 200
            sumTime = max(0, min(sumTime, player.totalTime))
            let progress = player.totalTime > 0 ? CGFloat(sumTime / player.totalTime) : 0
            let timeString = TimeFormatter.string(from: Int(sumTime))
            portraitPanel.updateSlider(value: progress, currentTimeString: timeString)
            landscapePanel.updateSlider(value: progress, currentTimeString: timeString)
        case .vertical:
            if location == .left {
                player.brightness -= Float(velocity.y) / 10000
                volumeBrightnessHUD.update(progress: CGFloat(player.brightness), type: .brightness)
            } else {
                player.volume -= Float(velocity.y) / 10000
                volumeBrightnessHUD.update(progress: CGFloat(player.volume), type: .volume)
            }
        default: break
        }
    }

    public func gestureEndedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation) {
        guard direction == .horizontal, let player else { return }
        Task {
            _ = await player.seek(to: sumTime)
            if shouldSeekToPlay { player.engine.play() }
            portraitPanel.sliderDidEndChanging()
            landscapePanel.sliderDidEndChanging()
        }
    }

    public func gesturePinched(_ gesture: GestureManager, scale: Float) {
        player?.engine.scalingMode = scale > 1 ? .aspectFill : .aspectFit
    }

    public func gestureTriggerCondition(_ gesture: GestureManager, type: GestureType, recognizer: UIGestureRecognizer, touch: UITouch) -> Bool {
        let point = touch.location(in: self)
        if player?.isFullScreen == true {
            return landscapePanel.shouldRespondToGesture(at: point, type: type, touch: touch)
        }
        return portraitPanel.shouldRespondToGesture(at: point, type: type, touch: touch)
    }
}
```

- [ ] **Step 2: Verify build**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
git add Sources/AlloyControlView/DefaultControlOverlay.swift
git commit -m "实现 DefaultControlOverlay 默认控制层

- 组装所有子组件（竖屏/横屏面板、缓冲、进度条等）
- 完整 ControlOverlay 协议实现
- 控制层显示/隐藏状态机 + 自动延迟隐藏
- 手势回调（单击切换、双击播放暂停、滑动调节进度/音量/亮度、捏合缩放）"
```

---

### Task 31: Resource files and AlloyControlView build verification

**Files:**
- Create: `Sources/AlloyControlView/Resources/.gitkeep` (如尚未创建)

- [ ] **Step 1: 确保资源目录存在**

```bash
touch Sources/AlloyControlView/Resources/.gitkeep
```

注意：当前阶段使用 SF Symbols 作为图标，无需打包自定义图片资源。后续可根据设计需求添加自定义资源文件到 `Resources/` 目录。

- [ ] **Step 2: 全模块编译验证**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "AlloyControlView 模块编译验证通过

- 所有控件实现完成
- SF Symbols 替代自定义图片资源"
```

---

## Phase 8: AlloyPlayer Umbrella & Final Verification

### Task 32: Final build verification and cleanup

**Files:**
- Modify: `Sources/AlloyPlayer/AlloyPlayer.swift` (已在 Task 1 创建)
- Remove: `Sources/AlloyCore/AlloyCore.swift` (占位文件)
- Remove: `Sources/AlloyAVPlayer/AlloyAVPlayer.swift` (占位文件)
- Remove: `Sources/AlloyControlView/AlloyControlView.swift` (占位文件)

- [ ] **Step 1: 清理占位文件**

```bash
rm -f Sources/AlloyCore/AlloyCore.swift
rm -f Sources/AlloyAVPlayer/AlloyAVPlayer.swift
rm -f Sources/AlloyControlView/AlloyControlView.swift
rm -f Sources/AlloyCore/.gitkeep
rm -f Sources/AlloyAVPlayer/.gitkeep
rm -f Sources/AlloyControlView/.gitkeep
rm -f Tests/AlloyCoreTests/.gitkeep
rm -f Tests/AlloyAVPlayerTests/.gitkeep
rm -f Tests/AlloyControlViewTests/.gitkeep
```

- [ ] **Step 2: 验证 AlloyPlayer umbrella 模块**

确认 `Sources/AlloyPlayer/AlloyPlayer.swift` 内容为：
```swift
//
//  AlloyPlayer.swift
//  AlloyPlayer
//
//  Created by Sun on 2026/4/14.
//

@_exported import AlloyCore
@_exported import AlloyAVPlayer
@_exported import AlloyControlView
```

- [ ] **Step 3: 全量构建验证**

Run: `swift build 2>&1 | tail -10`
Expected: Build succeeded

- [ ] **Step 4: 运行全部测试**

Run: `swift test 2>&1 | tail -15`
Expected: All tests passed

- [ ] **Step 5: 最终提交**

```bash
git add -A
git commit -m "清理占位文件，完成 AlloyPlayer 框架搭建

- 移除 Phase 1 创建的占位文件
- 验证全量构建通过
- 验证所有测试通过"
```
