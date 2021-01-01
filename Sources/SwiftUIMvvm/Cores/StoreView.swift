//
//  VMView.swift
//  
//
//  Created by Dao Duy Duong on 28/12/2020.
//

import SwiftUI
import Combine

/// Store view protocol
public protocol IStoreView: View {
    associatedtype S
    
    var store: S { get }
    init(store: S)
}

/// Wrapper view for wrapping a view with its own store
///
/// By using this, our app can dynamically push & present a modal
public struct StoreView<S: IStore & ObservableObject, V: IStoreView>: View where V.S == S {
    @ObservedObject var store: S
    let content: V
    
    public init(content: V.Type, store: S) {
        self.store = store
        self.content = content.init(store: store)
    }
    
    public var body: some View {
        ZStack {
            if let route = store.navigationRoute {
                NavigationLink("", destination: route.content, tag: route, selection: $store.navigationRoute)
            }
            
            content
        }
        .sheet(item: $store.modalRoute) { $0.content }
    }
}

