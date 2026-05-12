//
//  PlayerLifecycleCoordinator.swift
//  AlloyCore
//
//  Created by Sun on 2026/5/12.
//

#if canImport(UIKit)
    import Combine
    import Foundation

    /// 播放器生命周期协调器。
    @MainActor
    public final class PlayerLifecycleCoordinator {
        public var pauseWhenAppResignActive = true
        public private(set) var isPausedByEvent = false

        private weak var engine: PlaybackEngine?
        private var observer: SystemEventObserver?
        private var cancellables = Set<AnyCancellable>()

        public init() {}

        public func bind(engine: PlaybackEngine) {
            self.engine = engine
        }

        public func start() {
            observer?.stopObserving()
            cancellables.removeAll()

            let observer = SystemEventObserver()
            self.observer = observer
            observer.startObserving()

            observer.willResignActivePublisher.sink { [weak self] in
                guard let self, self.pauseWhenAppResignActive else { return }
                self.isPausedByEvent = true
                self.engine?.pause()
            }.store(in: &cancellables)

            observer.didBecomeActivePublisher.sink { [weak self] in
                guard let self, self.isPausedByEvent else { return }
                self.isPausedByEvent = false
                if self.engine?.shouldAutoPlay == true {
                    self.engine?.play()
                }
            }.store(in: &cancellables)
        }

        public func stop() {
            observer?.stopObserving()
            observer = nil
            cancellables.removeAll()
            isPausedByEvent = false
        }
    }
#endif
