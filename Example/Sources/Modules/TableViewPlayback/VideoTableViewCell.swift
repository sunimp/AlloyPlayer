//
//  VideoTableViewCell.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - VideoTableViewCell

/// 视频列表 Cell
final class VideoTableViewCell: UITableViewCell {
    static let reuseIdentifier = "VideoTableViewCell"

    /// 视频容器 (tag = 100，供 Player 通过 tag 查找)
    let videoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.tag = 100
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 封面图
    let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - 初始化

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(videoContainerView)
        videoContainerView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)

        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            videoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoContainerView.heightAnchor.constraint(equalTo: videoContainerView.widthAnchor, multiplier: 9.0 / 16.0),

            coverImageView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - 配置

    func configure(with video: VideoItem) {
        titleLabel.text = video.title
        descLabel.text = video.description
        coverImageView.image = video.makeCoverImage()
    }
}
