//
//  Extensions.swift
//  
//
//  Created by Dao Duy Duong on 28/12/2020.
//

import SwiftUI

// MARK: - Publics

public extension EdgeInsets {
    
    static let zero = only()
    
    static func horizontal(_ horizontal: CGFloat = 0, vertical: CGFloat = 0) -> EdgeInsets {
        return EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
    
    static func only(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> EdgeInsets {
        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

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
