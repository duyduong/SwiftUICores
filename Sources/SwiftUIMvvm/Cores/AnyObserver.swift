//
//  AnyObserver.swift
//  
//
//  Created by Dao Duy Duong on 30/12/2020.
//

import Combine

public struct AnyObserver<Output, Failure: Error> {
    let onNext: ((Output) -> Void)
    let onError: ((Failure) -> Void)
    let onComplete: (() -> Void)
}

public extension AnyPublisher {
    
    static func create(subscribe: @escaping (AnyObserver<Output, Failure>) -> AnyCancellable) -> Self {
        let subject = PassthroughSubject<Output, Failure>()
        var disposable: AnyCancellable?
        
        return subject.handleEvents(
            receiveSubscription: { subscription in
                disposable = subscribe(AnyObserver(
                    onNext: { output in subject.send(output) },
                    onError: { failure in subject.send(completion: .failure(failure)) },
                    onComplete: { subject.send(completion: .finished) }
                ))
            },
            receiveCancel: { disposable?.cancel() }
        )
        .eraseToAnyPublisher()
    }
}
