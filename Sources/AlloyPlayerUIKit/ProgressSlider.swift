//
//  ProgressSlider.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AlloyCore
    import Combine
    import UIKit

    /// 自定义进度滑块
    ///
    /// 三层轨道结构：背景轨道 → 缓冲轨道 → 播放进度轨道 + 滑块按钮。
    /// 支持拖拽、点击跳转、加载动画。
    @MainActor
    public final class ProgressSlider: UIView {
        // MARK: - 子视图

        /// 滑块按钮
        public private(set) var thumbButton: UIButton = ProgressSliderThumbButton(type: .custom)

        // MARK: - 轨道外观

        /// 背景轨道颜色。
        public var maximumTrackTintColor: UIColor = .init(white: 0.5, alpha: 0.3) {
            didSet { bgTrack.backgroundColor = maximumTrackTintColor }
        }

        /// 已播放轨道颜色。
        public var minimumTrackTintColor: UIColor = .white {
            didSet { progressTrack.backgroundColor = minimumTrackTintColor }
        }

        /// 缓冲轨道颜色。
        public var bufferTrackTintColor: UIColor = .init(white: 1.0, alpha: 0.5) {
            didSet { bufferTrack.backgroundColor = bufferTrackTintColor }
        }

        /// 加载动画颜色。
        public var loadingTintColor: UIColor = .white {
            didSet { loadingBar.backgroundColor = loadingTintColor }
        }

        /// 背景轨道图片。
        public var maximumTrackImage: UIImage?

        /// 已播放轨道图片。
        public var minimumTrackImage: UIImage?

        /// 缓冲轨道图片。
        public var bufferTrackImage: UIImage?

        // MARK: - 值

        /// 当前播放进度，范围为 0...1。
        public var value: Float = 0 {
            didSet { setNeedsLayout() }
        }

        /// 当前缓冲进度，范围为 0...1。
        public var bufferValue: Float = 0 {
            didSet { setNeedsLayout() }
        }

        // MARK: - 配置

        /// 是否允许点击轨道跳转。
        public var isTapEnabled = true

        /// 是否使用动画更新布局。
        public var isAnimated = true

        /// 轨道高度。
        public var trackHeight: CGFloat = 2

        /// 轨道圆角半径。
        public var trackCornerRadius: CGFloat = 1

        /// 是否隐藏滑块按钮。
        public var isThumbHidden = false {
            didSet {
                thumbButton.isHidden = isThumbHidden
                setNeedsLayout()
            }
        }

        /// 用户当前是否正在拖动。
        public private(set) var isDragging = false

        /// 本次拖动是否向前。
        public private(set) var isForward = false

        /// 滑块按钮尺寸。
        public var thumbSize = CGSize(width: 19, height: 19)
        var hitTestInsets: UIEdgeInsets = .zero

        // MARK: - Combine Subjects

        private let _touchBegan = PassthroughSubject<Float, Never>()
        private let _valueChanged = PassthroughSubject<Float, Never>()
        private let _touchEnded = PassthroughSubject<Float, Never>()
        private let _tapped = PassthroughSubject<Float, Never>()

        /// 触摸开始发布者。
        public var touchBeganPublisher: AnyPublisher<Float, Never> {
            _touchBegan.eraseToAnyPublisher()
        }

        /// 进度值变化发布者。
        public var valueChangedPublisher: AnyPublisher<Float, Never> {
            _valueChanged.eraseToAnyPublisher()
        }

        /// 触摸结束发布者。
        public var touchEndedPublisher: AnyPublisher<Float, Never> {
            _touchEnded.eraseToAnyPublisher()
        }

        /// 点击轨道发布者。
        public var tappedPublisher: AnyPublisher<Float, Never> {
            _tapped.eraseToAnyPublisher()
        }

        // MARK: - 内部视图

        private let bgTrack = UIView()
        private let bufferTrack = UIView()
        private let progressTrack = UIView()
        private let loadingBar = UIView()

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
            setupGestures()
        }

        /// 不支持从 Interface Builder 或 Storyboard 创建。
        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            bgTrack.backgroundColor = maximumTrackTintColor
            bufferTrack.backgroundColor = bufferTrackTintColor
            progressTrack.backgroundColor = minimumTrackTintColor
            loadingBar.backgroundColor = loadingTintColor
            loadingBar.isHidden = true

            addSubview(bgTrack)
            addSubview(bufferTrack)
            addSubview(progressTrack)
            addSubview(loadingBar)
            addSubview(thumbButton)

            thumbButton.tintColor = .white
            let thumbConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            thumbButton.setImage(UIImage(systemName: "circle.fill", withConfiguration: thumbConfig), for: .normal)
        }

        private func setupGestures() {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            addGestureRecognizer(pan)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            addGestureRecognizer(tap)
        }

        // MARK: - 布局

        override public func layoutSubviews() {
            super.layoutSubviews()
            performWithoutImplicitLayoutAnimations {
                let trackY = (bounds.height - trackHeight) / 2
                let horizontalInset = isThumbHidden ? 0 : thumbSize.width / 2
                let trackWidth = max(0, bounds.width - horizontalInset * 2)

                bgTrack.frame = CGRect(x: horizontalInset, y: trackY, width: trackWidth, height: trackHeight)
                bgTrack.layer.cornerRadius = trackCornerRadius

                let bufferWidth = trackWidth * CGFloat(min(max(bufferValue, 0), 1))
                bufferTrack.frame = CGRect(x: bgTrack.frame.minX, y: trackY, width: bufferWidth, height: trackHeight)
                bufferTrack.layer.cornerRadius = trackCornerRadius

                let clampedValue = CGFloat(min(max(value, 0), 1))
                let progressWidth = trackWidth * clampedValue
                progressTrack.frame = CGRect(x: bgTrack.frame.minX, y: trackY, width: progressWidth, height: trackHeight)
                progressTrack.layer.cornerRadius = trackCornerRadius

                let thumbX = bgTrack.frame.minX + progressWidth - thumbSize.width / 2
                let thumbY = (bounds.height - thumbSize.height) / 2
                thumbButton.frame = CGRect(x: thumbX, y: thumbY, width: thumbSize.width, height: thumbSize.height)
            }
        }

        override public func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
            bounds.inset(by: hitTestInsets).contains(point)
        }

        // MARK: - 手势处理

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let point = gesture.location(in: self)

            switch gesture.state {
            case .began:
                beginTrackInteraction(at: point)

            case .changed:
                updateTrackInteraction(at: point)

            case .ended, .cancelled, .failed:
                endTrackInteraction(at: point)

            default:
                break
            }
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard isTapEnabled else { return }
            let point = gesture.location(in: self)
            value = trackValue(at: point)
            _tapped.send(value)
        }

        // MARK: - 公开方法

        /// 开始加载动画
        public func startLoading() {
            loadingBar.isHidden = false

            let trackWidth = bgTrack.bounds.width
            let loadingWidth = min(max(trackWidth * 0.2, 20), trackWidth)
            loadingBar.frame = CGRect(x: bgTrack.frame.minX, y: bgTrack.frame.minY, width: loadingWidth, height: trackHeight)
            loadingBar.layer.cornerRadius = trackCornerRadius

            let positionAnimation = CABasicAnimation(keyPath: "position.x")
            positionAnimation.fromValue = bgTrack.frame.minX + loadingWidth / 2
            positionAnimation.toValue = bgTrack.frame.maxX - loadingWidth / 2

            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 0.2
            opacityAnimation.toValue = 0.9
            opacityAnimation.autoreverses = true

            let group = CAAnimationGroup()
            group.duration = 0.8
            group.repeatCount = .infinity
            group.animations = [positionAnimation, opacityAnimation]
            loadingBar.layer.add(group, forKey: "loading")
        }

        /// 停止加载动画
        public func stopLoading() {
            loadingBar.layer.removeAllAnimations()
            loadingBar.isHidden = true
            thumbButton.isHidden = isThumbHidden
        }

        /// 设置滑块图片
        public func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
            thumbButton.setImage(image, for: state)
        }

        /// 设置滑块背景图片
        public func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
            thumbButton.setBackgroundImage(image, for: state)
        }

        // MARK: - 内部交互入口

        func beginTrackInteraction(at point: CGPoint) {
            isDragging = true
            updateValueFromTrackPoint(point)
            _touchBegan.send(value)
            UIView.animate(withDuration: 0.2) {
                self.thumbButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
        }

        func updateTrackInteraction(at point: CGPoint) {
            guard isDragging else { return }
            updateValueFromTrackPoint(point)
            _valueChanged.send(value)
        }

        func endTrackInteraction(at point: CGPoint) {
            if isDragging {
                updateValueFromTrackPoint(point)
            }
            isDragging = false
            _touchEnded.send(value)
            UIView.animate(withDuration: 0.2) {
                self.thumbButton.transform = .identity
            }
        }

        private func updateValueFromTrackPoint(_ point: CGPoint) {
            let newValue = trackValue(at: point)
            isForward = newValue > value
            value = newValue
        }

        private func trackValue(at point: CGPoint) -> Float {
            layoutIfNeeded()
            let trackWidth = bgTrack.bounds.width
            guard trackWidth > 0 else { return value }
            let rawValue = (point.x - bgTrack.frame.minX) / trackWidth
            return Float(min(max(rawValue, 0), 1))
        }

        private func performWithoutImplicitLayoutAnimations(_ updates: () -> Void) {
            UIView.performWithoutAnimation {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                updates()
                CATransaction.commit()
            }
        }
    }

    private final class ProgressSliderThumbButton: UIButton {
        override var isHighlighted: Bool {
            get { false }
            set {}
        }
    }
#endif
