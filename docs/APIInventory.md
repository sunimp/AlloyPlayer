# AlloyPlayer API Inventory

本文档记录下一版架构重构时公共 API 的处理方向。目标不是保持源码兼容，而是保证调用方体验、架构边界和长期扩展性。

## Keep As Core Concepts

- `Player`: 保留概念，但职责收缩为播放编排与状态输出，不再直接承载列表播放、小窗和全屏实现细节。
- `PlaybackEngine`: 保留概念，但协议形态允许破坏性调整，优先服务自定义引擎接入体验。
- `AVPlayerManager`: 保留作为默认 AVFoundation 引擎。
- `DefaultControlOverlay`: 保留作为 UIKit 默认控制层，但应适配新的状态/事件模型。
- `AlloyPlayerView`: 保留作为 SwiftUI 默认入口名称，具体初始化 API 可重设计。

## Redesign

- `ControlOverlay`: 拆分为更小的事件 sink 与状态驱动模型。
- `Player` publisher API: 以 `statePublisher` 和 `eventPublisher` 作为下一版主路径，减少散落的单项 publisher。
- `Player` 列表播放 API: 从 `Player` 迁出到 `AlloyListPlayback`，umbrella target 提供便捷入口。
- `OrientationManager`: 从 `Player` 直接暴露的核心依赖，调整为可注入的横竖屏 coordinator。
- `RenderView` / `PlaybackEngine.renderView`: 收敛为更清晰的 render surface 抽象。
- `AlloyPlayerView` SwiftUI 初始化器: `AlloySwiftUIControls` 使用 engine injection，`AlloyPlayer` 提供默认 AVPlayer 便捷入口。

## Remove Or Move

- `Player` 内部列表播放存储：迁移到 `ListPlaybackCoordinator`。
- `Player` 直接管理小窗：新增 `FloatingPlaybackCoordinator` 承接，旧扩展后续移除。
- `Player` 直接管理 App 生命周期通知：迁移到 lifecycle coordinator。
- `ControlOverlay` 中的列表播放与小窗回调：迁移到列表播放相关 sink 或 coordinator 输出。

## Compatibility Policy

- 不为了源码兼容保留旧 API。
- 保留旧 API 只在它仍然是更好的调用方式时成立。
- 每个 breaking change 必须在迁移文档中提供 old-to-new 示例。
