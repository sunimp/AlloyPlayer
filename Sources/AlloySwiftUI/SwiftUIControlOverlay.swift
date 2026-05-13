//
//  SwiftUIControlOverlay.swift
//  AlloySwiftUI
//
//  Created by Sun on 2026/5/9.
//

#if canImport(UIKit) && canImport(SwiftUI)
    import AlloyCore
    import SwiftUI
    import UIKit

    /// 将 SwiftUI 控制界面桥接为 AlloyPlayer 控制层
    @MainActor
    public final class SwiftUIControlOverlay<Content: View>: UIView, ControlOverlay {
        public weak var player: Player? {
            didSet {
                state.attach(player: player)
                updateRootView()
            }
        }

        public let state: SwiftUIControlOverlayState

        public var gestureTriggerCondition: ((GestureType, UIGestureRecognizer, UITouch) -> Bool)?
        public var onSingleTap: ((SwiftUIControlOverlayState) -> Void)?
        public var onDoubleTap: ((SwiftUIControlOverlayState) -> Void)?
        public var onPanBegan: ((SwiftUIControlOverlayState, PanDirection, PanLocation) -> Void)?
        public var onPanChanged: ((SwiftUIControlOverlayState, PanDirection, PanLocation, CGPoint) -> Void)?
        public var onPanEnded: ((SwiftUIControlOverlayState, PanDirection, PanLocation) -> Void)?
        public var onPinch: ((SwiftUIControlOverlayState, Float) -> Void)?
        public var onLongPress: ((SwiftUIControlOverlayState, LongPressPhase) -> Void)?

        private let content: (SwiftUIControlOverlayState) -> Content
        private var hostingController: UIHostingController<Content>?

        public convenience init(
            @ViewBuilder content: @escaping (SwiftUIControlOverlayState) -> Content
        ) {
            self.init(state: SwiftUIControlOverlayState(), content: content)
        }

        public init(
            state: SwiftUIControlOverlayState,
            @ViewBuilder content: @escaping (SwiftUIControlOverlayState) -> Content
        ) {
            self.state = state
            self.content = content
            super.init(frame: .zero)
            setupHostingController()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func player(_: Player, prepareToPlay assetURL: URL) {
            state.updatePrepareToPlay(url: assetURL)
        }

        public func player(_: Player, didChangePlaybackState playbackState: PlaybackState) {
            state.updatePlaybackState(playbackState)
        }

        public func player(_: Player, didChangeLoadState loadState: LoadState) {
            state.updateLoadState(loadState)
        }

        public func player(_: Player, didUpdateTime currentTime: TimeInterval, totalTime: TimeInterval) {
            state.updateTime(current: currentTime, total: totalTime)
        }

        public func player(_: Player, didUpdateBufferTime bufferTime: TimeInterval) {
            state.updateBufferTime(bufferTime)
        }

        public func playerDidPlayToEnd(_: Player) {
            state.updatePlayToEnd()
        }

        public func player(_: Player, didFailWithError error: any Error) {
            state.updateError(error)
        }

        public func player(_: Player, didChangeLockState isLocked: Bool) {
            state.updateLockState(isLocked)
        }

        public func player(_ player: Player, willChangeOrientation _: OrientationManager) {
            state.updateOrientation(player: player)
        }

        public func player(_ player: Player, didChangeOrientation _: OrientationManager) {
            state.updateOrientation(player: player)
        }

        public func player(_: Player, didChangeReachability status: ReachabilityStatus) {
            state.updateReachability(status)
        }

        public func player(_: Player, didChangePresentationSize size: CGSize) {
            state.updatePresentationSize(size)
        }

        public func gestureTriggerCondition(
            _: GestureManager,
            type: GestureType,
            recognizer: UIGestureRecognizer,
            touch: UITouch
        ) -> Bool {
            gestureTriggerCondition?(type, recognizer, touch) ?? true
        }

        public func gestureSingleTapped(_: GestureManager) {
            state.updateGesture(.singleTap)
            state.toggleControls()
            onSingleTap?(state)
        }

        public func gestureDoubleTapped(_: GestureManager) {
            state.updateGesture(.doubleTap)
            onDoubleTap?(state)
        }

        public func gestureBeganPan(_: GestureManager, direction: PanDirection, location: PanLocation) {
            state.updateGesture(.pan)
            onPanBegan?(state, direction, location)
        }

        public func gestureChangedPan(_: GestureManager, direction: PanDirection, location: PanLocation, velocity: CGPoint) {
            state.updateGesture(.pan)
            onPanChanged?(state, direction, location, velocity)
        }

        public func gestureEndedPan(_: GestureManager, direction: PanDirection, location: PanLocation) {
            state.updateGesture(.pan)
            onPanEnded?(state, direction, location)
        }

        public func gesturePinched(_: GestureManager, scale: Float) {
            state.updateGesture(.pinch)
            onPinch?(state, scale)
        }

        public func longPressed(_: GestureManager, state phase: LongPressPhase) {
            state.updateGesture(.unknown)
            onLongPress?(state, phase)
        }

        public func player(_ player: Player, floatViewShow isShow: Bool) {
            state.updateOrientation(player: player)
            state.updateFloatingViewVisible(isShow)
        }

        private func setupHostingController() {
            backgroundColor = .clear
            let controller = UIHostingController(rootView: content(state))
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(controller.view)
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: topAnchor),
                controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                controller.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            hostingController = controller
        }

        private func updateRootView() {
            hostingController?.rootView = content(state)
        }
    }
#endif
