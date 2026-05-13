# AlloyPlayer 迁移指南

本文档记录 1.0.0 架构重构后的主要破坏性变更和迁移方式。1.0.0 不保留兼容别名，调用方需要迁移到 `PlaybackSession`、`AlloyPlayerUIKit.AlloyPlayerView` 和 `PlaybackSource`。

## 播放入口

旧入口以核心控制器直接绑定容器视图。新入口可以直接从播放源创建 UIKit 播放视图：

```swift
import AlloyPlayer

let playerView = AlloyPlayerUIKit.AlloyPlayerView(
    source: PlaybackSource(url: videoURL)
)
```

自定义播放引擎时仍然直接创建 `PlaybackSession`：

```swift
let session = PlaybackSession(engine: CustomPlaybackEngine())
let playerView = AlloyPlayerUIKit.AlloyPlayerView(session: session)
```

## API 对照

| 旧 API / 概念 | 1.0.0 API / 概念 |
|---------------|----------------|
| `Player` | `PlaybackSession` + `AlloyPlayerUIKit.AlloyPlayerView` |
| `AVPlayerManager` | `AVPlaybackEngine` |
| `assetURL` | `load(PlaybackSource(url:headers:))` |
| `ControlOverlay` | `UIKitControlOverlay` |
| `FullScreenMode` | `FullscreenMode` |
| ScrollView 扩展和自动选择方法 | `ListPlaybackCoordinator` + `ListPlaybackCandidate` |
| 浮窗视图公开操作 | `FloatingPlaybackCoordinator` |
| `SwiftUIControlOverlayState` | `AlloyPlayerController` |
| `SwiftUIControlOverlay` | `AlloySwiftUIPlayerView` 的自定义 controls 闭包 |
| HTTPMediaCache 直接改写播放器 URL | 可选 product 生成代理 `PlaybackSource` 后再 `load` |

1.0.0 不保留兼容别名。调用方应迁移到新的模块入口，避免继续依赖旧类型名或旧回调协议。

## 状态订阅

播放状态统一来自 session 快照和事件：

```swift
session.statePublisher
    .sink { snapshot in
        render(snapshot.engine.playbackState)
    }
    .store(in: &cancellables)

session.eventPublisher
    .sink { event in
        handle(event)
    }
    .store(in: &cancellables)
```

## 控制层

UIKit 自定义控制层实现 `UIKitControlOverlay`：

```swift
import AlloyPlayer
import UIKit

final class CustomOverlay: UIView, UIKitControlOverlay {
    var actionHandler: ((PlaybackControlAction) -> Void)?

    func render(state: PlaybackStateSnapshot) {
        // 根据快照刷新 UI。
    }

    func handle(event: PlaybackEvent) {
        // 根据事件刷新一次性 UI。
    }
}
```

控制层通过 `actionHandler` 发出 `.play`、`.pause`、`.seek`、`.toggleFullscreen` 等动作，不直接持有播放引擎。

## SwiftUI

SwiftUI 入口改为外部控制句柄和播放器视图：

```swift
let controller = AlloyPlayerController(
    source: PlaybackSource(url: videoURL)
)

AlloySwiftUIPlayerView(controller: controller)
```

加载视频源：

```swift
controller.load(PlaybackSource(url: videoURL))
```

## 列表播放

列表播放协调器现在驱动 `AlloyPlayerUIKit.AlloyPlayerView`，候选项使用稳定 `id` 和 `PlaybackSource`：

```swift
let coordinator = ListPlaybackCoordinator(playerView: playerView)
coordinator.configuration.minimumVisiblePercent = 0.5

let selected = coordinator.update(
    candidates: candidates,
    viewport: collectionView.bounds,
    containerProvider: { candidate in
        containerView(for: candidate.id)
    }
)
```

## HTTPMediaCache

HTTPMediaCache 支持由 `AlloyPlayerHTTPMediaCacheSupport` 可选 product 提供，不进入 `AlloyPlayer` umbrella product 的依赖图。需要缓存播放时，先通过该 product 生成代理 `PlaybackSource`，再调用 `playerView.load(proxySource)`。

## 渲染承载

自定义播放引擎通过 `renderSurface` 暴露渲染承载。UIKit 层会通过内部渲染宿主自动挂载 `LayerBackedRenderSurface`。
