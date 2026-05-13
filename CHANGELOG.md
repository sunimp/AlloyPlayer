# 更新日志

本文件记录项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本号遵循[语义化版本](https://semver.org/spec/v2.0.0.html)。

## [Unreleased]

### 破坏性调整

- 重建 2.0 架构：`AlloyCore` 收敛为平台无关的播放类型、引擎协议、快照、事件和 `PlaybackSession`。
- `AlloyAVPlayer` 改为提供 `AVPlaybackEngine`，通过 `PlaybackSource`、`PlaybackEngineSnapshot` 和 `PlaybackEngineEvent` 与核心层交互。
- `AlloyUIKit` 接管播放器视图、渲染承载、默认控制层、手势和全屏协调；UIKit 控制层改为 `UIKitControlOverlay`。
- `AlloySwiftUI` 改为围绕 `AlloyPlayerController(session:)` 与 `AlloySwiftUIPlayerView` 构建。
- `AlloyListPlayback` 改为驱动 `AlloyUIKit.AlloyPlayerView`，不再依赖旧 ScrollView 扩展。
- `AlloyHTTPMediaCacheSupport` 改为生成代理 `PlaybackSource`，由调用方显式加载。
- 删除旧 Core 中的 UIKit 控制器、手势、方向、浮窗、事件 sink、兼容渲染视图和 KVO/logging 辅助公开面。
- 收窄内部渲染宿主、列表可见性计算和浮动播放容器等实现细节；公开入口保留为 `AlloyPlayerView`、`ListPlaybackCoordinator` 与 `FloatingPlaybackCoordinator`。

## [0.3.1] - 2026-05-12

### 调整

- 将 `AlloyHTTPMediaCacheSupport` 依赖的 HTTPMediaCache 升级到 `1.0.3`。

### 修复

- 继承 HTTPMediaCache `1.0.3` 的 HLS 代理播放修复：开启缓存后，带 `EXT-X-MEDIA` 音轨或字幕 rendition 的 master playlist 默认保留多个 video variants，避免 AVPlayer 失去 ABR 自适应码率空间。

## [0.3.0] - 2026-05-12

### 新增

- 新增 `PlayerState` / `PlayerEvent` 统一状态与事件输出。
- 新增 `AlloyListPlayback` 模块，承接列表播放可见性计算与播放协调。
- 新增 `FloatingPlaybackCoordinator`，将浮动播放窗口从核心控制职责中迁出。
- 新增 `PlaybackRenderSurface`，为自定义播放引擎提供更稳定的渲染承载抽象。

### 调整

- 控制层拆分为播放、手势、方向和列表播放事件 sink 组合，降低自定义控制层接入成本。
- 旧 SwiftUI 控制模块不再依赖 `AlloyAVPlayer`；默认 AVFoundation 便利入口由 `AlloyPlayer` umbrella 模块提供。
- `AlloyHTTPMediaCacheSupport` 移除拆散参数重载，统一通过 `AlloyHTTPMediaCacheConfiguration` 承载进阶配置。
- 核心控制器新增 `attach(to:)` 通用挂载入口，列表播放协调器不再依赖旧 ScrollView 扩展挂载方法。
- 全屏模式选择迁移到独立解析器，横屏 scene 缺失时不再触发 `fatalError`。
- App 生命周期订阅迁移到独立生命周期协调器，减少核心控制器内部职责。

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
- **AlloyCore**：控制层协议，定义控制层 UI 接口。
- **AlloyCore**：主控制器，协调引擎、控制层、手势和方向。
- **AlloyCore**：手势管理，支持单击、双击、拖动、捏合和长按。
- **AlloyCore**：方向管理，横屏和竖屏全屏转换。
- **AlloyCore**：列表播放的可拖动画中画窗口。
- **AlloyCore**：`ReachabilityMonitor`，网络状态监控（WiFi/2G/3G/4G/5G）。
- **AlloyCore**：渲染视图、KVO 与系统事件工具类。
- **AlloyCore**：完整的播放状态、加载状态、缩放模式、全屏模式、手势、滑动方向和网络状态类型。
- **AlloyAVPlayer**：基于 AVFoundation 的 `PlaybackEngine` 实现。
- **AlloyUIKit**：`DefaultControlOverlay`，包含 `PortraitControlPanel`、`LandscapeControlPanel` 和 `FloatingControlPanel`。
- **AlloyUIKit**：`ProgressSlider`、`BufferingIndicator`、`LoadingIndicator`、`VolumeAndBrightnessHUD`、`NetworkSpeedMonitor`、`CustomStatusBar`。
- **AlloySwiftUI**：SwiftUI 播放器视图、控制器和默认控制层，提供开箱即用和自定义 SwiftUI 控制层能力。
- 所有播放状态、时间更新、缓冲进度、错误和方向变化均提供 Combine 发布者。
- ScrollView/TableView/CollectionView 列表播放，滚动时自动播放/暂停。
- SwiftPM 5.10 支持，UI 相关类型使用 `@MainActor` 隔离。
