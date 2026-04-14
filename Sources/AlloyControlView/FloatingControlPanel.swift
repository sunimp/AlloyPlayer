//
//  FloatingControlPanel.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import Combine
    import UIKit

    /// 小窗控制面板
    ///
    /// 显示在浮窗上的简易控制层，包含关闭按钮。
    @MainActor
    public final class FloatingControlPanel: UIView {
        private let _closeTap = PassthroughSubject<Void, Never>()
        public var closeTapPublisher: AnyPublisher<Void, Never> {
            _closeTap.eraseToAnyPublisher()
        }

        private lazy var closeButton: UIButton = {
            let btn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
            btn.tintColor = .white
            btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            return btn
        }()

        override public init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(closeButton)
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                closeButton.widthAnchor.constraint(equalToConstant: 30),
                closeButton.heightAnchor.constraint(equalToConstant: 30),
            ])
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func closeTapped() {
            _closeTap.send()
        }
    }
#endif
