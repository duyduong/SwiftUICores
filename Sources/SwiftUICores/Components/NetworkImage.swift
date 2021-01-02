//
//  File.swift
//  
//
//  Created by Dao Duy Duong on 29/12/2020.
//

import Foundation
import SwiftUI
import AlamofireImage

/// Custom network image
public struct NetworkImage: View {
    
    let url: URL?
    let contentMode: UIView.ContentMode
    let imageTransition: UIImageView.ImageTransition
    let placeholder: AnyView
    var progressView: ((Binding<Float>) -> AnyView)? = nil
    
    @State private var progress: Float = 0
    @State private var image: UIImage?
    
    public init(
        url: URL?,
        contentMode: UIView.ContentMode = .scaleToFill,
        imageTransition: UIImageView.ImageTransition = .crossDissolve(0.25)
    ) {
        self.url = url
        self.contentMode = contentMode
        self.imageTransition = imageTransition
        self.placeholder = AnyView(EmptyView())
    }
    
    public init<PlaceholderView: View>(
        url: URL?,
        contentMode: UIView.ContentMode = .scaleToFill,
        imageTransition: UIImageView.ImageTransition = .crossDissolve(0.25),
        placeholder: @escaping (() -> PlaceholderView),
        progressView: ((Binding<Float>) -> AnyView)? = nil
    ) {
        self.url = url
        self.contentMode = contentMode
        self.imageTransition = imageTransition
        self.placeholder = AnyView(placeholder())
        self.progressView = progressView
    }
    
    public var body: some View {
        ZStack {
            if image == nil {
                placeholder.fillParent()
                
                if let progressView = progressView {
                    progressView($progress)
                }
            }
            
            AFImage(
                url: url,
                contentMode: contentMode,
                imageTransition: imageTransition,
                progress: { progress = Float($0.fractionCompleted) },
                completion: { image = $0 }
            ).fillParent()
        }
    }
}

private struct AFImage: UIViewRepresentable {
    
    let url: URL?
    let contentMode: UIView.ContentMode
    let imageTransition: UIImageView.ImageTransition
    let progress: ((Progress) -> Void)
    let completion: ((UIImage?) -> Void)

    func makeUIView(context: UIViewRepresentableContext<AFImage>) -> UIImageView {
        UIImageView()
    }

    func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<AFImage>) {
        uiView.contentMode = contentMode
        
        guard let url = url else { return }
        uiView.af.setImage(
            withURL: url,
            progress: progress,
            imageTransition: imageTransition,
            completion: { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let image): self.completion(image)
                    case .failure: self.completion(nil)
                    }
                }
            }
        )
    }
}
