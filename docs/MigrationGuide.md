# AlloyPlayer 迁移指南

本文档记录 2.0 架构重构后的主要破坏性变更和迁移方式。2.0 不保留兼容别名，调用方需要迁移到 `PlaybackSession`、`AlloyUIKit.AlloyPlayerView` 和 `PlaybackSource`。

## 播放入口

旧入口以核心控制器直接绑定容器视图。新入口先创建 session，再交给 UIKit 或 SwiftUI 播放视图承载：

```swift
import AlloyPlayer

let session = AlloyPlayerFactory.makeDefaultSession()
let playerView = AlloyUIKit.AlloyPlayerView(session: session)
playerView.controlOverlay = DefaultControlOverlay()
playerView.load(PlaybackSource(url: videoURL))
```

自定义播放引擎时直接创建 `PlaybackSession`：

```swift
let session = PlaybackSession(engine: CustomPlaybackEngine())
let playerView = AlloyUIKit.AlloyPlayerView(session: session)
```

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
    session: AlloyPlayerFactory.makeDefaultSession()
)

AlloySwiftUIPlayerView(controller: controller)
```

加载视频源：

```swift
controller.load(PlaybackSource(url: videoURL))
```

## 列表播放

列表播放协调器现在驱动 `AlloyUIKit.AlloyPlayerView`，候选项使用稳定 `id` 和 `PlaybackSource`：

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

缓存支持层生成代理播放源，调用方再把播放源加载到播放器视图：

```swift
let proxySource = try await AlloyHTTPMediaCacheSupport.proxySource(
    for: PlaybackSource(url: originalURL),
    configuration: .default
)

playerView.load(proxySource)
```

## 渲染承载

自定义播放引擎通过 `renderSurface` 暴露渲染承载。UIKit 层会把 `LayerBackedRenderSurface` 自动挂载到 `RenderHostView`。
