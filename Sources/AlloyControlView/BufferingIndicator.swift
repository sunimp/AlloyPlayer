//
//  BufferingIndicator.swift
//  AlloyControlView
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
        public private(set) var loadingView: LoadingIndicator = {
            let v = LoadingIndicator()
            v.lineWidth = 2
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()

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

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func startAnimating() {
            loadingView.startAnimating(); isHidden = false
        }

        public func stopAnimating() {
            loadingView.stopAnimating(); isHidden = true
        }
    }
#endif
