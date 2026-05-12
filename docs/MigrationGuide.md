# AlloyPlayer 迁移指南

本文档记录架构重构后的主要破坏性变更和迁移方式。目标是让调用方选择更少、入口更清晰，同时把可维护性问题收敛到模块边界内。

## SwiftUI 播放器入口

使用 umbrella 模块时，默认 AVPlayer 体验不变：

```swift
import AlloyPlayer

AlloyPlayerView(url: url)
```

`AlloySwiftUIControls` 不再依赖 `AlloyAVPlayer`。如果调用方只引入该模块，需要显式提供播放引擎：

```swift
import AlloySwiftUIControls

AlloyPlayerView(
    url: url,
    engineFactory: { CustomPlaybackEngine() }
)
```

## 播放状态订阅

推荐主路径是统一状态流和事件流：

```swift
player.statePublisher
    .sink { state in
        render(state)
    }
    .store(in: &cancellables)

player.eventPublisher
    .sink { event in
        handle(event)
    }
    .store(in: &cancellables)
```

## 控制层协议

`ControlOverlay` 被拆成更小的事件 sink 协议组合：

- `PlaybackEventSink`
- `GestureEventSink`
- `OrientationEventSink`
- `ListPlaybackEventSink`

自定义控制层如果只关心部分事件，可以直接实现对应的小协议；完整控制层继续实现 `ControlOverlay`。

## 列表播放

列表播放能力从 `Player` 的职责中迁出到 `AlloyListPlayback`：

```swift
import AlloyPlayer

let coordinator = ListPlaybackCoordinator(player: player)
coordinator.playBestCandidate(
    in: candidates,
    viewport: collectionView.bounds,
    minimumVisiblePercent: 0.5,
    containerProvider: { candidate in
        containerView(for: candidate.indexPath)
    }
)
```

浮动小窗也由列表播放模块协调：

```swift
let floatingPlayback = FloatingPlaybackCoordinator(
    player: player,
    parentView: view
)
floatingPlayback.show()
floatingPlayback.hide()
```

## HTTPMediaCache

进阶配置统一使用 `AlloyHTTPMediaCacheConfiguration`，不再提供拆散的 `port`、`bindToLocalhost`、`requestHeaders` 重载：

```swift
let configuration = AlloyHTTPMediaCacheConfiguration(
    port: 0,
    bindToLocalhost: true,
    requestHeaders: [
        "Authorization": "Bearer token",
    ]
)

let proxyURL = try await AlloyHTTPMediaCacheSupport.proxyURL(
    for: originalURL,
    configuration: configuration
)
```

默认场景仍可直接调用：

```swift
let proxyURL = try await AlloyHTTPMediaCacheSupport.proxyURL(for: originalURL)
```

## 渲染承载面

`PlaybackEngine` 新增 `renderSurface` 默认入口。现有基于 `RenderView` 的引擎无需修改；自定义引擎可以逐步把更复杂的渲染承载能力收敛到 `PlaybackRenderSurface`。
