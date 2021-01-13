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
