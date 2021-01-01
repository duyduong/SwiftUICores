//
//  NestedPage.swift
//  iOS Example
//
//  Created by Dao Duy Duong on 28/12/2020.
//  Copyright © 2020 Duong Dao. All rights reserved.
//

import Foundation
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
        return AnyView(
            StoreView(content: NestedPage.self, store: NestedPageStore(count: count))
        )
    }
    
    case detail(count: Int)
}

// https://www.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=5061335c1e311a52dede50b843012dea&format=json&nojsoncallback=1&api_sig=811792fdcdcbadd7c2a87da2768e8f98

struct NestedPage: View, IStoreView {
    
    @ObservedObject var store: NestedPageStore
    
    var body: some View {
        VStack {
            NetworkImage(
                url: URL(string: "https://i.pinimg.com/originals/14/35/92/14359297c143d92aeb7b6ace47e8389e.jpg"),
                contentMode: .scaleAspectFit,
                placeholder: { Color.black },
                progressView: {
                    AnyView(
                        CircleProgressBar(progress: $0)
                            .frame(width: 70, height: 70, alignment: .center)
                    )
                }
            )
            .frame(width: 300, height: 200)
            .clipped()
            
            HStack {
                Text("Count: \(store.count)")
                    .font(.title)
                Button(action: store.increase) {
                    Image(systemName: "plus.square.fill")
                        .font(.system(.largeTitle))
                }
            }
            .padding()
            
            Button(action: store.pushDetail, label: {
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
            
            Button(action: store.presentDetail, label: {
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
            
            Button(action: store.showAlert, label: {
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

class NestedPageStore: Store<NestedRoute>, ObservableObject {
    
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
    
    /// AlertService is running on simulators/devices only
    func showAlert() {
        alertService.presentOkayAlert(title: "Alert is showing", message: "Your count is \(count)")
    }
}

struct NestedPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreView(content: NestedPage.self, store: NestedPageStore())
        }
        .previewDevice("iPhone 12")
    }
}
