//
//  File.swift
//  
//
//  Created by Dao Duy Duong on 29/12/2020.
//

import SwiftUI
import AlamofireImage

public struct NetworkImage: UIViewRepresentable {
    
    var url: URL?
    var contentMode: UIView.ContentMode
    var placeholder: UIImage?
    var imageTransition: UIImageView.ImageTransition
    
    public init(
        url: URL?,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        placeholder: UIImage? = nil,
        imageTransition: UIImageView.ImageTransition = .crossDissolve(0.25)
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
        self.imageTransition = imageTransition
    }

    public func makeUIView(context: UIViewRepresentableContext<NetworkImage>) -> UIImageView {
        return UIImageView(image: placeholder)
    }

    public func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<NetworkImage>) {
        uiView.contentMode = contentMode
        uiView.image = placeholder
        
        guard let url = url else { return }
        uiView.af.setImage(
            withURL: url,
            placeholderImage: placeholder,
            imageTransition: imageTransition
        )
    }
}
