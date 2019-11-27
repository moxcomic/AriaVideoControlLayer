//
//  UIViewControllerExtension.swift
//  AriaSwiftyChain
//
//  Created by 神崎H亚里亚 on 2019/11/27.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit

public extension UIViewController {
    @objc
    var topViewController: UIViewController? {
        return UIViewController.topViewController()
    }
    
    @objc
    static func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
        let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = viewController as? UINavigationController,
            !navigationController.viewControllers.isEmpty {
            return self.topViewController(navigationController.viewControllers.last)
        } else if let tabBarController = viewController as? UITabBarController,
            let selectedController = tabBarController.selectedViewController {
            return self.topViewController(selectedController)
        } else if let presentedController = viewController?.presentedViewController {
            return self.topViewController(presentedController)
        }
        return viewController
    }
}
