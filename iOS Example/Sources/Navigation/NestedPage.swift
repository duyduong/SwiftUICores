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
        let count = model ?? 0
        return AnyView(VMView(
            viewModel: NestedPageViewModel(count: count),
            content: NestedPage()
        ))
    }
    
    case detail(count: Int)
}

struct NestedPage: View {
    
    @EnvironmentObject var viewModel: NestedPageViewModel
    
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
                    Text("Push")
                        .foregroundColor(.white)
                        .font(.headline)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .padding(.all)
            })
            .background(Color.blue)
            .cornerRadius(5)
            
            Button(action: viewModel.presentDetail, label: {
                HStack {
                    Text("Present")
                        .foregroundColor(.white)
                        .font(.headline)
                    Image(systemName: "chevron.up")
                        .foregroundColor(.white)
                }
                .padding(.all)
            })
            .background(Color.blue)
            .cornerRadius(5)
            
            Button(action: viewModel.showAlert, label: {
                HStack {
                    Text("Show alert")
                        .foregroundColor(.white)
                        .font(.headline)
                    Image(systemName: "info.circle")
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
        push(to: .detail(count: count))
    }
    
    func presentDetail() {
        present(to: .detail(count: count))
    }
    
    func showAlert() {
        alertService.presentOkayAlert(title: "Alert is showing", message: "Your count is \(count)")
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
