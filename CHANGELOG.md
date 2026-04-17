# 更新日志

本文件记录项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
版本号遵循[语义化版本](https://semver.org/spec/v2.0.0.html)。

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
- **AlloyControlView**：`DefaultControlOverlay`，包含 `PortraitControlPanel`、`LandscapeControlPanel` 和 `FloatingControlPanel`。
- **AlloyControlView**：`ProgressSlider`、`BufferingIndicator`、`LoadingIndicator`、`VolumeAndBrightnessHUD`、`NetworkSpeedMonitor`、`CustomStatusBar`。
- 所有播放状态、时间更新、缓冲进度、错误和方向变化均提供 Combine 发布者。
- ScrollView/TableView/CollectionView 列表播放，滚动时自动播放/暂停。
- Swift 6 严格并发支持，使用 `@MainActor` 隔离和 `Sendable` 一致性。
