//
//  Extensions.swift
//  
//
//  Created by Dao Duy Duong on 28/12/2020.
//

import UIKit
import SwiftUI
import Combine

// MARK: - Publics

public extension View {
    func fillParent(alignment: Alignment = .center) -> some View {
        frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: alignment
        )
    }
}

public extension UIWindowScene {
    
    /// Get current window scene
    static var focused: UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }
    
    /// Create new window in iOS 13 with `UIWindowScene`
    static func createNewWindow() -> UIWindow {
        focused.map(UIWindow.init(windowScene:)) ?? UIWindow(frame: UIScreen.main.bounds)
    }
}

public extension CGSize {
    
    static func square(_ size: CGFloat) -> CGSize {
        CGSize(width: size, height: size)
    }
}

public extension UIImage {
    
    /// Create image from mono color
    static func from(color: UIColor) -> UIImage {
        let size: CGSize = .square(1)
        return from(color: color, withSize: size)
    }
    
    /// Create image from mono color with specific size and corner radius
    static func from(color: UIColor, withSize size: CGSize, cornerRadius: CGFloat = 0) -> UIImage {
        defer { UIGraphicsEndImageContext() }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: cornerRadius)
        path.addClip()
        color.setFill()
        path.fill()
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

public extension UIImage {
    
    func withColor(_ color: UIColor) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage else { return nil }
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.setBlendMode(.normal)
        context.clip(to: rect, mask: cgImage)
        context.fill(rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func withAlpha(_ value: CGFloat) -> UIImage? {
        defer { UIGraphicsEndImageContext() }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(at: .zero, blendMode: .normal, alpha: value)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func withSize(_ size: CGSize) -> UIImage? {
        defer { UIGraphicsEndImageContext() }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: size)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
