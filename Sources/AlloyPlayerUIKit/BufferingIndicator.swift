//
//  BufferingIndicator.swift
//  AlloyPlayerUIKit
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 缓冲指示器
    ///
    /// 组合 LoadingIndicator（菊花动画）+ 网速标签。
    @MainActor
    public final class BufferingIndicator: UIView {
        /// 加载动画视图。
        public private(set) var loadingView: LoadingIndicator = {
            let v = LoadingIndicator()
            v.lineWidth = 2
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

        /// 网速文本标签。
        public private(set) var speedLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .systemFont(ofSize: 12)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        override public init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(loadingView)
            addSubview(speedLabel)
            NSLayoutConstraint.activate([
                loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
                loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
                loadingView.widthAnchor.constraint(equalToConstant: 44),
                loadingView.heightAnchor.constraint(equalToConstant: 44),
                speedLabel.topAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: 4),
                speedLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
        }

        /// 不支持从 Interface Builder 或 Storyboard 创建。
        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// 开始显示缓冲动画。
        public func startAnimating() {
            loadingView.startAnimating(); isHidden = false
        }

        /// 停止显示缓冲动画。
        public func stopAnimating() {
            loadingView.stopAnimating(); isHidden = true
        }
    }
#endif
