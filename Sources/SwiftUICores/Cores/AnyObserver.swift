//
//  AnyObserver.swift
//  
//
//  Created by Dao Duy Duong on 30/12/2020.
//

import Combine

public extension AnyPublisher {
    
    /// Custom object for create a custom publisher
    struct AnyObserver<Output, Failure: Error> {
        let onNext: ((Output) -> Void)
        let onError: ((Failure) -> Void)
        let onComplete: (() -> Void)
    }
    
    /// Create custom publisher in `RxSwift` style
    /// - Parameter subscribe: Subscribe block
    /// - Returns: Publisher
    static func create(subscribe: @escaping (AnyObserver<Output, Failure>) -> AnyCancellable) -> Self {
        let subject = PassthroughSubject<Output, Failure>()
        var disposable: AnyCancellable?
        
        return subject.handleEvents(
            receiveSubscription: { subscription in
                disposable = subscribe(AnyObserver(
                    onNext: { subject.send($0) },
                    onError: { subject.send(completion: .failure($0)) },
                    onComplete: { subject.send(completion: .finished) }
                ))
            },
            receiveCancel: { disposable?.cancel() }
        )
        .eraseToAnyPublisher()
    }
}

public extension Publisher {
    
    /// Sink wrapper for a weak `self`
    /// - Parameters:
    ///   - obj: Weak referrence object
    ///   - receiveCompletion: The closure to execute on receipt of error/completion
    ///   - receiveValue: The closure to execute on receipt of a value
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    func sink<A: AnyObject>(weak obj: A, receiveCompletion: @escaping ((A, Subscribers.Completion<Self.Failure>) -> Void), receiveValue: @escaping ((A, Self.Output) -> Void)) -> AnyCancellable {
        sink { [weak obj] result in
            guard let obj = obj else { return }
            receiveCompletion(obj, result)
        } receiveValue: { [weak obj] output in
            guard let obj = obj else { return }
            receiveValue(obj, output)
        }
    }
    
    /// Sink without handle error/completion
    /// - Parameter receiveValue: The closure to execute on receipt of a value
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    func sink(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
    
    /// Sink without handle error/completion
    /// - Parameter receiveValue: The closure to execute on receipt of a value
    /// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
    func sink<A: AnyObject>(weak obj: A, receiveValue: @escaping ((A, Self.Output) -> Void)) -> AnyCancellable {
        sink { _ in } receiveValue: { [weak obj] output in
            guard let obj = obj else { return }
            receiveValue(obj, output)
        }
    }
}

public extension Publishers {
    
    /// Zip an array of publishers
    struct ZipAll<Element, F: Error>: Publisher {
        public typealias Output = [Element]
        public typealias Failure = F

        private let upstreams: [AnyPublisher<Element, F>]

        public init(_ upstreams: [AnyPublisher<Element, F>]) {
            self.upstreams = upstreams
        }

        public func receive<S: Subscriber>(subscriber: S) where Self.Failure == S.Failure, Self.Output == S.Input {
            let initial = Just<[Element]>([])
                .setFailureType(to: F.self)
                .eraseToAnyPublisher()

            let zipped = upstreams.reduce(into: initial) { result, upstream in
                result = result
                    .zip(upstream) { $0 + [$1] }
                    .eraseToAnyPublisher()
            }

            zipped.subscribe(subscriber)
        }
    }
}
