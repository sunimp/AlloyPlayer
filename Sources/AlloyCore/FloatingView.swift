//
//  FloatingView.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 小窗浮窗视图
    ///
    /// 支持拖拽移动，自动限制在父视图安全区域内。
    @MainActor
    public final class FloatingView: UIView {
        // MARK: - 属性

        /// 父视图（弱引用）
        public weak var parentView: UIView? {
            didSet {
                guard let parentView else { return }
                if superview !== parentView {
                    parentView.addSubview(self)
                }
            }
        }

        /// 安全边距
        public var safeInsets: UIEdgeInsets = .zero

        // MARK: - 内部

        private lazy var panGesture: UIPanGestureRecognizer = .init(target: self, action: #selector(handlePan(_:)))

        // MARK: - 初始化

        override public init(frame: CGRect) {
            super.init(frame: frame)
            addGestureRecognizer(panGesture)
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - 拖拽处理

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard gesture.state == .changed, let parentView else { return }

            let translation = gesture.translation(in: parentView)
            var newCenter = CGPoint(
                x: center.x + translation.x,
                y: center.y + translation.y
            )

            // 限制在父视图安全区域内
            let halfWidth = bounds.width / 2
            let halfHeight = bounds.height / 2
            let minX = halfWidth + safeInsets.left
            let maxX = parentView.bounds.width - halfWidth - safeInsets.right
            let minY = halfHeight + safeInsets.top
            let maxY = parentView.bounds.height - halfHeight - safeInsets.bottom

            newCenter.x = max(minX, min(maxX, newCenter.x))
            newCenter.y = max(minY, min(maxY, newCenter.y))

            center = newCenter
            gesture.setTranslation(.zero, in: parentView)
        }
    }
#endif
