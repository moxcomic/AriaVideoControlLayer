//
//  UIButtonExtension.swift
//  AriaSwiftySelf
//
//  Created by 神崎H亚里亚 on 2019/11/27.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import NSObject_Rx
import RxDataSources

public extension UIButton {
    @discardableResult
    func title(_ title: String?, for state: State...) -> UIButton {
        state.forEach { self.setTitle(title, for: $0) }
        return self
    }
    
    @discardableResult
    @objc
    func setTitleForState() -> (String?, State) -> UIButton {
        return { (title, state) in
            self.setTitle(title, for: state)
            return self
        }
    }
    
    @discardableResult
    func titleColor(_ color: UIColor?, for state: State...) -> UIButton {
        state.forEach { self.setTitleColor(color, for: $0) }
        return self
    }
    
    @discardableResult
    @objc
    func setTitleColorForState() -> (UIColor?, State) -> UIButton {
        return { (color, state) in
            self.setTitleColor(color, for: state)
            return self
        }
    }
    
    @discardableResult
    func image(_ image: UIImage?, for state: State...) -> UIButton {
        state.forEach { self.setImage(image, for: $0) }
        return self
    }
    
    @discardableResult
    @objc
    func setImageForState() -> (UIImage?, State) -> UIButton {
        return { (image, state) in
            self.setImage(image, for: state)
            return self
        }
    }
    
    @discardableResult
    func backgroundImage(_ image: UIImage?, for state: State...) -> UIButton {
        state.forEach { self.setBackgroundImage(image, for: $0) }
        return self
    }
    
    @discardableResult
    @objc
    func setBackgroundImage() -> (UIImage?, State) -> UIButton {
        return { (image, state) in
            self.setBackgroundImage(image, for: state)
            return self
        }
    }
    
    @discardableResult
    func attributedTitle(_ attributedTitle: NSAttributedString?, for state: State...) -> UIButton {
        state.forEach { self.setAttributedTitle(attributedTitle, for: $0) }
        return self
    }
    
    @discardableResult
    @objc
    func setAttributedTitleForState() -> (NSAttributedString?, State) -> UIButton {
        return { (attributedTitle, state) in
            self.setAttributedTitle(attributedTitle, for: state)
            return self
        }
    }
    
    @discardableResult
    func titleEdgeInsets(_ edgeInsets: UIEdgeInsets) -> UIButton {
        self.titleEdgeInsets = edgeInsets
        return self
    }
    
    @discardableResult
    @objc
    func setTitleEdgeInsets() -> (UIEdgeInsets) -> UIButton {
        return { (edgeInsets) in
            self.titleEdgeInsets = edgeInsets
            return self
        }
    }
    
    @discardableResult
    @objc
    func titleEdgeInsets(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> UIButton {
        self.titleEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        return self
    }
    
    @discardableResult
    @objc
    func setTitleEdgeInsetsWithTLBR() -> (CGFloat, CGFloat, CGFloat, CGFloat) -> UIButton {
        return { (top, left, bottom, right) in
            self.titleEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            return self
        }
    }
    
    @discardableResult
    func imageEdgeInsets(_ edgeInsets: UIEdgeInsets) -> UIButton {
        self.imageEdgeInsets = edgeInsets
        return self
    }
    
    @discardableResult
    @objc
    func setImageEdgeInsets() -> (UIEdgeInsets) -> UIButton {
        return { (edgeInsets) in
            self.imageEdgeInsets = edgeInsets
            return self
        }
    }
    
    @discardableResult
    func imageEdgeInsets(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> UIButton {
        self.imageEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        return self
    }
    
    @discardableResult
    @objc
    func setImageEdgeInsetsWithTLBR() -> (CGFloat, CGFloat, CGFloat, CGFloat) -> UIButton {
        return { (top, left, bottom, right) in
            self.imageEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            return self
        }
    }
    
    @discardableResult
    func frame(frame: CGRect) -> UIButton {
        self.frame = frame
        return self
    }
    
    @discardableResult
    @objc
    func setFrame() -> (CGRect) -> UIButton {
        return { (frame) in
            self.frame = frame
            return self
        }
    }
    
    @discardableResult
    func frame(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> UIButton {
        self.frame = CGRect(x: x, y: y, width: width, height: height)
        return self
    }
    
    @discardableResult
    @objc
    func setFrameWithXYWH() -> (CGFloat, CGFloat, CGFloat, CGFloat) -> UIButton {
        return { (x, y, width, height) in
            self.frame = CGRect(x: x, y: y, width: width, height: height)
            return self
        }
    }
    
    @discardableResult
    func backgroundColor(_ backgroundColor: UIColor?) -> UIButton {
        self.backgroundColor = backgroundColor
        return self
    }
    
    @discardableResult
    @objc
    func setBackgroundColor() -> (UIColor?) -> UIButton {
        return { (backgroundColor) in
            self.backgroundColor = backgroundColor
            return self
        }
    }
    
    @discardableResult
    func addToSuperview(_ superview: UIView) -> UIButton {
        superview.addSubview(self)
        return self
    }
    
    @discardableResult
    @objc
    func addToSuperview() -> (UIView) -> UIButton {
        return { (superview) in
            superview.addSubview(self)
            return self
        }
    }
    
    @discardableResult
    func makeConstraints(_ closure: (_ make: ConstraintMaker) -> ()) -> UIButton {
        self.snp.makeConstraints { (make) in
            closure(make)
        }
        return self
    }
    
    @discardableResult
    func tap(_ closure: (() -> ())?) -> UIButton {
        self.rx.tap.bind { closure?() }.disposed(by: rx.disposeBag)
        return self
    }
    
    @discardableResult
    @objc
    func setTap() -> ((() -> ())?) -> UIButton {
        return { (closure) in
            self.rx.tap.bind { closure?() }.disposed(by: self.rx.disposeBag)
            return self
        }
    }
}
