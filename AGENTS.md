# AGENTS.md — AlloyPlayer 开发指南

## 项目概述

AlloyPlayer 是一个现代的纯 Swift 视频播放器框架 — ZFPlayer 的完整功能重写。采用 Swift 6 严格并发、Combine 事件流、UIKit + Auto Layout，仅通过 Swift Package Manager 分发。

### 仓库结构

```
AlloyPlayer/
├── Package.swift
├── Sources/
│   ├── AlloyCore/           ← 协议、枚举、Player 控制器
│   ├── AlloyAVPlayer/       ← AVFoundation 播放引擎
│   ├── AlloyControlView/    ← 默认控制层 UI + 资源
│   └── AlloyPlayer/         ← Umbrella 重新导出模块
├── Tests/
│   ├── AlloyCoreTests/
│   ├── AlloyAVPlayerTests/
│   └── AlloyControlViewTests/
├── README.md
├── LICENSE
├── AGENTS.md
├── CLAUDE.md -> AGENTS.md
├── CONTRIBUTING.md
└── CHANGELOG.md
```

### 模块依赖关系

```
AlloyPlayer (umbrella)
├── AlloyCore
├── AlloyAVPlayer      → 依赖 AlloyCore
└── AlloyControlView   → 依赖 AlloyCore
```

## 技术栈约束

- **语言**：Swift 6.3，严格并发模式（`swiftLanguageModes: [.v6]`）
- **最低部署版本**：iOS 15.0，macOS 12.0（macOS 仅用于 SPM 测试宿主）
- **包管理器**：仅 SPM — 不使用 CocoaPods、不使用 Carthage
- **事件通信**：Combine（`AnyPublisher`、`PassthroughSubject`）
- **UI 框架**：UIKit + Auto Layout — 不使用 SwiftUI
- **UIKit 代码**必须用 `#if canImport(UIKit)` 包裹
- **主线程隔离**：所有面向 UI 的协议和类使用 `@MainActor`

## 代码规范

### 文件头

每个 `.swift` 文件必须以以下格式开头：

```swift
//
//  FileName.swift
//  ModuleName
//
//  Created by Author on YYYY/M/D.
//
```

其中 `Author` 为当前作者， `YYYY/M/D` 为实际创建日期。

### 语言

- **代码注释**：简体中文
- **Git commit 信息**：简体中文，带签名：
  ```
  简要描述变更内容
  ```
- **文档文件**（README、CONTRIBUTING 等）：中文

### 格式化

- 编辑后对**每个修改的 `.swift` 文件**执行 `swiftformat <file>`
- **禁止**目录级格式化（`swiftformat .` 或 `swiftformat Sources/`）
- 不使用制表符 — 使用 4 个空格缩进

### 命名

- 协议：描述能力的名词或形容词（`PlaybackEngine`、`ControlOverlay`）
- 枚举：PascalCase 类型名，camelCase 成员名（`PlaybackState.playing`）
- OptionSet：PascalCase 类型名，camelCase 静态成员名（`LoadState.playable`）
- 发布者：以 `Publisher` 为后缀（`statePublisher`、`playTimePublisher`）

## 开发流程

1. **TDD 循环**：编写测试 → 验证失败 → 实现功能 → 验证通过 → 提交
2. **每次提交对应一个逻辑单元**的变更
3. **未经维护者明确许可不得执行 `git push`**
4. **不得执行破坏性 git 操作**（`reset --hard`、`clean -f`、`rebase`、`commit --amend`），除非明确要求

## 测试策略

- **单元测试**用于纯逻辑：枚举、工具类、状态机
- 测试在 macOS 宿主上通过 `swift test` 运行
- 依赖 UIKit 的类使用 `#if canImport(UIKit)` 包裹 — 测试文件遵循相同模式
- 测试 target：
  - `AlloyCoreTests` → 测试 AlloyCore
  - `AlloyAVPlayerTests` → 测试 AlloyAVPlayer
  - `AlloyControlViewTests` → 测试 AlloyControlView

### 运行测试

```bash
cd AlloyPlayer
swift test
```

## 关键类型参考

### AlloyCore — 协议

| 协议 | Actor | 描述 |
|------|-------|------|
| `PlaybackEngine` | `@MainActor` | 视频播放引擎接口（play、pause、seek、Combine 发布者） |
| `ControlOverlay` | `@MainActor` | 控制层 UI 接口（继承 `UIView`） |
| `ProgressSliderDelegate` | — | 滑块交互回调 |

### AlloyCore — 类

| 类 | 描述 |
|------|------|
| `Player` | 主控制器 — 协调引擎、控制层、手势、方向 |
| `GestureManager` | 识别单击、双击、拖动、捏合、长按；发布事件 |
| `OrientationManager` | 管理全屏转换（横屏/竖屏） |
| `FloatingView` | 可拖动的画中画浮动窗口 |
| `RenderView` | 视频渲染层的基础 UIView |
| `ReachabilityMonitor` | 通过 NWPathMonitor 监控网络可达性 |
| `SystemEventObserver` | 应用生命周期通知（进入后台/回到前台） |
| `KVOManager` | 类型安全的 KVO 包装器 |
| `LandscapeController` | 横屏全屏视图控制器 |
| `LandscapeWindow` | 横屏展示专用 window |
| `PortraitController` | 竖屏全屏视图控制器 |
| `FullScreenTransition` | 自定义全屏转场动画 |
| `InteractiveDismissTransition` | 竖屏全屏的交互式关闭手势 |
| `LandscapeRotationHandler` | 设备旋转检测和处理 |

### AlloyCore — 枚举与 OptionSet

| 类型 | 种类 | 值 |
|------|------|------|
| `PlaybackState` | enum | `unknown`、`playing`、`paused`、`failed`、`stopped` |
| `LoadState` | OptionSet | `prepare`、`playable`、`playthroughOK`、`stalled` |
| `ScalingMode` | enum | `none`、`aspectFit`、`aspectFill`、`fill` |
| `FullScreenMode` | enum | `automatic`、`landscape`、`portrait` |
| `GestureType` | enum | `unknown`、`singleTap`、`doubleTap`、`pan`、`pinch` |
| `PanDirection` | enum | `unknown`、`vertical`、`horizontal` |
| `PanLocation` | enum | `unknown`、`left`、`right` |
| `LongPressPhase` | enum | `began`、`changed`、`ended` |
| `ReachabilityStatus` | enum | `unknown`、`notReachable`、`wifi`、`cellular2G/3G/4G/5G` |
| `AttachmentMode` | enum | `view`、`cell` |
| `ScrollDirection` | enum | `none`、`up`、`down`、`left`、`right` |
| `DisableGestureTypes` | OptionSet | `singleTap`、`doubleTap`、`pan`、`pinch`、`longPress` |
| `DisablePanMovingDirection` | OptionSet | `vertical`、`horizontal` |

### AlloyAVPlayer

| 类 | 描述 |
|------|------|
| `AVPlayerManager` | 基于 AVFoundation `AVPlayer` 的 `PlaybackEngine` 实现 |

### AlloyControlView

| 类 | 描述 |
|------|------|
| `DefaultControlOverlay` | 完整的 `ControlOverlay` 实现，包含竖屏/横屏/浮动面板 |
| `PortraitControlPanel` | 竖屏模式控件（播放、滑块、时间、全屏按钮） |
| `LandscapeControlPanel` | 横屏模式控件（扩展工具栏） |
| `FloatingControlPanel` | 浮动画中画窗口控件 |
| `ProgressSlider` | 自定义播放进度滑块 |
| `BufferingIndicator` | 缓冲状态显示 |
| `LoadingIndicator` | 加载动画视图 |
| `VolumeAndBrightnessHUD` | 系统音量/亮度调节浮层 |
| `NetworkSpeedMonitor` | 当前网速显示 |
| `CustomStatusBar` | 全屏模式自定义状态栏 |
