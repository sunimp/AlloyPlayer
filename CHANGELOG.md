# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-14

### Added

- Initial release of AlloyPlayer.
- **AlloyCore**: `PlaybackEngine` protocol defining the standard video playback engine interface.
- **AlloyCore**: `ControlOverlay` protocol defining the control UI layer interface.
- **AlloyCore**: `Player` main controller coordinating engine, overlay, gestures, and orientation.
- **AlloyCore**: `GestureManager` with tap, double-tap, pan, pinch, and long-press support.
- **AlloyCore**: `OrientationManager` for landscape and portrait fullscreen transitions.
- **AlloyCore**: `FloatingView` draggable PiP window for list playback.
- **AlloyCore**: `ReachabilityMonitor` for network status monitoring (WiFi/2G/3G/4G/5G).
- **AlloyCore**: `RenderView`, `KVOManager`, `SystemEventObserver` utilities.
- **AlloyCore**: Full enum/OptionSet suite: `PlaybackState`, `LoadState`, `ScalingMode`, `FullScreenMode`, `GestureType`, `PanDirection`, `ReachabilityStatus`, and more.
- **AlloyAVPlayer**: `AVPlayerManager` — AVFoundation-based `PlaybackEngine` implementation.
- **AlloyControlView**: `DefaultControlOverlay` with `PortraitControlPanel`, `LandscapeControlPanel`, and `FloatingControlPanel`.
- **AlloyControlView**: `ProgressSlider`, `BufferingIndicator`, `LoadingIndicator`, `VolumeAndBrightnessHUD`, `NetworkSpeedMonitor`, `CustomStatusBar`.
- Combine publishers for all playback states, time updates, buffer progress, errors, and orientation changes.
- ScrollView/TableView/CollectionView list playback with automatic play/pause on scroll.
- Swift 6 strict concurrency support with `@MainActor` isolation and `Sendable` conformance.
