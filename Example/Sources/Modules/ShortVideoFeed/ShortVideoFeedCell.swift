//
//  ShortVideoFeedCell.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import AlloyPlayer
import Combine
import UIKit

// MARK: - ShortVideoFeedCell

/// 全屏视频 Cell（抖音风格）
final class ShortVideoFeedCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    static let reuseIdentifier = "ShortVideoFeedCell"

    /// 点击回调
    var onTap: (() -> Void)?
    var onSeek: ((Float) -> Void)?

    // MARK: - 子视图

    /// 视频容器（tag = 300）
    let videoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.tag = 300
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 封面占位
    private let coverView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 底部信息栏
    private let infoView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = UIColor(white: 1, alpha: 0.8)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// 底部进度条
    private let progressSlider: ProgressSlider = {
        let v = ProgressSlider()
        v.trackHeight = 2
        v.trackCornerRadius = 1
        v.isThumbHidden = true
        v.maximumTrackTintColor = UIColor(white: 1, alpha: 0.25)
        v.minimumTrackTintColor = .white
        v.bufferTrackTintColor = UIColor(white: 1, alpha: 0.45)
        v.loadingTintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 暂停指示器
    private let pauseIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: config))
        iv.tintColor = UIColor(white: 1, alpha: 0.8)
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 右侧互动按钮
    private let likeButton = ShortVideoFeedCell.makeButton(systemName: "heart.fill", label: "喜欢")
    private let commentButton = ShortVideoFeedCell.makeButton(systemName: "bubble.right.fill", label: "评论")
    private let shareButton = ShortVideoFeedCell.makeButton(systemName: "arrowshape.turn.up.right.fill", label: "分享")

    private let gradientLayer = CAGradientLayer()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupProgressSlider()
        setupTapGesture()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = infoView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progressSlider.value = 0
        progressSlider.bufferValue = 0
        progressSlider.stopLoading()
        setPausedIndicatorVisible(false)
        coverView.isHidden = false
        onTap = nil
        onSeek = nil
    }

    // MARK: - 公开方法

    func configure(title: String, description: String, coverColor: UIColor) {
        titleLabel.text = "@\(title)"
        descLabel.text = description
        coverView.backgroundColor = coverColor
    }

    /// 隐藏封面（开始播放时调用）
    func hideCover() {
        coverView.isHidden = true
    }

    /// 更新播放进度（0...1）
    func updateProgress(_ value: Float) {
        progressSlider.value = value
    }

    func syncPlaybackProgress(_ value: Float) {
        guard !progressSlider.isDragging else { return }
        progressSlider.value = value
    }

    /// 更新缓冲进度（0...1）
    func updateBufferProgress(_ value: Float) {
        progressSlider.bufferValue = value
    }

    func setBuffering(_ isBuffering: Bool) {
        if isBuffering {
            setPausedIndicatorVisible(false)
            progressSlider.startLoading()
        } else {
            progressSlider.stopLoading()
        }
    }

    /// 控制用户暂停后的中心播放按钮。
    func setPausedIndicatorVisible(_ isVisible: Bool) {
        pauseIcon.layer.removeAllAnimations()
        pauseIcon.transform = .identity
        pauseIcon.alpha = isVisible ? 1 : 0
        pauseIcon.isHidden = !isVisible
    }

    // MARK: - 私有方法

    private func setupViews() {
        contentView.backgroundColor = .black

        contentView.addSubview(videoContainerView)
        contentView.addSubview(coverView)
        contentView.addSubview(pauseIcon)

        // 右侧按钮（独立于 infoView，在其上方）
        let buttonStack = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 20
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)

        // infoView（渐变背景 + 进度条 + 文字）
        contentView.addSubview(infoView)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.6).cgColor]
        infoView.layer.insertSublayer(gradientLayer, at: 0)

        infoView.addSubview(progressSlider)
        infoView.addSubview(titleLabel)
        infoView.addSubview(descLabel)

        NSLayoutConstraint.activate([
            // 视频容器铺满
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // 封面铺满
            coverView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // 右侧按钮：固定宽度，底部锚定到 infoView 顶部上方
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            buttonStack.bottomAnchor.constraint(equalTo: infoView.topAnchor, constant: -16),
            buttonStack.widthAnchor.constraint(equalToConstant: 50),

            // infoView 锚定到 safeArea 底部
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),

            // 进度条在 infoView 顶部
            progressSlider.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 4),
            progressSlider.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            progressSlider.heightAnchor.constraint(equalToConstant: 30),

            // 标题
            titleLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),

            // 描述
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -12),

            // 暂停图标居中
            pauseIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pauseIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    private func setupProgressSlider() {
        progressSlider.valueChangedPublisher
            .sink { [weak self] value in
                self?.updateProgress(value)
            }
            .store(in: &cancellables)

        progressSlider.touchEndedPublisher
            .sink { [weak self] value in
                self?.onSeek?(value)
            }
            .store(in: &cancellables)

        progressSlider.tappedPublisher
            .sink { [weak self] value in
                self?.onSeek?(value)
            }
            .store(in: &cancellables)
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onTap?()
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else { return true }
        return !touchView.isDescendant(of: progressSlider)
    }

    private static func makeButton(systemName: String, label: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 28)
        let btn = UIImageView(image: UIImage(systemName: systemName, withConfiguration: config))
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 11)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(btn)
        container.addSubview(lbl)

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: container.topAnchor),
            btn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            lbl.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 2),
            lbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            lbl.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 50),
        ])

        return container
    }
}
