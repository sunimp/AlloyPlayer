//
//  ReachabilityMonitor.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

import Combine
import Network

#if os(iOS)
    import CoreTelephony
#endif

/// 网络可达性监控
///
/// 基于 NWPathMonitor 实现，监控网络状态变化。
/// 支持区分 WiFi / 蜂窝网络（2G/3G/4G/5G）。
@MainActor
public final class ReachabilityMonitor {
    // MARK: - 单例

    public static let shared = ReachabilityMonitor()

    // MARK: - 状态

    /// 当前网络状态
    public private(set) var currentStatus: ReachabilityStatus = .unknown

    /// 是否可达
    public var isReachable: Bool {
        currentStatus != .notReachable && currentStatus != .unknown
    }

    /// 是否通过 WiFi 可达
    public var isReachableViaWiFi: Bool {
        currentStatus == .wifi
    }

    /// 是否通过蜂窝网络可达
    public var isReachableViaCellular: Bool {
        switch currentStatus {
        case .cellular2G, .cellular3G, .cellular4G, .cellular5G: true
        default: false
        }
    }

    // MARK: - Combine

    private let _status = CurrentValueSubject<ReachabilityStatus, Never>(.unknown)

    /// 网络状态变化事件流
    public var statusPublisher: AnyPublisher<ReachabilityStatus, Never> {
        _status.eraseToAnyPublisher()
    }

    // MARK: - 内部

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.alloyplayer.reachability")
    private var isMonitoring = false

    #if os(iOS)
        private let telephonyInfo = CTTelephonyNetworkInfo()
    #endif

    // MARK: - 初始化

    private init() {}

    // MARK: - 方法

    /// 开始监控网络状态
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }

    /// 停止监控网络状态
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
    }

    // MARK: - 内部方法

    private func handlePathUpdate(_ path: NWPath) {
        let status: ReachabilityStatus
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                status = .wifi
            } else if path.usesInterfaceType(.cellular) {
                status = detectCellularGeneration()
            } else {
                // 有线等其他连接方式
                status = .wifi
            }
        } else {
            status = .notReachable
        }

        guard status != currentStatus else { return }
        currentStatus = status
        _status.send(status)
    }

    private func detectCellularGeneration() -> ReachabilityStatus {
        #if os(iOS)
            let radioTech: String?
            if let providers = telephonyInfo.serviceCurrentRadioAccessTechnology {
                radioTech = providers.values.first
            } else {
                radioTech = nil
            }

            guard let tech = radioTech else { return .cellular4G }

            switch tech {
            case CTRadioAccessTechnologyGPRS,
                 CTRadioAccessTechnologyEdge,
                 CTRadioAccessTechnologyCDMA1x:
                return .cellular2G
            case CTRadioAccessTechnologyWCDMA,
                 CTRadioAccessTechnologyHSDPA,
                 CTRadioAccessTechnologyHSUPA,
                 CTRadioAccessTechnologyCDMAEVDORev0,
                 CTRadioAccessTechnologyCDMAEVDORevA,
                 CTRadioAccessTechnologyCDMAEVDORevB,
                 CTRadioAccessTechnologyeHRPD:
                return .cellular3G
            case CTRadioAccessTechnologyLTE:
                return .cellular4G
            default:
                // NR / NRNonStandalone (5G)
                if tech.contains("NR") {
                    return .cellular5G
                }
                return .cellular4G
            }
        #else
            return .cellular4G
        #endif
    }
}
