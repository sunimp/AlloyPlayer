# 列表浮窗播放重构交接

日期：2026-05-13

## 背景

TableView 和 CollectionView 列表播放的旧方案把完整的 `AlloyPlayerView` 在 cell 和浮窗之间搬迁。`AlloyPlayerView` 同时包含渲染层、控制层、手势、状态绑定，滚动刷新时会反复触发 reattach、控制层安装、自动隐藏计时和 window detach，导致：

- cell 控制层点开后很快消失，和列表滚动刷新/重复 reattach 有关。
- cell 到浮窗的播放状态和进度衔接不稳定，迁移过程容易被 view detach 或控制层替换影响。

本次已推翻旧方案，改为拆分渲染宿主和控制宿主。

## 当前架构

新增 `AlloyPlayerRenderView`，只负责承载同一个 `PlaybackSession` 的渲染 layer。底层 `AVPlayerLayer` 同一时间只能挂在一个宿主上，因此该 view 负责在 cell 和浮窗之间迁移唯一渲染层。

新增 `AlloyPlayerControlView`，只负责控制层、手势、`PlaybackSession` action 转发。inline cell 和 floating window 可以各自拥有独立控制宿主，但共享同一个 `PlaybackSession`。

列表页现在使用：

- cell 内：`AlloyPlayerRenderView + AlloyPlayerControlView(DefaultControlOverlay)`
- 浮窗内：同一个 `AlloyPlayerRenderView + AlloyPlayerControlView(FloatingPlaybackOverlay)`
- 播放状态、进度、缓冲状态全部来自同一个 `PlaybackSession`

阈值行为：

- 当前播放 cell 可见比例 `<= 10%` 时进入浮窗。
- 当前播放 cell 可见比例 `>= 90%` 时回到 cell。
- 中间区间不做 reattach，避免滚动中重复刷新控制层。

## 关键文件

- `Sources/AlloyPlayerUIKit/PlayerView/AlloyPlayerRenderView.swift`
- `Sources/AlloyPlayerUIKit/PlayerView/AlloyPlayerControlView.swift`
- `Sources/AlloyListPlayback/ListPlaybackCoordinator.swift`
- `Sources/AlloyListPlayback/FloatingPlaybackCoordinator.swift`
- `Sources/AlloyListPlayback/FloatingPlaybackOverlay.swift`
- `Example/Sources/Modules/TableViewPlayback/TableViewPlaybackViewController.swift`
- `Example/Sources/Modules/CollectionViewPlayback/CollectionViewPlaybackViewController.swift`

## 浮窗控制层

`FloatingPlaybackOverlay` 已改为自定义控制层风格：

- 半透明遮罩
- 中间播放/暂停按钮
- 底部进度条
- `当前时间 / 总时长`
- 右上角关闭按钮

它不重新创建播放器、不重新 load source，只通过共享 `PlaybackSession` 发 play/pause/seek/replay action。

## 验证结果

已执行并通过：

```bash
swift test
xcodebuild -project Example/AlloyPlayerDemo.xcodeproj -scheme AlloyPlayerDemo -configuration Debug -destination 'generic/platform=iOS Simulator' build
git diff --check
```

说明：SwiftPM 在 macOS 宿主下不会实际执行 `#if canImport(UIKit)` 内的 UIKit 测试，但 iOS Simulator 编译已覆盖 UIKit 代码路径。

## 未纳入本次提交的现有改动

工作区还有两处未纳入本次提交的改动，提交时刻判断它们不属于列表浮窗架构重构：

- `Example/Sources/Modules/Home/HomeViewController.swift`
- `Example/Sources/Resources/DemoPlaybackConfiguration.swift`

下一会话如需处理，应单独确认这些改动的意图。

## 下一会话建议

1. 在模拟器手动验证 TableView 列表播放：点击 cell 播放，点击控制层，滚动到 `<= 10%` 可见触发浮窗，再滚回 `>= 90%` 可见回 cell。
2. 同样验证 CollectionView 列表播放。
3. 重点观察控制层是否仍因滚动刷新瞬间消失，浮窗和 cell 的播放进度、播放状态是否完全连续。
4. 如手动验证通过，再考虑为 iOS UI 行为补更具体的集成测试或截图验证。
