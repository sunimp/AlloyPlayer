# AlloyPlayer

[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-F05138.svg)](https://swift.org)
[![Platform iOS 15.0+](https://img.shields.io/badge/Platform-iOS%2015.0+-007AFF.svg)](https://developer.apple.com/ios/)
[![License MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)

一个现代的纯 Swift 视频播放器框架。基于 [ZFPlayer](https://github.com/renzifeng/ZFPlayer) 的完整功能重写，采用 Swift 6 并发、Combine 事件流和模块化 SPM 架构。

## 特性

- 协议驱动的插件架构（可自由替换引擎/UI）
- 完整的竖屏和横屏全屏支持
- ScrollView/TableView/CollectionView 列表播放
- 丰富的手势支持（单击、双击、拖动、捏合、长按）
- 可插拔的 `PlaybackEngine` 协议（内置 AVPlayer，可自定义）
- 可自定义的 `ControlOverlay` 协议（内置 `DefaultControlOverlay`）
- 网络可达性监控（WiFi / 2G / 3G / 4G / 5G）
- 列表播放的浮动画中画窗口
- 所有事件均提供 Combine 发布者
- Swift 6 严格并发安全

## 系统要求

- iOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## 安装

### Swift Package Manager

**方式一 — 完整框架（推荐）：**

```swift
dependencies: [
    .package(url: "https://github.com/nicklasundell/AlloyPlayer.git", from: "0.1.0")
]

// 在你的 target 中：
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyPlayer", package: "AlloyPlayer")
])
```

**方式二 — Core + AVPlayer 引擎（不含默认 UI）：**

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyCore", package: "AlloyPlayer"),
    .product(name: "AlloyAVPlayer", package: "AlloyPlayer"),
])
```

**方式三 — 仅 Core（自行提供引擎和 UI）：**

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyCore", package: "AlloyPlayer")
])
```

**方式四 — 单独模块：**

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyCore", package: "AlloyPlayer"),
    .product(name: "AlloyAVPlayer", package: "AlloyPlayer"),
    .product(name: "AlloyControlView", package: "AlloyPlayer"),
])
```

## 快速开始

### 基本播放

```swift
import AlloyPlayer

class PlayerViewController: UIViewController {
    private var player: Player!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. 创建容器视图
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 220))
        view.addSubview(containerView)

        // 2. 使用 AVPlayer 引擎创建播放器
        let engine = AVPlayerManager()
        player = Player(engine: engine, containerView: containerView)

        // 3. 设置默认控制层
        player.controlOverlay = DefaultControlOverlay()

        // 4. 设置视频 URL，自动开始播放
        player.assetURL = URL(string: "https://example.com/video.mp4")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.isViewControllerDisappear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.isViewControllerDisappear = false
    }
}
```

### 列表播放（TableView）

```swift
import AlloyPlayer

class ListPlayerViewController: UIViewController, UITableViewDelegate {
    private var player: Player!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let engine = AVPlayerManager()
        // 使用 scrollView 和容器视图 tag 初始化
        player = Player(scrollView: tableView, engine: engine, containerViewTag: 100)
        player.controlOverlay = DefaultControlOverlay()

        // 配置列表播放 URL（按 section 分组）
        player.sectionAssetURLs = [
            [
                URL(string: "https://example.com/video1.mp4")!,
                URL(string: "https://example.com/video2.mp4")!,
            ]
        ]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player.playTheIndexPath(indexPath, scrollToTop: true)
    }
}
```

### 自定义控制层

```swift
import AlloyCore

class MinimalOverlay: UIView, ControlOverlay {
    var player: Player?

    func gestureSingleTapped(_ gesture: GestureManager) {
        guard let player else { return }
        player.engine.isPlaying ? player.engine.pause() : player.engine.play()
    }

    func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {
        // 更新自定义时间标签
    }

    func player(_ player: Player, didChangePlaybackState state: PlaybackState) {
        // 更新播放/暂停按钮
    }
}
```

### 自定义播放引擎

```swift
import AlloyCore
import Combine

class CustomEngine: PlaybackEngine {
    var renderView = RenderView()
    var playbackState: PlaybackState = .unknown
    var loadState: LoadState = .unknown
    // ... 实现所有协议要求

    var statePublisher: AnyPublisher<PlaybackState, Never> { /* ... */ }
    // ... 实现所有发布者

    func prepareToPlay() { /* ... */ }
    func play() { /* ... */ }
    func pause() { /* ... */ }
    func stop() { /* ... */ }
    func seek(to time: TimeInterval) async -> Bool { /* ... */ }
    // ... 实现其余方法
}
```

## 架构

```
AlloyPlayer (umbrella)
├── AlloyCore          ← 协议、枚举、Player 控制器
├── AlloyAVPlayer      ← AVPlayer 引擎实现
└── AlloyControlView   ← 默认控制层 UI
```

## 模块

### AlloyCore

基础模块，包含所有协议、枚举和 `Player` 控制器。

| 类型 | 描述 |
|------|------|
| `Player` | 主控制器，协调引擎、UI、手势和方向 |
| `PlaybackEngine` | 视频播放引擎协议 |
| `ControlOverlay` | 控制层 UI 协议 |
| `GestureManager` | 单击、拖动、捏合和长按手势处理 |
| `OrientationManager` | 竖屏/横屏全屏转换 |
| `FloatingView` | 列表播放的浮动画中画窗口 |
| `ReachabilityMonitor` | 网络状态监控 |
| `RenderView` | 视频渲染基础视图 |
| `PlaybackState` | 播放状态枚举（unknown/playing/paused/failed/stopped） |
| `LoadState` | 缓冲加载状态（OptionSet） |
| `ScalingMode` | 视频缩放模式（aspectFit/aspectFill/fill） |
| `FullScreenMode` | 全屏模式（automatic/landscape/portrait） |

### AlloyAVPlayer

基于 AVFoundation 的播放引擎实现。

| 类型 | 描述 |
|------|------|
| `AVPlayerManager` | 使用 AVPlayer 的 `PlaybackEngine` 实现 |

### AlloyControlView

默认控制层，包含竖屏和横屏面板。

| 类型 | 描述 |
|------|------|
| `DefaultControlOverlay` | 完整功能的 `ControlOverlay` 实现 |
| `PortraitControlPanel` | 竖屏模式控制面板 |
| `LandscapeControlPanel` | 横屏模式控制面板 |
| `FloatingControlPanel` | 浮动窗口控制面板 |
| `ProgressSlider` | 播放进度滑块 |
| `BufferingIndicator` | 缓冲状态指示器 |
| `LoadingIndicator` | 加载动画 |
| `VolumeAndBrightnessHUD` | 音量/亮度调节 HUD |
| `NetworkSpeedMonitor` | 网速显示 |
| `CustomStatusBar` | 全屏自定义状态栏 |

### AlloyPlayer (umbrella)

重新导出所有三个模块，方便单次导入使用。

## 许可证

MIT 许可证。详见 [LICENSE](LICENSE)。
