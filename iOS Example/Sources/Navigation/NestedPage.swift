//
//  NestedPage.swift
//  iOS Example
//
//  Created by Dao Duy Duong on 28/12/2020.
//  Copyright © 2020 Duong Dao. All rights reserved.
//

import SwiftUI
import SwiftUIMvvm

/// Nested push with model passing
enum NestedRoute: IRoute {
    typealias M = Int
    
    var rawValue: String { UUID().uuidString }
    
    var model: Int? {
        switch self {
        case .detail(let count):
            return count
        }
    }
    
    var content: AnyView {
        guard let count = model else { return AnyView(EmptyView()) }
        return AnyView(VMView(
            viewModel: NestedPageViewModel(count: count),
            content: NestedPage()
        ))
    }
    
    case detail(count: Int)
}

struct NestedPage: View {
    
    @EnvironmentObject var viewModel: NestedPageViewModel
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Count: \(viewModel.count)")
                    .font(.title)
                Button(action: viewModel.increase) {
                    Image(systemName: "plus.square.fill")
                        .font(.system(.largeTitle))
                }
            }
            .padding()
            
            Button(action: viewModel.pushDetail, label: {
                HStack {
                    Text("Nested push")
                        .foregroundColor(.white)
                        .font(.headline)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .padding(.all)
            })
            .background(Color.blue)
            .cornerRadius(5)
        }
    }
}

class NestedPageViewModel: ViewModel<NestedRoute>, ObservableObject {
    
    @Published var count: Int
    
    @LazyInjected var alertService: IAlertService
    
    init(count: Int = 0) {
        self.count = count
        super.init()
    }
    
    func increase() {
        count += 1
    }
    
    func pushDetail() {
        alertService.presentOkayAlert(title: "Test title", message: "Test message")
    }
}

struct NestedPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VMView(
                viewModel: NestedPageViewModel(),
                content: NestedPage()
            )
        }
    }
}
