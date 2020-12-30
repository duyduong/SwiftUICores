//
//  VMView.swift
//  
//
//  Created by Dao Duy Duong on 28/12/2020.
//

import SwiftUI
import Combine

/// Wrapper view for wrapping a page with its own ViewModel together
public struct VMView<VM: IViewModel & ObservableObject>: View {
    @ObservedObject var viewModel: VM
    let content: AnyView
    
    public init<Content: View>(viewModel: VM, content: Content) {
        self.init(viewModel: viewModel, content: { content })
    }
    
    public init<Content: View>(viewModel: VM, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self.content = AnyView(content())
    }
    
    public var body: some View {
        ZStack {
            if let route = viewModel.navigationRoute {
                NavigationLink("", destination: route.content, tag: route, selection: $viewModel.navigationRoute)
            }
            
            content.environmentObject(viewModel)
        }
        .sheet(item: $viewModel.modalRoute) { $0.content }
    }
}

