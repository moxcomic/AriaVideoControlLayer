//
//  UIAlertControllerExtension.swift
//  AriaSwiftyChain
//
//  Created by 神崎H亚里亚 on 2019/11/27.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit

public extension UIAlertController {
    @objc
    static func show(withTitle title: String? = nil, message: String? = nil, confirmText: String = "OK", handler: ((UIAlertAction) -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: confirmText, style: .default, handler: handler)
        alert.addAction(confirmAction)
        UIViewController.topViewController()?.present(alert, animated: true)
    }
    
    @objc
    static func show(withTitle title: String? = nil, message: String? = nil, actions: [String], completion: ((Int) -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for i in 0..<actions.count {
            let action = UIAlertAction(title: actions[i], style: .default) { (action) in completion?(i) }
            alert.addAction(action)
        }
        UIViewController.topViewController()?.present(alert, animated: true)
    }
}
