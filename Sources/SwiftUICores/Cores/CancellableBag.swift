//
//  CancellableBag.swift
//  
//
//  Created by Dao Duy Duong on 30/12/2020.
//

import Combine

/// Shorthand for `Set<AnyCancellable>`
public typealias CancellableBag = Set<AnyCancellable>

// MARK: - Store in cancellable bag

precedencegroup DisposablePrecedence {
    lowerThan: DefaultPrecedence
}

infix operator =>: DisposablePrecedence

public func =>(cancelable: AnyCancellable, bag: inout CancellableBag) {
    cancelable.store(in: &bag)
}
