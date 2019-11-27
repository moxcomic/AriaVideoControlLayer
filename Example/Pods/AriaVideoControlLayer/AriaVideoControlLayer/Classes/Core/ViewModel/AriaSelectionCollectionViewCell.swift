//
//  AriaSelectionCollectionViewCell.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/19.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import Then
import SnapKit

class AriaSelectionCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
        setUI()
    }
    
    var model: String! {
        didSet {
            infoLabel.text = model
        }
    }
    
    fileprivate lazy var content = UIView()
    
    fileprivate lazy var infoLabel = UILabel().then {
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textAlignment = .center
    }
}

extension AriaSelectionCollectionViewCell {
    fileprivate func setUI() {
        addControl()
        setLayout()
    }
    
    func setSelectStyle(isSelect: Bool) {
        if isSelect {
            content.layer.borderColor = biliPink.cgColor
            infoLabel.textColor = biliPink
        } else {
            content.layer.borderColor = defaultGray.cgColor
            infoLabel.textColor = .white
        }
    }
    
    fileprivate func addControl() {
        content.frame = contentView.bounds
        contentView.addSubview(content)
        content.addSubview(infoLabel)
    }
    
    fileprivate func setLayout() {
        content.layer.borderWidth = 1
        content.layer.borderColor = defaultGray.cgColor
        content.layer.cornerRadius = 5
        content.layer.masksToBounds = true
        
        infoLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.left.equalToSuperview().offset(2)
            make.bottom.right.equalToSuperview().offset(-2)
        }
    }
}
