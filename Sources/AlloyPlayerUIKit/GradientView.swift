//
//  GradientView.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import UIKit

    @MainActor
    final class GradientView: UIView {
        private let gradientLayer = CAGradientLayer()
        private let isTopToBottom: Bool

        init(isTopToBottom: Bool = true) {
            self.isTopToBottom = isTopToBottom
            super.init(frame: .zero)
            layer.addSublayer(gradientLayer)
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(isTopToBottom ? 0.6 : 0).cgColor,
                UIColor.black.withAlphaComponent(isTopToBottom ? 0 : 0.6).cgColor,
            ]
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            gradientLayer.frame = bounds
            CATransaction.commit()
        }
    }
#endif
