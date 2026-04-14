//
//  CustomStatusBar.swift
//  AlloyControlView
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import UIKit

    /// 横屏自定义状态栏
    ///
    /// 显示时间和电池信息，用于全屏模式下替代系统状态栏。
    @MainActor
    public final class CustomStatusBar: UIView {
        public var refreshInterval: TimeInterval = 3.0

        private let timeLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = .systemFont(ofSize: 12)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let batteryIcon: UIImageView = {
            let iv = UIImageView()
            iv.tintColor = .white
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            return iv
        }()

        private var timer: Timer?

        override public init(frame: CGRect) {
            super.init(frame: frame)
            UIDevice.current.isBatteryMonitoringEnabled = true
            addSubview(timeLabel)
            addSubview(batteryIcon)
            NSLayoutConstraint.activate([
                timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                batteryIcon.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 6),
                batteryIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
                batteryIcon.widthAnchor.constraint(equalToConstant: 22),
                batteryIcon.heightAnchor.constraint(equalToConstant: 12),
            ])
            updateDisplay()
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public func startTimer() {
            stopTimer()
            updateDisplay()
            timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in self?.updateDisplay() }
            }
        }

        public func stopTimer() {
            timer?.invalidate()
            timer = nil
        }

        private func updateDisplay() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            timeLabel.text = formatter.string(from: Date())

            let level = UIDevice.current.batteryLevel
            let config = UIImage.SymbolConfiguration(pointSize: 12)
            batteryIcon.image = switch UIDevice.current.batteryState {
            case .charging, .full:
                UIImage(systemName: "battery.100.bolt", withConfiguration: config)
            default:
                UIImage(systemName: level > 0.5 ? "battery.75" : (level > 0.2 ? "battery.25" : "battery.0"), withConfiguration: config)
            }
        }
    }
#endif
