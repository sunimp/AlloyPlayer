# AlloyPlayer

[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-F05138.svg)](https://swift.org)
[![Platform iOS 15.0+](https://img.shields.io/badge/Platform-iOS%2015.0+-007AFF.svg)](https://developer.apple.com/ios/)
[![License MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)

A modern, pure Swift video player framework. Feature-complete reimplementation of [ZFPlayer](https://github.com/renzifeng/ZFPlayer) with Swift 6 concurrency, Combine event streams, and modular SPM architecture.

## Features

- Protocol-driven plugin architecture (swap engines/UI freely)
- Full portrait & landscape fullscreen support
- ScrollView/TableView/CollectionView list playback
- Rich gesture support (tap, double-tap, pan, pinch, long-press)
- Pluggable `PlaybackEngine` protocol (built-in AVPlayer, bring your own)
- Customizable `ControlOverlay` protocol (built-in `DefaultControlOverlay`)
- Network reachability monitoring (WiFi / 2G / 3G / 4G / 5G)
- Floating PiP window for list playback
- Combine publishers for all events
- Swift 6 strict concurrency safe

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

**Option 1 — Full framework (recommended):**

```swift
dependencies: [
    .package(url: "https://github.com/nicklasundell/AlloyPlayer.git", from: "0.1.0")
]

// In your target:
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyPlayer", package: "AlloyPlayer")
])
```

**Option 2 — Core + AVPlayer engine only (no default UI):**

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyCore", package: "AlloyPlayer"),
    .product(name: "AlloyAVPlayer", package: "AlloyPlayer"),
])
```

**Option 3 — Core only (bring your own engine and UI):**

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyCore", package: "AlloyPlayer")
])
```

**Option 4 — Individual modules:**

```swift
.target(name: "YourApp", dependencies: [
    .product(name: "AlloyCore", package: "AlloyPlayer"),
    .product(name: "AlloyAVPlayer", package: "AlloyPlayer"),
    .product(name: "AlloyControlView", package: "AlloyPlayer"),
])
```

## Quick Start

### Basic Playback

```swift
import AlloyPlayer

class PlayerViewController: UIViewController {
    private var player: Player!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create a container view
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 220))
        view.addSubview(containerView)

        // 2. Create player with AVPlayer engine
        let engine = AVPlayerManager()
        player = Player(engine: engine, containerView: containerView)

        // 3. Set the default control overlay
        player.controlOverlay = DefaultControlOverlay()

        // 4. Set the video URL and playback starts automatically
        player.assetURL = URL(string: "https://example.com/video.mp4")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.isViewControllerDisappear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.isViewControllerDisappear = false
    }
}
```

### List Playback (TableView)

```swift
import AlloyPlayer

class ListPlayerViewController: UIViewController, UITableViewDelegate {
    private var player: Player!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let engine = AVPlayerManager()
        // Initialize with scrollView and containerView tag
        player = Player(scrollView: tableView, engine: engine, containerViewTag: 100)
        player.controlOverlay = DefaultControlOverlay()

        // Configure list playback URLs (grouped by section)
        player.sectionAssetURLs = [
            [
                URL(string: "https://example.com/video1.mp4")!,
                URL(string: "https://example.com/video2.mp4")!,
            ]
        ]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player.playTheIndexPath(indexPath, scrollToTop: true)
    }
}
```

### Custom Control Overlay

```swift
import AlloyCore

class MinimalOverlay: UIView, ControlOverlay {
    var player: Player?

    func gestureSingleTapped(_ gesture: GestureManager) {
        guard let player else { return }
        player.engine.isPlaying ? player.engine.pause() : player.engine.play()
    }

    func player(_ player: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {
        // Update your custom time labels
    }

    func player(_ player: Player, didChangePlaybackState state: PlaybackState) {
        // Update play/pause button
    }
}
```

### Custom Playback Engine

```swift
import AlloyCore
import Combine

class CustomEngine: PlaybackEngine {
    var renderView = RenderView()
    var playbackState: PlaybackState = .unknown
    var loadState: LoadState = .unknown
    // ... implement all protocol requirements

    var statePublisher: AnyPublisher<PlaybackState, Never> { /* ... */ }
    // ... implement all publishers

    func prepareToPlay() { /* ... */ }
    func play() { /* ... */ }
    func pause() { /* ... */ }
    func stop() { /* ... */ }
    func seek(to time: TimeInterval) async -> Bool { /* ... */ }
    // ... implement remaining methods
}
```

## Architecture

```
AlloyPlayer (umbrella)
├── AlloyCore          ← Protocols, enums, Player controller
├── AlloyAVPlayer      ← AVPlayer engine implementation
└── AlloyControlView   ← Default control UI
```

## Modules

### AlloyCore

The foundation module containing all protocols, enums, and the `Player` controller.

| Type | Description |
|------|-------------|
| `Player` | Main controller coordinating engine, UI, gestures, and orientation |
| `PlaybackEngine` | Protocol for video playback engines |
| `ControlOverlay` | Protocol for control UI layers |
| `GestureManager` | Tap, pan, pinch, and long-press gesture handling |
| `OrientationManager` | Portrait/landscape fullscreen transitions |
| `FloatingView` | Floating PiP window for list playback |
| `ReachabilityMonitor` | Network status monitoring |
| `RenderView` | Base view for video rendering |
| `PlaybackState` | Playback state enum (unknown/playing/paused/failed/stopped) |
| `LoadState` | Buffer loading state (OptionSet) |
| `ScalingMode` | Video scaling modes (aspectFit/aspectFill/fill) |
| `FullScreenMode` | Fullscreen mode (automatic/landscape/portrait) |

### AlloyAVPlayer

AVFoundation-based playback engine implementation.

| Type | Description |
|------|-------------|
| `AVPlayerManager` | `PlaybackEngine` implementation using AVPlayer |

### AlloyControlView

Default control overlay with portrait and landscape panels.

| Type | Description |
|------|-------------|
| `DefaultControlOverlay` | Full-featured `ControlOverlay` implementation |
| `PortraitControlPanel` | Portrait mode control panel |
| `LandscapeControlPanel` | Landscape mode control panel |
| `FloatingControlPanel` | Floating window control panel |
| `ProgressSlider` | Playback progress slider |
| `BufferingIndicator` | Buffering state indicator |
| `LoadingIndicator` | Loading animation |
| `VolumeAndBrightnessHUD` | Volume/brightness adjustment HUD |
| `NetworkSpeedMonitor` | Network speed display |
| `CustomStatusBar` | Custom status bar for fullscreen |

### AlloyPlayer (umbrella)

Re-exports all three modules for convenient single-import usage.

## License

MIT License. See [LICENSE](LICENSE) for details.
