//
//  CancellableBag.swift
//  
//
//  Created by Dao Duy Duong on 30/12/2020.
//

import Combine

/// Wrapping for cancellable
public final class CancellableBag {
    fileprivate var subscriptions = Set<AnyCancellable>()
    
    public init() {}
    
    public func dispose() {
        subscriptions.forEach { $0.cancel() }
    }
}

// MARK: - Store in cancellable bag

precedencegroup DisposablePrecedence {
    lowerThan: DefaultPrecedence
}

infix operator =>: DisposablePrecedence

public func =>(cancelable: AnyCancellable, bag: CancellableBag?) {
    guard let bag = bag else { return }
    cancelable.store(in: &bag.subscriptions)
}
