//
//  Store.swift
//  
//
//  Created by Dao Duy Duong on 28/12/2020.
//

import SwiftUI
import Combine

/// Route interface
public protocol IRoute: Hashable, Identifiable {
    associatedtype M
    
    var model: M? { get }
    var rawValue: String { get }
    var content: AnyView { get }
}

public extension IRoute {
    var model: M? { nil }
    var id: String { rawValue }
    var content: AnyView { AnyView(EmptyView()) }
}

/// Default route type
public struct EmptyRoute: IRoute {
    public typealias M = Any
    public var rawValue: String { UUID().uuidString }
}

/// Core ViewModel
public protocol IStore: class {
    associatedtype R: IRoute
    
    var navigationRoute: R? { get set }
    var modalRoute: R? { get set }
    
    func push(to route: R)
    func present(to route: R)
}

/// Super ViewModel class for inherit
open class Store<R: IRoute>: IStore {
    @Published public var navigationRoute: R?
    @Published public var modalRoute: R?
    
    public init() {}
    
    public func push(to route: R) {
        navigationRoute = route
    }
    
    public func present(to route: R) {
        modalRoute = route
    }
}
