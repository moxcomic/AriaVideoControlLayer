//
//  UILabelExtension.swift
//  AriaSwiftyChain
//
//  Created by 神崎H亚里亚 on 2019/11/27.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SnapKit

public extension UILabel {
    @discardableResult
    func text(_ text: String?) -> UILabel {
        self.text = text
        return self
    }
    
    @discardableResult
    @objc
    func setText() -> (String?) -> UILabel {
        return { (text) in
            self.text = text
            return self
        }
    }
    
    @discardableResult
    func textColor(_ textColor: UIColor!) -> UILabel {
        self.textColor = textColor
        return self
    }
    
    @discardableResult
    @objc
    func setTextColor() -> (UIColor?) -> UILabel {
        return { (textColor) in
            self.textColor = textColor
            return self
        }
    }
    
    @discardableResult
    func textAlignment(_ textAlignment: NSTextAlignment) -> UILabel {
        self.textAlignment = textAlignment
        return self
    }
    
    @discardableResult
    @objc
    func setTextAlignment() -> (NSTextAlignment) -> UILabel {
        return { (textAlignment) in
            self.textAlignment = textAlignment
            return self
        }
    }
    
    @discardableResult
    func font(_ font: UIFont!) -> UILabel {
        self.font = font
        return self
    }
    
    @discardableResult
    @objc
    func setFont() -> (UIFont?) -> UILabel {
        return { (font) in
            self.font = font
            return self
        }
    }
    
    @discardableResult
    func shadowColor(_ shadowColor: UIColor?) -> UILabel {
        self.shadowColor = shadowColor
        return self
    }
    
    @discardableResult
    @objc
    func setShadowColor() -> (UIColor?) -> UILabel {
        return { (shadowColor) in
            self.shadowColor = shadowColor
            return self
        }
    }
    
    @discardableResult
    func shadowOffset(_ shadowOffset: CGSize) -> UILabel {
        self.shadowOffset = shadowOffset
        return self
    }
    
    @discardableResult
    @objc
    func setShadowOffset() -> (CGSize) -> UILabel {
        return { (shadowOffset) in
            self.shadowOffset = shadowOffset
            return self
        }
    }
    
    @discardableResult
    func shadowOffset(width: CGFloat, height: CGFloat) -> UILabel {
        self.shadowOffset = CGSize(width: width, height: height)
        return self
    }
    
    @discardableResult
    @objc
    func setShadowOffsetWithWH() -> (CGFloat, CGFloat) -> UILabel {
        return { (width, height) in
            self.shadowOffset = CGSize(width: width, height: height)
            return self
        }
    }
    
    @discardableResult
    func numberOfLines(_ numberOfLines: Int) -> UILabel {
        self.numberOfLines = numberOfLines
        return self
    }
    
    @discardableResult
    @objc
    func setNumberOfLines() -> (Int) -> UILabel {
        return { (numberOfLines) in
            self.numberOfLines = numberOfLines
            return self
        }
    }
    
    @discardableResult
    func adjustsFontSizeToFitWidth(_ adjustsFontSizeToFitWidth: Bool) -> UILabel {
        self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        return self
    }
    
    @discardableResult
    @objc
    func setAdjustsFontSizeToFitWidth() -> (Bool) -> UILabel {
        return { (adjustsFontSizeToFitWidth) in
            self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
            return self
        }
    }
    
    @discardableResult
    func addToSuperview(_ superview: UIView) -> UILabel {
        superview.addSubview(self)
        return self
    }
    
    @discardableResult
    @objc
    func addToSuperview() -> (UIView) -> UILabel {
        return { (superview) in
            superview.addSubview(self)
            return self
        }
    }
    
    @discardableResult
    func makeConstraints(_ closure: (_ make: ConstraintMaker) -> ()) -> UILabel {
        self.snp.makeConstraints { (make) in
            closure(make)
        }
        return self
    }
}
