# AGENTS.md — AlloyPlayer Development Guide

## Project Overview

AlloyPlayer is a modern, pure Swift video player framework — a feature-complete reimplementation of ZFPlayer. It uses Swift 6 strict concurrency, Combine event streams, UIKit + Auto Layout, and is distributed exclusively via Swift Package Manager.

### Repository Layout

```
AlloyPlayer/
├── Package.swift
├── Sources/
│   ├── AlloyCore/           ← Protocols, enums, Player controller
│   ├── AlloyAVPlayer/       ← AVFoundation playback engine
│   ├── AlloyControlView/    ← Default control UI + resources
│   └── AlloyPlayer/         ← Umbrella re-export module
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

### Module Dependency Graph

```
AlloyPlayer (umbrella)
├── AlloyCore
├── AlloyAVPlayer      → depends on AlloyCore
└── AlloyControlView   → depends on AlloyCore
```

## Tech Stack Constraints

- **Language**: Swift 6.3, strict concurrency mode (`swiftLanguageModes: [.v6]`)
- **Minimum deployment**: iOS 15.0, macOS 12.0 (macOS for SPM test host only)
- **Package manager**: SPM only — no CocoaPods, no Carthage
- **Event communication**: Combine (`AnyPublisher`, `PassthroughSubject`)
- **UI framework**: UIKit + Auto Layout — no SwiftUI
- **UIKit code** must be wrapped in `#if canImport(UIKit)` guards
- **Main actor isolation**: All UI-facing protocols and classes are `@MainActor`

## Code Conventions

### File Header

Every `.swift` file must start with:

```swift
//
//  FileName.swift
//  ModuleName
//
//  Created by Sun on YYYY/M/D.
//
```

Where `YYYY/M/D` is the actual creation date.

### Language

- **Code comments**: Simplified Chinese (简体中文)
- **Git commit messages**: Simplified Chinese, signed off:
  ```
  简要描述变更内容

  Signed-off-by: Sun <yangguang@webull.com>
  ```
- **Documentation files** (README, CONTRIBUTING, etc.): English

### Formatting

- Run `swiftformat <file>` on **each modified `.swift` file** after editing
- **Never** run directory-level formatting (`swiftformat .` or `swiftformat Sources/`)
- No tabs — use 4 spaces for indentation

### Naming

- Protocols: noun or adjective describing capability (`PlaybackEngine`, `ControlOverlay`)
- Enums: PascalCase type, camelCase cases (`PlaybackState.playing`)
- OptionSets: PascalCase type, camelCase static members (`LoadState.playable`)
- Publishers: suffixed with `Publisher` (`statePublisher`, `playTimePublisher`)

## Development Workflow

1. **TDD cycle**: Write test → verify it fails → implement → verify it passes → commit
2. **One commit per logical unit** of work
3. **No `git push`** without explicit permission from the maintainer
4. **No destructive git operations** (`reset --hard`, `clean -f`, `rebase`, `commit --amend`) unless explicitly requested

## Testing Strategy

- **Unit tests** for pure logic: enums, utilities, state machines
- Tests run on macOS host via `swift test`
- UIKit-dependent classes are wrapped in `#if canImport(UIKit)` — test files follow the same pattern
- Test targets:
  - `AlloyCoreTests` → tests AlloyCore
  - `AlloyAVPlayerTests` → tests AlloyAVPlayer
  - `AlloyControlViewTests` → tests AlloyControlView

### Running Tests

```bash
cd AlloyPlayer
swift test
```

## Key Types Reference

### AlloyCore — Protocols

| Protocol | Actor | Description |
|----------|-------|-------------|
| `PlaybackEngine` | `@MainActor` | Video playback engine interface (play, pause, seek, Combine publishers) |
| `ControlOverlay` | `@MainActor` | Control UI layer interface (inherits `UIView`) |
| `ProgressSliderDelegate` | — | Slider interaction callbacks |

### AlloyCore — Classes

| Class | Description |
|-------|-------------|
| `Player` | Main controller — coordinates engine, overlay, gestures, orientation |
| `GestureManager` | Recognizes tap, double-tap, pan, pinch, long-press; publishes events |
| `OrientationManager` | Manages fullscreen transitions (landscape/portrait) |
| `FloatingView` | Draggable PiP floating window |
| `RenderView` | Base UIView for video rendering layer |
| `ReachabilityMonitor` | Network reachability via NWPathMonitor |
| `SystemEventObserver` | App lifecycle notifications (resign/become active) |
| `KVOManager` | Type-safe KVO wrapper |
| `LandscapeController` | View controller for landscape fullscreen |
| `LandscapeWindow` | Dedicated window for landscape presentation |
| `PortraitController` | View controller for portrait fullscreen |
| `FullScreenTransition` | Custom fullscreen transition animation |
| `InteractiveDismissTransition` | Interactive dismiss gesture for portrait fullscreen |
| `LandscapeRotationHandler` | Device rotation detection and handling |

### AlloyCore — Enums & OptionSets

| Type | Kind | Values |
|------|------|--------|
| `PlaybackState` | enum | `unknown`, `playing`, `paused`, `failed`, `stopped` |
| `LoadState` | OptionSet | `prepare`, `playable`, `playthroughOK`, `stalled` |
| `ScalingMode` | enum | `none`, `aspectFit`, `aspectFill`, `fill` |
| `FullScreenMode` | enum | `automatic`, `landscape`, `portrait` |
| `GestureType` | enum | `unknown`, `singleTap`, `doubleTap`, `pan`, `pinch` |
| `PanDirection` | enum | `unknown`, `vertical`, `horizontal` |
| `PanLocation` | enum | `unknown`, `left`, `right` |
| `LongPressPhase` | enum | `began`, `changed`, `ended` |
| `ReachabilityStatus` | enum | `unknown`, `notReachable`, `wifi`, `cellular2G/3G/4G/5G` |
| `AttachmentMode` | enum | `view`, `cell` |
| `ScrollDirection` | enum | `none`, `up`, `down`, `left`, `right` |
| `DisableGestureTypes` | OptionSet | `singleTap`, `doubleTap`, `pan`, `pinch`, `longPress` |
| `DisablePanMovingDirection` | OptionSet | `vertical`, `horizontal` |

### AlloyAVPlayer

| Class | Description |
|-------|-------------|
| `AVPlayerManager` | `PlaybackEngine` implementation backed by AVFoundation `AVPlayer` |

### AlloyControlView

| Class | Description |
|-------|-------------|
| `DefaultControlOverlay` | Full `ControlOverlay` implementation with portrait/landscape/floating panels |
| `PortraitControlPanel` | Portrait mode controls (play, slider, time, fullscreen button) |
| `LandscapeControlPanel` | Landscape mode controls (extended toolbar) |
| `FloatingControlPanel` | Floating PiP window controls |
| `ProgressSlider` | Custom slider for playback progress |
| `BufferingIndicator` | Shows buffering state |
| `LoadingIndicator` | Loading animation view |
| `VolumeAndBrightnessHUD` | System volume/brightness adjustment overlay |
| `NetworkSpeedMonitor` | Displays current network throughput |
| `CustomStatusBar` | Custom status bar for fullscreen mode |
