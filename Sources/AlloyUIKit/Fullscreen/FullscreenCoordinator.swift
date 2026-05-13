//
//  FullscreenCoordinator.swift
//  AlloyUIKit
//
//  Created by Sun on 2026/5/13.
//

#if canImport(UIKit)
    import Combine

    public enum FullscreenState: Equatable, Sendable {
        case inline
        case fullscreen
    }

    @MainActor
    public protocol FullscreenCoordinating: AnyObject {
        var state: FullscreenState { get }
        var statePublisher: AnyPublisher<FullscreenState, Never> { get }
        func setFullscreen(_ isFullscreen: Bool, animated: Bool) async
        func toggle(animated: Bool) async
    }

    @MainActor
    open class FullscreenCoordinator: FullscreenCoordinating {
        public private(set) var state: FullscreenState = .inline {
            didSet {
                guard state != oldValue else { return }
                stateSubject.send(state)
            }
        }

        public var statePublisher: AnyPublisher<FullscreenState, Never> {
            stateSubject.eraseToAnyPublisher()
        }

        public var configuration: FullscreenConfiguration

        private let stateSubject = CurrentValueSubject<FullscreenState, Never>(.inline)

        public init(configuration: FullscreenConfiguration = .init()) {
            self.configuration = configuration
        }

        open func setFullscreen(_ isFullscreen: Bool, animated _: Bool) async {
            state = isFullscreen ? .fullscreen : .inline
        }

        open func toggle(animated: Bool) async {
            await setFullscreen(state == .inline, animated: animated)
        }
    }
#endif
