//
//  LoadingIndicator.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import AlloyCore
    import UIKit

    /// 加载动画指示器
    ///
    /// 圆形旋转加载动画，支持 keep（持续旋转）和 fadeOut（渐隐）两种动画类型。
    @MainActor
    public final class LoadingIndicator: UIView {
        // MARK: - 属性

        /// 动画类型
        public var animationType: LoadingType = .keep

        /// 线条颜色
        public var lineColor: UIColor = .white {
            didSet { shapeLayer.strokeColor = lineColor.cgColor }
        }

        /// 线条宽度
        public var lineWidth: CGFloat = 1.5 {
            didSet { shapeLayer.lineWidth = lineWidth }
        }

        /// 停止时隐藏
        public var hidesWhenStopped = true

        /// 动画时长
        public var animationDuration: TimeInterval = 1.0

        /// 是否正在动画
        public private(set) var isAnimating = false

        // MARK: - 内部

        private lazy var shapeLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.strokeColor = lineColor.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = lineWidth
            layer.lineCap = .round
            layer.strokeStart = 0.1
            layer.strokeEnd = 1.0
            return layer
        }()

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            isHidden = hidesWhenStopped
            layer.addSublayer(shapeLayer)
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            shapeLayer.frame = bounds
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2 - lineWidth
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            shapeLayer.path = path.cgPath
        }

        // MARK: - 方法

        /// 开始动画
        public func startAnimating() {
            guard !isAnimating else { return }
            isAnimating = true
            isHidden = false

            let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.fromValue = 0
            rotation.toValue = CGFloat.pi * 2
            rotation.duration = animationDuration
            rotation.repeatCount = .infinity
            rotation.isRemovedOnCompletion = false
            shapeLayer.add(rotation, forKey: "rotation")

            if animationType == .fadeOut {
                addFadeOutAnimation()
            }
        }

        /// 停止动画
        public func stopAnimating() {
            guard isAnimating else { return }
            isAnimating = false
            shapeLayer.removeAllAnimations()
            if hidesWhenStopped { isHidden = true }
        }

        private func addFadeOutAnimation() {
            let strokeEnd = CABasicAnimation(keyPath: "strokeEnd")
            strokeEnd.fromValue = 0
            strokeEnd.toValue = 1.0
            strokeEnd.duration = animationDuration / 1.5
            strokeEnd.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let strokeStart = CABasicAnimation(keyPath: "strokeStart")
            strokeStart.fromValue = 0
            strokeStart.toValue = 0.25
            strokeStart.duration = animationDuration / 1.5
            strokeStart.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let strokeStartLate = CABasicAnimation(keyPath: "strokeStart")
            strokeStartLate.fromValue = 0.25
            strokeStartLate.toValue = 1.0
            strokeStartLate.beginTime = animationDuration / 1.5
            strokeStartLate.duration = animationDuration / 3
            strokeStartLate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let group = CAAnimationGroup()
            group.duration = animationDuration
            group.repeatCount = .infinity
            group.isRemovedOnCompletion = false
            group.animations = [strokeEnd, strokeStart, strokeStartLate]
            shapeLayer.add(group, forKey: "fadeOut")
        }
    }
#endif
