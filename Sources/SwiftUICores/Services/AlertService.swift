//
//  File.swift
//  
//
//  Created by Dao Duy Duong on 29/12/2020.
//

import UIKit
import SwiftUI
import Combine

private class AlertController: UIAlertController {
    
    private var alertWindow: UIWindow? = nil
    
    func show() {
        let blankViewController = UIViewController()
        blankViewController.view.backgroundColor = .clear
        
        let window = UIWindowScene.createNewWindow()
        window.rootViewController = blankViewController
        window.backgroundColor = .clear
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()
        alertWindow = window
        
        blankViewController.present(self, animated: true)
    }
    
    func hide() {
        alertWindow?.isHidden = true
        alertWindow = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        hide()
    }
}

/// Alert action including `title` and `style`
public struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    
    public init(title: String, style: UIAlertAction.Style) {
        self.title = title
        self.style = style
    }
    
    func uiAction(handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        UIAlertAction(title: title, style: style, handler: handler)
    }
}

public protocol IAlertService {
    
    /// Present an alert with list of actions
    ///
    /// Whenever the user pressed on an action, its index will be returned
    func presentAlertPublisher(title: String?, message: String?, actions: [AlertAction]) -> AnyPublisher<Int, Never>
    
    /// Present an action sheet alert with list of actions and a cancel action
    ///
    /// Whenever the user pressed on an action, its index will be returned. Otherwise cancel action returns `-1`
    func presentActionSheetPublisher(
        title: String?,
        message: String?,
        actions: [AlertAction],
        cancelAction: AlertAction
    ) -> AnyPublisher<Int, Never>
    
    /// Present a simple alert with one action styled `cancel`
    func presentOkayAlert(title: String?, message: String?, okAction: AlertAction)
}

public extension IAlertService {
    
    /// Present an action sheet alert with list of actions and a cancel action
    ///
    /// Whenever the user pressed on an action, its index will be returned. Otherwise cancel action returns `-1`
    func presentActionSheetPublisher(
        title: String?,
        message: String?,
        actions: [AlertAction],
        cancelAction: AlertAction = .init(title: "OK", style: .cancel)
    ) -> AnyPublisher<Int, Never> {
        presentActionSheetPublisher(title: title, message: message, actions: actions, cancelAction: cancelAction)
    }

    /// Present a simple alert with one action styled `cancel`
    func presentOkayAlertPublisher(
        title: String?,
        message: String?,
        okAction: AlertAction = .init(title: "OK", style: .cancel)
    ) -> AnyPublisher<Void, Never> {
        return presentAlertPublisher(title: title, message: message, actions: [okAction])
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    /// Present a simple alert with one action styled `cancel`
    func presentOkayAlert(title: String?, message: String?, okAction: AlertAction = .init(title: "OK", style: .cancel)) {
        presentOkayAlert(title: title, message: message, okAction: okAction)
    }
}

public class AlertService: IAlertService {
    
    public init() {}
    
    /// Present an alert with list of actions
    ///
    /// Whenever the user pressed on an action, its index will be returned
    public func presentAlertPublisher(title: String?, message: String?, actions: [AlertAction]) -> AnyPublisher<Int, Never> {
        return Future { promise in
            let controller = AlertController(title: title, message: message, preferredStyle: .alert)
            for (i, action) in actions.enumerated() {
                let alertAction = action.uiAction { _ in
                    promise(.success(i))
                }
                
                controller.addAction(alertAction)
            }
            
            controller.show()
        }
        .eraseToAnyPublisher()
    }
    
    /// Present an action sheet alert with list of actions and a cancel action
    ///
    /// Whenever the user pressed on an action, its index will be returned. Otherwise cancel action returns `-1`
    public func presentActionSheetPublisher(title: String?, message: String?, actions: [AlertAction], cancelAction: AlertAction) -> AnyPublisher<Int, Never> {
        return Future { promise in
            let controller = AlertController(title: title, message: message, preferredStyle: .actionSheet)
            for (i, action) in actions.enumerated() {
                let alertAction = action.uiAction { _ in
                    promise(.success(i))
                }
                
                controller.addAction(alertAction)
            }
            
            controller.addAction(cancelAction.uiAction { _ in
                promise(.success(-1))
            })
            
            controller.show()
        }
        .eraseToAnyPublisher()
    }
    
    /// Present a simple alert with one action styled `cancel`
    public func presentOkayAlert(title: String?, message: String?, okAction: AlertAction = .init(title: "OK", style: .cancel)) {
        let controller = AlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(okAction.uiAction())
        controller.show()
    }
}
