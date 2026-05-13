//
//  FloatingPlaybackCoordinator.swift
//  AlloyListPlayback
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import AlloyCore
    import AlloyPlayerUIKit
    import UIKit

    /// 浮窗播放协调器。
    @MainActor
    public final class FloatingPlaybackCoordinator {
        /// 浮窗播放使用的播放会话。
        public let session: PlaybackSession

        /// 浮窗内承载视频画面的渲染视图。
        public let renderView: AlloyPlayerUIKit.AlloyPlayerRenderView

        /// 浮窗当前是否可见。
        public private(set) var isVisible = false

        /// 浮窗控制层使用的时间格式化配置。
        public var timeFormatterConfiguration = TimeFormatter.defaultConfiguration {
            didSet {
                floatingOverlay.timeFormatterConfiguration = timeFormatterConfiguration
            }
        }

        private var floatingView: FloatingPlaybackView?
        private let floatingOverlay = FloatingPlaybackOverlay()
        private lazy var controlView = AlloyPlayerUIKit.AlloyPlayerControlView(
            session: session,
            controlOverlay: floatingOverlay,
            gestureController: nil
        )
        private weak var legacyPlayerView: AlloyPlayerUIKit.AlloyPlayerView?
        private var controlViewConstraints: [NSLayoutConstraint] = []
        private var closeHandler: (() -> Void)?

        /// 使用播放会话和渲染视图创建浮窗播放协调器。
        public init(
            session: PlaybackSession,
            renderView: AlloyPlayerUIKit.AlloyPlayerRenderView
        ) {
            self.session = session
            self.renderView = renderView
        }

        /// 使用完整播放器视图创建浮窗播放协调器。
        public convenience init(playerView: AlloyPlayerUIKit.AlloyPlayerView) {
            self.init(
                session: playerView.session,
                renderView: AlloyPlayerUIKit.AlloyPlayerRenderView(session: playerView.session)
            )
            legacyPlayerView = playerView
            playerView.configuration.attachesRenderSurfaceAutomatically = false
        }

        /// 在父视图中显示浮窗。
        public func show(in parentView: UIView, frame: CGRect) {
            let hostView = parentView.window ?? parentView
            let hostFrame = parentView === hostView ? frame : parentView.convert(frame, to: hostView)
            let floatingView = floatingView ?? FloatingPlaybackView(frame: frame)
            self.floatingView = floatingView
            floatingView.frame = hostFrame
            floatingView.closeAction = { [weak self] in
                self?.close()
            }

            if floatingView.superview !== hostView {
                hostView.addSubview(floatingView)
            }

            legacyPlayerView?.removeFromSuperview()
            floatingView.attach(renderView)
            renderView.activateRenderSurface()
            installFloatingControls(in: floatingView)
            isVisible = true
        }

        /// 设置浮窗关闭回调。
        public func setCloseHandler(_ handler: (() -> Void)?) {
            closeHandler = handler
        }

        /// 隐藏浮窗并解除控制层挂载。
        public func hide() {
            uninstallFloatingControls()
            floatingView?.detach()
            floatingView?.removeFromSuperview()
            floatingView = nil
            isVisible = false
        }

        private func installFloatingControls(in floatingView: FloatingPlaybackView) {
            floatingOverlay.closeAction = { [weak self] in
                self?.close()
            }

            guard controlView.superview !== floatingView else { return }
            uninstallFloatingControls()
            controlView.translatesAutoresizingMaskIntoConstraints = false
            floatingView.addSubview(controlView)
            controlViewConstraints = [
                controlView.topAnchor.constraint(equalTo: floatingView.topAnchor),
                controlView.leadingAnchor.constraint(equalTo: floatingView.leadingAnchor),
                controlView.trailingAnchor.constraint(equalTo: floatingView.trailingAnchor),
                controlView.bottomAnchor.constraint(equalTo: floatingView.bottomAnchor),
            ]
            NSLayoutConstraint.activate(controlViewConstraints)
        }

        private func uninstallFloatingControls() {
            NSLayoutConstraint.deactivate(controlViewConstraints)
            controlViewConstraints.removeAll()
            controlView.removeFromSuperview()
        }

        private func close() {
            closeHandler?()
            hide()
        }
    }
#endif
