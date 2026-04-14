//
//  ProgressSlider.swift
//  AlloyControlView
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
        public private(set) var thumbButton = UIButton(type: .custom)

        // MARK: - 轨道外观

        public var maximumTrackTintColor: UIColor = .init(white: 0.5, alpha: 0.3) { didSet { bgTrack.backgroundColor = maximumTrackTintColor } }
        public var minimumTrackTintColor: UIColor = .white {
            didSet { progressTrack.backgroundColor = minimumTrackTintColor }
        }

        public var bufferTrackTintColor: UIColor = .init(white: 1.0, alpha: 0.5) { didSet { bufferTrack.backgroundColor = bufferTrackTintColor } }
        public var loadingTintColor: UIColor = .white {
            didSet { loadingBar.backgroundColor = loadingTintColor }
        }

        public var maximumTrackImage: UIImage?
        public var minimumTrackImage: UIImage?
        public var bufferTrackImage: UIImage?

        // MARK: - 值

        public var value: Float = 0 {
            didSet { setNeedsLayout() }
        }

        public var bufferValue: Float = 0 {
            didSet { setNeedsLayout() }
        }

        // MARK: - 配置

        public var isTapEnabled = true
        public var isAnimated = true
        public var trackHeight: CGFloat = 2
        public var trackCornerRadius: CGFloat = 1
        public var isThumbHidden = false {
            didSet { thumbButton.isHidden = isThumbHidden }
        }

        public private(set) var isDragging = false
        public private(set) var isForward = false
        public var thumbSize = CGSize(width: 19, height: 19)

        // MARK: - Delegate

        public weak var delegate: ProgressSliderDelegate?

        // MARK: - Combine Subjects

        private let _touchBegan = PassthroughSubject<Float, Never>()
        private let _valueChanged = PassthroughSubject<Float, Never>()
        private let _touchEnded = PassthroughSubject<Float, Never>()
        private let _tapped = PassthroughSubject<Float, Never>()

        public var touchBeganPublisher: AnyPublisher<Float, Never> {
            _touchBegan.eraseToAnyPublisher()
        }

        public var valueChangedPublisher: AnyPublisher<Float, Never> {
            _valueChanged.eraseToAnyPublisher()
        }

        public var touchEndedPublisher: AnyPublisher<Float, Never> {
            _touchEnded.eraseToAnyPublisher()
        }

        public var tappedPublisher: AnyPublisher<Float, Never> {
            _tapped.eraseToAnyPublisher()
        }

        // MARK: - 内部视图

        private let bgTrack = UIView()
        private let bufferTrack = UIView()
        private let progressTrack = UIView()
        private let loadingBar = UIView()
        private var previousValue: Float = 0

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
            setupGestures()
        }

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

            thumbButton.adjustsImageWhenHighlighted = false
        }

        private func setupGestures() {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            thumbButton.addGestureRecognizer(pan)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            bgTrack.isUserInteractionEnabled = true
            bgTrack.addGestureRecognizer(tap)
        }

        // MARK: - 布局

        override public func layoutSubviews() {
            super.layoutSubviews()
            let trackY = (bounds.height - trackHeight) / 2
            let trackWidth = bounds.width - thumbSize.width

            bgTrack.frame = CGRect(x: thumbSize.width / 2, y: trackY, width: trackWidth, height: trackHeight)
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

        // MARK: - 手势处理

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let trackWidth = bounds.width - thumbSize.width
            guard trackWidth > 0 else { return }
            let translation = gesture.translation(in: self)

            switch gesture.state {
            case .began:
                isDragging = true
                previousValue = value
                _touchBegan.send(value)
                delegate?.sliderTouchBegan(self, value: value)
                UIView.animate(withDuration: 0.2) {
                    self.thumbButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }

            case .changed:
                let delta = Float(translation.x / trackWidth)
                let newValue = min(max(previousValue + delta, 0), 1)
                isForward = newValue > value
                value = newValue
                _valueChanged.send(value)
                delegate?.sliderValueChanged(self, value: value)

            case .ended, .cancelled, .failed:
                isDragging = false
                _touchEnded.send(value)
                delegate?.sliderTouchEnded(self, value: value)
                UIView.animate(withDuration: 0.2) {
                    self.thumbButton.transform = .identity
                }

            default:
                break
            }
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard isTapEnabled else { return }
            let point = gesture.location(in: bgTrack)
            let trackWidth = bgTrack.bounds.width
            guard trackWidth > 0 else { return }
            let newValue = Float(point.x / trackWidth)
            value = min(max(newValue, 0), 1)
            _tapped.send(value)
            delegate?.sliderTapped(self, value: value)
        }

        // MARK: - 公开方法

        /// 开始加载动画
        public func startLoading() {
            progressTrack.isHidden = true
            bufferTrack.isHidden = true
            thumbButton.isHidden = true
            loadingBar.isHidden = false

            let trackWidth = bgTrack.bounds.width
            loadingBar.frame = CGRect(x: bgTrack.frame.minX, y: bgTrack.frame.minY, width: 0, height: trackHeight)

            let scaleAnimation = CABasicAnimation(keyPath: "transform.scaleX")
            scaleAnimation.fromValue = 0
            scaleAnimation.toValue = trackWidth / 10

            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 1.0
            opacityAnimation.toValue = 0.0

            let group = CAAnimationGroup()
            group.duration = 0.4
            group.repeatCount = .infinity
            group.animations = [scaleAnimation, opacityAnimation]
            loadingBar.layer.add(group, forKey: "loading")
        }

        /// 停止加载动画
        public func stopLoading() {
            loadingBar.layer.removeAllAnimations()
            loadingBar.isHidden = true
            progressTrack.isHidden = false
            bufferTrack.isHidden = false
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
    }
#endif
