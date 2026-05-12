# 更新日志

本文件记录项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本号遵循[语义化版本](https://semver.org/spec/v2.0.0.html)。

## [Unreleased]

## [0.3.0] - 2026-05-12

### 新增

- 新增 `PlayerState` / `PlayerEvent` 统一状态与事件输出。
- 新增 `AlloyListPlayback` 模块，承接列表播放可见性计算与播放协调。
- 新增 `FloatingPlaybackCoordinator`，将浮动播放窗口从 `Player` 职责中迁出。
- 新增 `PlaybackRenderSurface`，为自定义播放引擎提供更稳定的渲染承载抽象。

### 调整

- `ControlOverlay` 拆分为播放、手势、方向和列表播放事件 sink 组合，降低自定义控制层接入成本。
- `AlloySwiftUIControls` 不再依赖 `AlloyAVPlayer`；默认 AVPlayer 便利入口由 `AlloyPlayer` umbrella 模块提供。
- `AlloyHTTPMediaCacheSupport` 移除拆散参数重载，统一通过 `AlloyHTTPMediaCacheConfiguration` 承载进阶配置。
- `Player` 新增 `attach(to:)` 通用挂载入口，列表播放协调器不再依赖旧 ScrollView 扩展挂载方法。
- 全屏模式选择迁移到 `FullScreenModeResolver`，横屏 scene 缺失时不再触发 `fatalError`。
- App 生命周期订阅迁移到 `PlayerLifecycleCoordinator`，减少 `Player` 内部职责。

## [0.2.0] - 2026-05-12

### 新增

- 新增 `AlloyHTTPMediaCacheSupport` 可选模块，支持 HTTPMediaCache 代理播放。
- Demo 增加 HTTPMediaCache 播放开关与代理 URL 展示。

### 调整

- Package manifest 降至 SwiftPM 5.10 兼容版本。
- `AlloyHTTPMediaCacheSupport` API 收敛为配置对象入口，便于统一控制端口、localhost 绑定和请求头。

### 修复

- 修复较新 Swift 编译器检查下的 KVO 与关联对象 key 报警问题。

## [0.1.2] - 2026-05-08

### 新增

- Demo 进度条统一展示播放进度、缓冲进度，并支持点击与拖拽 seek。
- Demo 进度条新增缓冲动画，覆盖默认控制层、自定义控制层和短视频场景。
- Demo 接入 LookInside-Release 0.2.0 的 `LookInsideServer`。

### 修复

- 修复短视频 Demo 点击进度条会导致视频暂停的问题。
- 修复初始加载、播放中缓冲不足、加载失败等状态下控制层展示不一致的问题。
- 修复加载失败后点击重试无效，以及失败态仍展示播放按钮和其它控制视图的问题。
- 修复进度条缓冲脉冲动画左右超出可视范围的问题。

## [0.1.1] - 2026-04-17

### 新增

- 视频播放结束时，播放按钮自动切换为重播图标（`arrow.counterclockwise`），
  点击后视频会从头重新开始播放，且开始播放后按钮自动恢复为暂停图标
  （PR #3）。

### 修复

- 修复视频播放完成后，点击播放按钮无效、无法重新播放的问题
  （Issues #1，PR #2、#4）。

## [0.1.0] - 2026-04-14

### 新增

- AlloyPlayer 首次发布。
- **AlloyCore**：`PlaybackEngine` 协议，定义标准视频播放引擎接口。
- **AlloyCore**：`ControlOverlay` 协议，定义控制层 UI 接口。
- **AlloyCore**：`Player` 主控制器，协调引擎、控制层、手势和方向。
- **AlloyCore**：`GestureManager`，支持单击、双击、拖动、捏合和长按。
- **AlloyCore**：`OrientationManager`，横屏和竖屏全屏转换。
- **AlloyCore**：`FloatingView`，列表播放的可拖动画中画窗口。
- **AlloyCore**：`ReachabilityMonitor`，网络状态监控（WiFi/2G/3G/4G/5G）。
- **AlloyCore**：`RenderView`、`KVOManager`、`SystemEventObserver` 工具类。
- **AlloyCore**：完整的枚举/OptionSet 集合：`PlaybackState`、`LoadState`、`ScalingMode`、`FullScreenMode`、`GestureType`、`PanDirection`、`ReachabilityStatus` 等。
- **AlloyAVPlayer**：`AVPlayerManager` — 基于 AVFoundation 的 `PlaybackEngine` 实现。
- **AlloyUIKitControls**：`DefaultControlOverlay`，包含 `PortraitControlPanel`、`LandscapeControlPanel` 和 `FloatingControlPanel`。
- **AlloyUIKitControls**：`ProgressSlider`、`BufferingIndicator`、`LoadingIndicator`、`VolumeAndBrightnessHUD`、`NetworkSpeedMonitor`、`CustomStatusBar`。
- **AlloySwiftUIControls**：`AlloyPlayerView`、`AlloyPlayerController`、`DefaultSwiftUIControlOverlayView`、`SwiftUIControlOverlay` 和 `SwiftUIControlOverlayState`，提供开箱即用和自定义 SwiftUI 控制层能力。
- 所有播放状态、时间更新、缓冲进度、错误和方向变化均提供 Combine 发布者。
- ScrollView/TableView/CollectionView 列表播放，滚动时自动播放/暂停。
- SwiftPM 5.10 支持，UI 相关类型使用 `@MainActor` 隔离。
