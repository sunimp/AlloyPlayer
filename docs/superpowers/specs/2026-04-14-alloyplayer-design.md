# AlloyPlayer 设计文档

> 纯 Swift 视频播放框架，100% 覆盖 ZFPlayer 功能，最低支持 iOS 15.0。

## 1. 技术栈

| 项目 | 选型 |
|------|------|
| 语言 | Swift 6.3（Swift 6 语言模式） |
| 最低版本 | iOS 15.0 |
| 包管理 | 仅 SPM |
| 事件通信 | Combine |
| UI 框架 | UIKit + Auto Layout |
| 异步 | async/await |
| 网络监控 | NWPathMonitor |
| 日志 | os.Logger |

## 2. SPM 模块结构

```
AlloyPlayer (SPM Package)
├── AlloyCore          ← 协议、枚举、核心控制器、工具类
├── AlloyAVPlayer      ← AVPlayer 引擎实现（依赖 AlloyCore）
├── AlloyControlView   ← 默认控制层 UI（依赖 AlloyCore）
└── AlloyPlayer        ← Umbrella re-export（依赖以上三者）
```

### 依赖关系

```
AlloyControlView ──depends on──▶ AlloyCore
AlloyAVPlayer    ──depends on──▶ AlloyCore
AlloyPlayer      ──depends on──▶ AlloyCore + AlloyAVPlayer + AlloyControlView
```

### 对外 Products

```swift
.library(name: "AlloyPlayer", targets: ["AlloyPlayer"]),         // 一键全量
.library(name: "AlloyCore", targets: ["AlloyCore"]),             // 仅协议+核心
.library(name: "AlloyAVPlayer", targets: ["AlloyAVPlayer"]),     // AVPlayer 引擎
.library(name: "AlloyControlView", targets: ["AlloyControlView"]), // 默认 UI
```

## 3. 目录结构

```
AlloyPlayer/
├── Package.swift
├── Sources/
│   ├── AlloyCore/
│   │   ├── Enums.swift
│   │   ├── PlaybackEngine.swift
│   │   ├── ControlOverlay.swift
│   │   ├── Player.swift
│   │   ├── Player+Playback.swift
│   │   ├── Player+Orientation.swift
│   │   ├── Player+ScrollView.swift
│   │   ├── RenderView.swift
│   │   ├── GestureManager.swift
│   │   ├── OrientationManager.swift
│   │   ├── LandscapeRotationHandler.swift
│   │   ├── LandscapeController.swift
│   │   ├── LandscapeWindow.swift
│   │   ├── PortraitController.swift
│   │   ├── FullScreenTransition.swift
│   │   ├── InteractiveDismissTransition.swift
│   │   ├── FloatingView.swift
│   │   ├── SystemEventObserver.swift
│   │   ├── ReachabilityMonitor.swift
│   │   ├── KVOManager.swift
│   │   ├── ScrollView+Player.swift
│   │   └── Utilities.swift
│   │
│   ├── AlloyAVPlayer/
│   │   └── AVPlayerManager.swift
│   │
│   ├── AlloyControlView/
│   │   ├── DefaultControlOverlay.swift
│   │   ├── PortraitControlPanel.swift
│   │   ├── LandscapeControlPanel.swift
│   │   ├── ProgressSlider.swift
│   │   ├── FloatingControlPanel.swift
│   │   ├── BufferingIndicator.swift
│   │   ├── LoadingIndicator.swift
│   │   ├── VolumeAndBrightnessHUD.swift
│   │   ├── NetworkSpeedMonitor.swift
│   │   ├── CustomStatusBar.swift
│   │   └── Resources/
│   │
│   └── AlloyPlayer/
│       └── AlloyPlayer.swift
│
└── Tests/
    ├── AlloyCoreTests/
    ├── AlloyAVPlayerTests/
    └── AlloyControlViewTests/
```

## 4. 枚举 & OptionSet

所有枚举符合 `Sendable`，`NS_OPTIONS` 全部改用 `OptionSet`。

### 播放状态

```swift
public enum PlaybackState: Int, Sendable {
    case unknown, playing, paused, failed, stopped
}
```

### 加载状态

```swift
public struct LoadState: OptionSet, Sendable {
    public let rawValue: UInt
    public static let unknown       = LoadState([])
    public static let prepare       = LoadState(rawValue: 1 << 0)
    public static let playable      = LoadState(rawValue: 1 << 1)
    public static let playthroughOK = LoadState(rawValue: 1 << 2)
    public static let stalled       = LoadState(rawValue: 1 << 3)
}
```

### 缩放模式

```swift
public enum ScalingMode: Int, Sendable {
    case none, aspectFit, aspectFill, fill
}
```

### 全屏模式

```swift
public enum FullScreenMode: Int, Sendable {
    case automatic, landscape, portrait
}

public enum PortraitFullScreenMode: Int, Sendable {
    case scaleToFill, scaleAspectFit
}
```

### 手势相关

```swift
public enum GestureType: Int, Sendable {
    case unknown, singleTap, doubleTap, pan, pinch
}

public struct DisableGestureTypes: OptionSet, Sendable {
    public let rawValue: UInt
    public static let singleTap  = DisableGestureTypes(rawValue: 1 << 0)
    public static let doubleTap  = DisableGestureTypes(rawValue: 1 << 1)
    public static let pan        = DisableGestureTypes(rawValue: 1 << 2)
    public static let pinch      = DisableGestureTypes(rawValue: 1 << 3)
    public static let longPress  = DisableGestureTypes(rawValue: 1 << 4)
    public static let all: DisableGestureTypes = [.singleTap, .doubleTap, .pan, .pinch, .longPress]
}

public enum PanDirection: Int, Sendable { case unknown, vertical, horizontal }
public enum PanLocation: Int, Sendable  { case unknown, left, right }
public enum PanMovingDirection: Int, Sendable { case unknown, top, left, bottom, right }

public struct DisablePanMovingDirection: OptionSet, Sendable {
    public let rawValue: UInt
    public static let vertical   = DisablePanMovingDirection(rawValue: 1 << 0)
    public static let horizontal = DisablePanMovingDirection(rawValue: 1 << 1)
    public static let all: DisablePanMovingDirection = [.vertical, .horizontal]
}

public enum LongPressPhase: Int, Sendable { case began, changed, ended }
```

### 屏幕方向

```swift
public struct InterfaceOrientationMask: OptionSet, Sendable {
    public let rawValue: UInt
    public static let portrait           = InterfaceOrientationMask(rawValue: 1 << 0)
    public static let landscapeLeft      = InterfaceOrientationMask(rawValue: 1 << 1)
    public static let landscapeRight     = InterfaceOrientationMask(rawValue: 1 << 2)
    public static let portraitUpsideDown = InterfaceOrientationMask(rawValue: 1 << 3)
    public static let landscape: InterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
    public static let all: InterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    public static let allButUpsideDown: InterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
}

public struct DisablePortraitGestureTypes: OptionSet, Sendable {
    public let rawValue: UInt
    public static let tap = DisablePortraitGestureTypes(rawValue: 1 << 0)
    public static let pan = DisablePortraitGestureTypes(rawValue: 1 << 1)
    public static let all: DisablePortraitGestureTypes = [.tap, .pan]
}
```

### 滚动视图相关

```swift
public enum ScrollDirection: Int, Sendable { case none, up, down, left, right }
public enum ScrollViewDirection: Int, Sendable { case vertical, horizontal }
public enum AttachmentMode: Int, Sendable { case view, cell }

public enum ScrollAnchor: Int, Sendable {
    case none
    case top, centeredVertically, bottom
    case left, centeredHorizontally, right
}
```

### 其他

```swift
public enum ReachabilityStatus: Int, Sendable {
    case unknown = -1
    case notReachable = 0
    case wifi = 1
    case cellular2G = 2
    case cellular3G = 3
    case cellular4G = 4
    case cellular5G = 5
}

public enum BackgroundState: Int, Sendable { case foreground, background }
public enum LoadingType: Int, Sendable { case keep, fadeOut }
```

## 5. 核心协议

### PlaybackEngine（播放引擎协议）

```swift
@MainActor
public protocol PlaybackEngine: AnyObject {
    var renderView: RenderView { get }

    // 状态
    var playbackState: PlaybackState { get }
    var loadState: LoadState { get }
    var isPlaying: Bool { get }
    var isPreparedToPlay: Bool { get }

    // 控制属性
    var volume: Float { get set }
    var isMuted: Bool { get set }
    var rate: Float { get set }
    var scalingMode: ScalingMode { get set }
    var shouldAutoPlay: Bool { get set }

    // 时间
    var currentTime: TimeInterval { get }
    var totalTime: TimeInterval { get }
    var bufferTime: TimeInterval { get }
    var seekTime: TimeInterval { get set }

    // 资源
    var assetURL: URL? { get set }
    var presentationSize: CGSize { get }

    // Combine 事件流
    var statePublisher: AnyPublisher<PlaybackState, Never> { get }
    var loadStatePublisher: AnyPublisher<LoadState, Never> { get }
    var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never> { get }
    var bufferTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    var prepareToPlayPublisher: AnyPublisher<URL, Never> { get }
    var readyToPlayPublisher: AnyPublisher<URL, Never> { get }
    var playFailedPublisher: AnyPublisher<Error, Never> { get }
    var didPlayToEndPublisher: AnyPublisher<Void, Never> { get }
    var presentationSizePublisher: AnyPublisher<CGSize, Never> { get }

    // 控制方法
    func prepareToPlay()
    func reloadPlayer()
    func play()
    func pause()
    func replay()
    func stop()
    func seek(to time: TimeInterval) async -> Bool

    // 截图（可选，有默认空实现）
    func thumbnailImageAtCurrentTime() -> UIImage?
    func thumbnailImageAtCurrentTime() async -> UIImage?
}
```

### ControlOverlay（控制层协议）

```swift
@MainActor
public protocol ControlOverlay: UIView {
    var player: Player? { get set }

    // 播放状态（均有默认空实现）
    func player(_ player: Player, prepareToPlay assetURL: URL)
    func player(_ player: Player, didChangePlaybackState state: PlaybackState)
    func player(_ player: Player, didChangeLoadState state: LoadState)

    // 进度
    func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval)
    func player(_ player: Player, didUpdateBufferTime bufferTime: TimeInterval)
    func player(_ player: Player, draggingTime: TimeInterval, totalTime: TimeInterval)
    func playerDidPlayToEnd(_ player: Player)
    func player(_ player: Player, didFailWithError error: Error)

    // 锁屏
    func player(_ player: Player, didChangeLockState isLocked: Bool)

    // 旋转
    func player(_ player: Player, willChangeOrientation observer: OrientationManager)
    func player(_ player: Player, didChangeOrientation observer: OrientationManager)

    // 网络
    func player(_ player: Player, didChangeReachability status: ReachabilityStatus)

    // 视频尺寸
    func player(_ player: Player, didChangePresentationSize size: CGSize)

    // 手势
    func gestureTriggerCondition(_ gesture: GestureManager, type: GestureType, recognizer: UIGestureRecognizer, touch: UITouch) -> Bool
    func gestureSingleTapped(_ gesture: GestureManager)
    func gestureDoubleTapped(_ gesture: GestureManager)
    func gestureBeganPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)
    func gestureChangedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation, velocity: CGPoint)
    func gestureEndedPan(_ gesture: GestureManager, direction: PanDirection, location: PanLocation)
    func gesturePinched(_ gesture: GestureManager, scale: Float)
    func longPressed(_ gesture: GestureManager, state: LongPressPhase)

    // 列表播放
    func playerWillAppearInScrollView(_ player: Player)
    func playerDidAppearInScrollView(_ player: Player)
    func playerWillDisappearInScrollView(_ player: Player)
    func playerDidDisappearInScrollView(_ player: Player)
    func player(_ player: Player, appearingPercent: CGFloat)
    func player(_ player: Player, disappearingPercent: CGFloat)
    func player(_ player: Player, floatViewShow isShow: Bool)
}
```

### ProgressSliderDelegate

```swift
public protocol ProgressSliderDelegate: AnyObject {
    func sliderTouchBegan(_ slider: ProgressSlider, value: Float)
    func sliderValueChanged(_ slider: ProgressSlider, value: Float)
    func sliderTouchEnded(_ slider: ProgressSlider, value: Float)
    func sliderTapped(_ slider: ProgressSlider, value: Float)
}
```

## 6. Player 主控制器

### 初始化

```swift
public final class Player {
    // 普通模式
    public init(engine: PlaybackEngine, containerView: UIView)

    // 列表模式（tag 查找容器）
    public init(scrollView: UIScrollView, engine: PlaybackEngine, containerViewTag: Int)

    // 列表模式（直接传入容器）
    public init(scrollView: UIScrollView, engine: PlaybackEngine, containerView: UIView)
}
```

### 核心属性

```swift
// 组件
public weak var containerView: UIView?
public var engine: PlaybackEngine
public var controlOverlay: (UIView & ControlOverlay)?
public private(set) var orientationManager: OrientationManager
public private(set) var gestureManager: GestureManager
public private(set) var systemEventObserver: SystemEventObserver?
public private(set) var attachmentMode: AttachmentMode

// 播放状态（只读）
public var currentTime: TimeInterval { get }
public var totalTime: TimeInterval { get }
public var bufferTime: TimeInterval { get }
public var progress: Float { get }
public var bufferProgress: Float { get }
public var isFullScreen: Bool { get }

// 播放控制
public var volume: Float { get set }
public var isMuted: Bool { get set }
public var brightness: Float { get set }
public var rate: Float { get set }

// 资源管理
public var assetURL: URL? { get set }
public var assetURLs: [URL]?
public var currentPlayIndex: Int { get set }
public var isFirstAsset: Bool { get }
public var isLastAsset: Bool { get }

// 行为配置
public var shouldResumePlayRecord: Bool
public var pauseWhenAppResignActive: Bool
public var isPausedByEvent: Bool
public var isViewControllerDisappear: Bool
public var useCustomAudioSession: Bool
public var exitFullScreenWhenStop: Bool

// 锁屏 & 状态栏
public var isScreenLocked: Bool { get set }
public var isStatusBarHidden: Bool { get set }
public var fullScreenStatusBarStyle: UIStatusBarStyle
public var fullScreenStatusBarAnimation: UIStatusBarAnimation

// 手势配置
public var disabledGestureTypes: DisableGestureTypes
public var disabledPanMovingDirection: DisablePanMovingDirection
```

### 播放控制扩展 (Player+Playback)

```swift
extension Player {
    public func stop()
    public func replaceEngine(_ engine: PlaybackEngine)
    public func playNext()
    public func playPrevious()
    public func play(at index: Int)
    public func seek(to time: TimeInterval) async -> Bool
}
```

### 旋转/全屏扩展 (Player+Orientation)

```swift
extension Player {
    public func addDeviceOrientationObserver()
    public func removeDeviceOrientationObserver()
    public func rotate(to orientation: UIInterfaceOrientation, animated: Bool) async
    public func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) async
    public func enterFullScreen(_ fullScreen: Bool, animated: Bool) async
}
```

### 列表播放扩展 (Player+ScrollView)

```swift
extension Player {
    // 小窗
    public private(set) var floatingView: FloatingView?
    public var isFloatingViewVisible: Bool { get }
    public func addPlayerView(to cell: UIView)
    public func addPlayerView(to containerView: UIView)
    public func addPlayerViewToFloatingView()

    // 列表配置
    public var shouldAutoPlay: Bool { get set }
    public var autoPlayOnWWAN: Bool { get set }
    public private(set) var playingIndexPath: IndexPath?
    public private(set) var shouldPlayIndexPath: IndexPath?
    public var containerViewTag: Int { get }
    public var stopWhileNotVisible: Bool { get set }
    public var disappearPercent: CGFloat { get set }
    public var appearPercent: CGFloat { get set }
    public var sectionAssetURLs: [[URL]]?

    // 播放指定位置
    public func play(at indexPath: IndexPath)
    public func play(at indexPath: IndexPath, scrollTo position: ScrollAnchor, animated: Bool) async
    public func play(at indexPath: IndexPath, assetURL: URL)
    public func play(at indexPath: IndexPath, assetURL: URL, scrollTo position: ScrollAnchor, animated: Bool) async

    // 滚动过滤
    public func filterShouldPlayCellWhileScrolled() -> IndexPath?
    public func filterShouldPlayCellWhileScrolling() -> IndexPath?
    public func stopCurrentPlayingView()
    public func stopCurrentPlayingCell()
}
```

### Combine 事件流

```swift
extension Player {
    // 透传 engine 事件
    public var playbackStatePublisher: AnyPublisher<PlaybackState, Never>
    public var loadStatePublisher: AnyPublisher<LoadState, Never>
    public var playTimePublisher: AnyPublisher<(current: TimeInterval, total: TimeInterval), Never>
    public var bufferTimePublisher: AnyPublisher<TimeInterval, Never>
    public var playFailedPublisher: AnyPublisher<Error, Never>
    public var didPlayToEndPublisher: AnyPublisher<Void, Never>
    public var presentationSizePublisher: AnyPublisher<CGSize, Never>

    // Player 独有事件
    public var orientationWillChangePublisher: AnyPublisher<Bool, Never>
    public var orientationDidChangePublisher: AnyPublisher<Bool, Never>

    // 列表播放事件
    public var playerAppearingPublisher: AnyPublisher<(IndexPath, CGFloat), Never>
    public var playerDisappearingPublisher: AnyPublisher<(IndexPath, CGFloat), Never>
    public var playerWillAppearPublisher: AnyPublisher<IndexPath, Never>
    public var playerDidAppearPublisher: AnyPublisher<IndexPath, Never>
    public var playerWillDisappearPublisher: AnyPublisher<IndexPath, Never>
    public var playerDidDisappearPublisher: AnyPublisher<IndexPath, Never>
    public var scrollViewDidEndScrollingPublisher: AnyPublisher<IndexPath, Never>
}
```

## 7. 支撑模块

### GestureManager

```swift
public final class GestureManager {
    // 手势识别器（只读）
    public private(set) var singleTap: UITapGestureRecognizer
    public private(set) var doubleTap: UITapGestureRecognizer
    public private(set) var pan: UIPanGestureRecognizer
    public private(set) var pinch: UIPinchGestureRecognizer
    public private(set) var longPress: UILongPressGestureRecognizer

    // 状态
    public private(set) var panDirection: PanDirection
    public private(set) var panLocation: PanLocation
    public private(set) var panMovingDirection: PanMovingDirection

    // 配置
    public var disabledGestureTypes: DisableGestureTypes
    public var disabledPanMovingDirection: DisablePanMovingDirection

    // Combine 事件流
    public var singleTapPublisher: AnyPublisher<Void, Never>
    public var doubleTapPublisher: AnyPublisher<Void, Never>
    public var panBeganPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation), Never>
    public var panChangedPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation, velocity: CGPoint), Never>
    public var panEndedPublisher: AnyPublisher<(direction: PanDirection, location: PanLocation), Never>
    public var pinchPublisher: AnyPublisher<Float, Never>
    public var longPressPublisher: AnyPublisher<LongPressPhase, Never>

    // 条件过滤
    public var triggerCondition: ((_ type: GestureType, _ recognizer: UIGestureRecognizer, _ touch: UITouch) -> Bool)?

    public func attach(to view: UIView)
    public func detach(from view: UIView)
}
```

### OrientationManager

```swift
public final class OrientationManager {
    public weak var containerView: UIView?
    public private(set) var fullScreenContainerView: UIView?

    // 状态
    public private(set) var isFullScreen: Bool
    public private(set) var currentOrientation: UIInterfaceOrientation

    // 配置
    public var fullScreenMode: FullScreenMode
    public var portraitFullScreenMode: PortraitFullScreenMode
    public var animationDuration: TimeInterval
    public var isScreenLocked: Bool
    public var isAllowOrientationRotation: Bool
    public var supportedOrientations: InterfaceOrientationMask
    public var isFullScreenStatusBarHidden: Bool
    public var fullScreenStatusBarStyle: UIStatusBarStyle
    public var fullScreenStatusBarAnimation: UIStatusBarAnimation
    public var presentationSize: CGSize
    public var disabledPortraitGestureTypes: DisablePortraitGestureTypes

    // Combine 事件流
    public var orientationWillChangePublisher: AnyPublisher<Bool, Never>
    public var orientationDidChangePublisher: AnyPublisher<Bool, Never>

    // 方法
    public func updateViews(renderView: RenderView, containerView: UIView)
    public func addDeviceOrientationObserver()
    public func removeDeviceOrientationObserver()
    public func rotate(to orientation: UIInterfaceOrientation, animated: Bool) async
    public func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) async
    public func enterFullScreen(_ fullScreen: Bool, animated: Bool) async
}
```

内部按 iOS 版本差异分策略：iOS 15 基于 `UIDevice.setValue`，iOS 16+ 基于 `UIWindowScene.requestGeometryUpdate`。

### SystemEventObserver

```swift
public final class SystemEventObserver {
    public private(set) var backgroundState: BackgroundState

    public enum AudioRouteChangeReason: Sendable {
        case newDeviceAvailable
        case oldDeviceUnavailable
        case categoryChanged
    }

    // Combine 事件流
    public var willResignActivePublisher: AnyPublisher<Void, Never>
    public var didBecomeActivePublisher: AnyPublisher<Void, Never>
    public var audioRouteChangePublisher: AnyPublisher<AudioRouteChangeReason, Never>
    public var volumeChangedPublisher: AnyPublisher<Float, Never>
    public var audioInterruptionPublisher: AnyPublisher<AVAudioSession.InterruptionType, Never>

    public func startObserving()
    public func stopObserving()
}
```

### ReachabilityMonitor

基于 `NWPathMonitor` 实现。

```swift
public final class ReachabilityMonitor {
    public static let shared: ReachabilityMonitor

    public private(set) var currentStatus: ReachabilityStatus
    public var isReachable: Bool { get }
    public var isReachableViaWiFi: Bool { get }
    public var isReachableViaCellular: Bool { get }

    public var statusPublisher: AnyPublisher<ReachabilityStatus, Never>

    public func startMonitoring()
    public func stopMonitoring()
}
```

### KVOManager

```swift
public final class KVOManager {
    public init(target: NSObject)
    public func observe<Value>(_ keyPath: KeyPath<some NSObject, Value>, options: NSKeyValueObservingOptions, handler: @escaping (Value) -> Void)
    public func invalidate()
}
```

### FloatingView

```swift
public final class FloatingView: UIView {
    public weak var parentView: UIView?
    public var safeInsets: UIEdgeInsets
    // 内置拖拽手势，自动吸附屏幕边缘
}
```

### ScrollView+Player

```swift
extension UIScrollView {
    public var scrollDirection: ScrollDirection { get }
    public var scrollViewDirection: ScrollViewDirection { get set }
    public func cell(at indexPath: IndexPath) -> UIView?
    public func indexPath(for cell: UIView) -> IndexPath?
    public func scroll(to indexPath: IndexPath, at anchor: ScrollAnchor, animated: Bool) async
}
```

### 内部类（internal 访问级别）

- `LandscapeRotationHandler` — 横屏旋转处理
- `LandscapeWindow` — 横屏全屏窗口
- `LandscapeController` — 横屏 VC
- `PortraitController` — 竖屏全屏 VC
- `FullScreenTransition` — 全屏转场动画
- `InteractiveDismissTransition` — 交互式退出转场

### Utilities

```swift
enum TimeFormatter {
    static func string(from seconds: Int) -> String   // "00:00" / "00:00:00"
}

enum ImageGenerator {
    static func image(color: UIColor, size: CGSize) -> UIImage
}
```

## 8. AlloyAVPlayer 模块

### AVPlayerManager

```swift
public final class AVPlayerManager: PlaybackEngine {
    // AVFoundation 内部对象（只读暴露）
    public private(set) var asset: AVURLAsset?
    public private(set) var playerItem: AVPlayerItem?
    public private(set) var player: AVPlayer?
    public private(set) var playerLayer: AVPlayerLayer?

    // 配置
    public var timeRefreshInterval: TimeInterval      // 默认 0.1s
    public var requestHeaders: [String: String]?      // 自定义请求头

    // PlaybackEngine 协议完整实现...
}
```

### 内部流程

```
assetURL 设置
  → 创建 AVURLAsset（附加 requestHeaders）
  → 创建 AVPlayerItem
  → KVOManager 观察 playerItem：status, loadedTimeRanges, playbackLikelyToKeepUp, playbackBufferEmpty, playbackBufferFull, presentationSize
  → 创建/复用 AVPlayer
  → addPeriodicTimeObserver → playTimePublisher
  → NotificationCenter 监听：didPlayToEndTime, failedToPlayToEndTime
```

### ScalingMode 映射

```
.aspectFit  → AVLayerVideoGravity.resizeAspect
.aspectFill → AVLayerVideoGravity.resizeAspectFill
.fill       → AVLayerVideoGravity.resize
.none       → AVLayerVideoGravity.resizeAspect
```

### 截图

- 同步：`AVAssetImageGenerator.copyCGImage(at:actualTime:)`
- 异步：`AVAssetImageGenerator.generateCGImagesAsynchronously`

## 9. AlloyControlView 模块

### DefaultControlOverlay

```swift
public final class DefaultControlOverlay: UIView, ControlOverlay {
    // 子视图
    public private(set) var portraitPanel: PortraitControlPanel
    public private(set) var landscapePanel: LandscapeControlPanel
    public private(set) var bufferingIndicator: BufferingIndicator
    public private(set) var bottomProgress: ProgressSlider
    public private(set) var coverImageView: UIImageView
    public private(set) var backgroundImageView: UIImageView
    public private(set) var backgroundEffectView: UIVisualEffectView?
    public private(set) var floatingPanel: FloatingControlPanel
    public private(set) var failButton: UIButton
    public private(set) var seekHUDView: UIView
    public private(set) var seekTimeLabel: UILabel
    public private(set) var seekProgressView: ProgressSlider
    public private(set) var seekDirectionImageView: UIImageView

    // 配置
    public var isSeekHUDAnimated: Bool
    public var isBackgroundEffectVisible: Bool
    public var shouldSeekToPlay: Bool
    public var isControlViewVisible: Bool { get }
    public var autoHideInterval: TimeInterval
    public var autoFadeInterval: TimeInterval
    public var shouldShowControlOnHorizontalPan: Bool
    public var shouldShowControlOnPrepare: Bool
    public var shouldShowLoadingOnPrepare: Bool
    public var isCustomDisablePanMovingDirection: Bool
    public var shouldShowCustomStatusBar: Bool
    public var fullScreenMode: FullScreenMode

    // Combine 事件流
    public var backButtonTapPublisher: AnyPublisher<Void, Never>
    public var controlVisibilityPublisher: AnyPublisher<Bool, Never>

    // 方法
    public func show(title: String?, coverURL: URL?, placeholderImage: UIImage?, fullScreenMode: FullScreenMode)
    public func show(title: String?, coverImage: UIImage?, fullScreenMode: FullScreenMode)
    public func resetControlView()
}
```

### PortraitControlPanel

```swift
public final class PortraitControlPanel: UIView {
    public private(set) var topToolBar: UIView
    public private(set) var bottomToolBar: UIView
    public private(set) var titleLabel: UILabel
    public private(set) var playPauseButton: UIButton
    public private(set) var currentTimeLabel: UILabel
    public private(set) var slider: ProgressSlider
    public private(set) var totalTimeLabel: UILabel
    public private(set) var fullScreenButton: UIButton

    public weak var player: Player?
    public var shouldSeekToPlay: Bool
    public var fullScreenMode: FullScreenMode

    public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never>
    public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never>

    public func resetControlView()
    public func showControlView()
    public func hideControlView()
    public func show(title: String?, fullScreenMode: FullScreenMode)
    public func updatePlayButtonState(isPlaying: Bool)
    public func updateTime(current: TimeInterval, total: TimeInterval)
    public func updateBufferTime(_ bufferTime: TimeInterval)
    public func updateSlider(value: CGFloat, currentTimeString: String)
    public func sliderDidEndChanging()
}
```

### LandscapeControlPanel

```swift
public final class LandscapeControlPanel: UIView {
    // 比竖屏多 backButton 和 lockButton
    public private(set) var topToolBar: UIView
    public private(set) var bottomToolBar: UIView
    public private(set) var backButton: UIButton
    public private(set) var titleLabel: UILabel
    public private(set) var playPauseButton: UIButton
    public private(set) var currentTimeLabel: UILabel
    public private(set) var slider: ProgressSlider
    public private(set) var totalTimeLabel: UILabel
    public private(set) var lockButton: UIButton

    public weak var player: Player?
    public var shouldSeekToPlay: Bool
    public var shouldShowCustomStatusBar: Bool
    public var fullScreenMode: FullScreenMode

    public var sliderValueChangingPublisher: AnyPublisher<(value: CGFloat, isForward: Bool), Never>
    public var sliderValueChangedPublisher: AnyPublisher<CGFloat, Never>
    public var backButtonTapPublisher: AnyPublisher<Void, Never>

    // 方法与 PortraitControlPanel 对称 + 额外方法
    public func updatePresentationSize(_ size: CGSize)
    public func updateOrientation(_ observer: OrientationManager)
}
```

### ProgressSlider

```swift
public final class ProgressSlider: UIView {
    public private(set) var thumbButton: UIButton

    // 轨道外观
    public var maximumTrackTintColor: UIColor
    public var minimumTrackTintColor: UIColor
    public var bufferTrackTintColor: UIColor
    public var loadingTintColor: UIColor
    public var maximumTrackImage: UIImage?
    public var minimumTrackImage: UIImage?
    public var bufferTrackImage: UIImage?

    // 值
    public var value: Float { get set }
    public var bufferValue: Float { get set }

    // 配置
    public var isTapEnabled: Bool
    public var isAnimated: Bool
    public var trackHeight: CGFloat
    public var trackCornerRadius: CGFloat
    public var isThumbHidden: Bool
    public var isDragging: Bool { get }
    public var isForward: Bool { get }
    public var thumbSize: CGSize

    // Combine 事件流
    public var touchBeganPublisher: AnyPublisher<Float, Never>
    public var valueChangedPublisher: AnyPublisher<Float, Never>
    public var touchEndedPublisher: AnyPublisher<Float, Never>
    public var tappedPublisher: AnyPublisher<Float, Never>

    // Delegate（可选）
    public weak var delegate: ProgressSliderDelegate?

    public func startLoading()
    public func stopLoading()
    public func setThumbImage(_ image: UIImage?, for state: UIControl.State)
    public func setBackgroundImage(_ image: UIImage?, for state: UIControl.State)
}
```

### 其他控件

```swift
// FloatingControlPanel
public final class FloatingControlPanel: UIView {
    public var closeTapPublisher: AnyPublisher<Void, Never>
}

// BufferingIndicator
public final class BufferingIndicator: UIView {
    public private(set) var loadingView: LoadingIndicator
    public private(set) var speedLabel: UILabel
    public func startAnimating()
    public func stopAnimating()
}

// LoadingIndicator
public final class LoadingIndicator: UIView {
    public var animationType: LoadingType
    public var lineColor: UIColor
    public var lineWidth: CGFloat
    public var hidesWhenStopped: Bool
    public var animationDuration: TimeInterval
    public var isAnimating: Bool { get }
    public func startAnimating()
    public func stopAnimating()
}

// VolumeAndBrightnessHUD
public final class VolumeAndBrightnessHUD: UIView {
    public enum HUDType: Sendable { case volume, brightness }
    public private(set) var hudType: HUDType
    public private(set) var progressView: UIProgressView
    public private(set) var iconImageView: UIImageView
    public func update(progress: CGFloat, type: HUDType)
    public func addSystemVolumeView()
    public func removeSystemVolumeView()
}

// NetworkSpeedMonitor
public final class NetworkSpeedMonitor {
    public private(set) var downloadSpeed: String
    public private(set) var uploadSpeed: String
    public var speedPublisher: AnyPublisher<(download: String, upload: String), Never>
    public func startMonitoring()
    public func stopMonitoring()
}

// CustomStatusBar
public final class CustomStatusBar: UIView {
    public var refreshInterval: TimeInterval
    public func startTimer()
    public func stopTimer()
}
```

### 资源管理

SPM resource bundle，通过 `Bundle.module` 加载图片资源。

## 10. 移除项

| ZFPlayer 功能 | 原因 |
|---|---|
| `UIImageView+ZFCache` | 图片缓存不属于播放器职责，用户可选 Kingfisher/SDWebImage/Nuke |
| `UIView+ZFFrame` | 改用 Auto Layout，不需要 frame 便捷属性 |
| `ZFPlayerLogManager` | 使用 `os.Logger` 替代 |
| ijkplayer 子模块 | 仅内置 AVPlayer，用户可通过 PlaybackEngine 协议自行实现其他引擎 |

## 11. ZFPlayer → AlloyPlayer 完整对照表

| ZFPlayer | AlloyPlayer | 模块 |
|---|---|---|
| ZFPlayerController | `Player` | AlloyCore |
| ZFPlayerMediaPlayback | `PlaybackEngine` | AlloyCore |
| ZFPlayerMediaControl | `ControlOverlay` | AlloyCore |
| ZFPlayerView | `RenderView` | AlloyCore |
| ZFPlayerGestureControl | `GestureManager` | AlloyCore |
| ZFOrientationObserver | `OrientationManager` | AlloyCore |
| ZFLandscapeRotationManager | `LandscapeRotationHandler` (internal) | AlloyCore |
| ZFLandscapeViewController | `LandscapeController` (internal) | AlloyCore |
| ZFPortraitViewController | `PortraitController` (internal) | AlloyCore |
| ZFFloatView | `FloatingView` | AlloyCore |
| ZFPlayerNotification | `SystemEventObserver` | AlloyCore |
| ZFReachabilityManager | `ReachabilityMonitor` | AlloyCore |
| ZFKVOController | `KVOManager` | AlloyCore |
| UIScrollView+ZFPlayer | `UIScrollView` extension | AlloyCore |
| ZFAVPlayerManager | `AVPlayerManager` | AlloyAVPlayer |
| ZFPlayerControlView | `DefaultControlOverlay` | AlloyControlView |
| ZFPortraitControlView | `PortraitControlPanel` | AlloyControlView |
| ZFLandScapeControlView | `LandscapeControlPanel` | AlloyControlView |
| ZFSliderView | `ProgressSlider` | AlloyControlView |
| ZFSmallFloatControlView | `FloatingControlPanel` | AlloyControlView |
| ZFSpeedLoadingView | `BufferingIndicator` | AlloyControlView |
| ZFLoadingView | `LoadingIndicator` | AlloyControlView |
| ZFVolumeBrightnessView | `VolumeAndBrightnessHUD` | AlloyControlView |
| ZFNetworkSpeedMonitor | `NetworkSpeedMonitor` | AlloyControlView |
| ZFPlayerStatusBar | `CustomStatusBar` | AlloyControlView |
| Block 回调 | Combine Publisher | 全局 |
| completionHandler | async/await | 全局 |
| NS_OPTIONS | OptionSet | 全局 |
| SCNetworkReachability | NWPathMonitor | AlloyCore |
| 字符串 KVO | Swift KeyPath KVO | AlloyCore |
