//
//  VideoResource.swift
//  AlloyPlayerDemo
//
//  Created by Sun on 2026/4/14.
//

import UIKit

// MARK: - VideoItem

/// 视频资源模型
struct VideoItem {
    let title: String
    let url: URL
    let description: String
    let coverColor: UIColor

    /// 生成渐变封面图（带播放图标）
    func makeCoverImage(size: CGSize = CGSize(width: 320, height: 180)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let colors = [coverColor.cgColor, coverColor.withAlphaComponent(0.6).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            let iconSize: CGFloat = 44
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            let config = UIImage.SymbolConfiguration(pointSize: iconSize * 0.6, weight: .medium)
            if let icon = UIImage(systemName: "play.circle.fill", withConfiguration: config)?
                .withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal)
            {
                icon.draw(in: iconRect)
            }

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            ]
            let titleStr = title as NSString
            let titleSize = titleStr.size(withAttributes: titleAttrs)
            titleStr.draw(
                at: CGPoint(x: 12, y: size.height - titleSize.height - 10),
                withAttributes: titleAttrs
            )
        }
    }
}

// MARK: - VideoResource

/// 视频资源集合
enum VideoResource {
    // MARK: - Apple 官方 HLS 测试流

    static let hlsSamples: [VideoItem] = [
        VideoItem(
            title: "HEVC + Dolby Vision",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8")!,
            description: "Apple 官方 4K HDR 测试流 (HEVC/Dolby Vision/Atmos)",
            coverColor: UIColor(red: 0.15, green: 0.25, blue: 0.50, alpha: 1)
        ),
        VideoItem(
            title: "BipBop (fMP4)",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!,
            description: "Apple 自适应码率 (fragmented MP4 格式)",
            coverColor: UIColor(red: 0.40, green: 0.20, blue: 0.40, alpha: 1)
        ),
        VideoItem(
            title: "BipBop (TS)",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!,
            description: "Apple 自适应码率 (MPEG-TS 格式)",
            coverColor: UIColor(red: 0.10, green: 0.40, blue: 0.40, alpha: 1)
        ),
        VideoItem(
            title: "BipBop 16:9",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!,
            description: "Apple 16:9 宽屏自适应码率",
            coverColor: UIColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1)
        ),
        VideoItem(
            title: "BipBop (HEVC)",
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!,
            description: "Apple HEVC 编码自适应码率",
            coverColor: UIColor(red: 0.25, green: 0.15, blue: 0.45, alpha: 1)
        ),
    ]

    // MARK: - 开源/公开 MP4 测试视频

    static let mp4Samples: [VideoItem] = [
        VideoItem(
            title: "Sintel Trailer",
            url: URL(string: "https://media.w3.org/2010/05/sintel/trailer.mp4")!,
            description: "Blender 开源动画短片 Sintel 预告 (MP4/H.264)",
            coverColor: UIColor(red: 0.50, green: 0.20, blue: 0.20, alpha: 1)
        ),
        VideoItem(
            title: "Big Buck Bunny",
            url: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
            description: "Blender 开源动画 Big Buck Bunny (HLS 多码率)",
            coverColor: UIColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 1)
        ),
        VideoItem(
            title: "Tears of Steel",
            url: URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!,
            description: "Blender 开源短片 Tears of Steel (HLS)",
            coverColor: UIColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1)
        ),
    ]

    /// 全部测试资源
    static let allSamples: [VideoItem] = hlsSamples + mp4Samples
}
