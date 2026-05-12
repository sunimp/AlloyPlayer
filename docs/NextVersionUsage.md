# AlloyPlayer Next Version Usage

本文档定义下一版优先服务的调用方式。后续重构以这些调用体验为约束。

## SwiftUI 默认播放器

```swift
import AlloyPlayer

struct VideoScreen: View {
    let url: URL

    var body: some View {
        AlloyPlayerView(url: url)
    }
}
```

## SwiftUI 自定义控制层

```swift
import AlloyPlayer

struct VideoScreen: View {
    let url: URL

    var body: some View {
        AlloyPlayerView(url: url) { state in
            CustomControls(state: state)
        }
    }
}
```

## SwiftUI 自定义播放引擎

```swift
import AlloySwiftUIControls

struct VideoScreen: View {
    let url: URL

    var body: some View {
        AlloyPlayerView(
            url: url,
            engineFactory: { CustomPlaybackEngine() }
        ) { state in
            CustomControls(state: state)
        }
    }
}
```

## UIKit 默认组合

```swift
import AlloyPlayer

let engine = AVPlayerManager()
let player = Player(engine: engine, containerView: containerView)
player.controlOverlay = DefaultControlOverlay()
player.assetURL = url
```

## 状态订阅

```swift
let stateCancellable = player.statePublisher.sink { state in
    render(state)
}

let eventCancellable = player.eventPublisher.sink { event in
    handle(event)
}
```

## 列表播放

```swift
import AlloyPlayer

let listPlayback = ListPlaybackCoordinator(player: player)
let candidates = visibleCells.map {
    ListPlaybackCandidate(indexPath: $0.indexPath, frame: $0.frame, assetURL: $0.url)
}

listPlayback.playBestCandidate(
    in: candidates,
    viewport: collectionView.bounds,
    minimumVisiblePercent: 0.5,
    containerProvider: { candidate in
        containerView(for: candidate.indexPath)
    }
)
```

## 浮动小窗

```swift
import AlloyPlayer

let floatingPlayback = FloatingPlaybackCoordinator(player: player, parentView: view)
floatingPlayback.show()
floatingPlayback.hide()
```
