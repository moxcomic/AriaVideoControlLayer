//
//  LandscapeMoreSettingHeaderView.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/20.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit

class LandscapeMoreSettingHeaderView: UICollectionReusableView {
    fileprivate lazy var label = UILabel().then {
        $0.textColor = .gray
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
    }
    
    var model: String! {
        didSet {
            label.text = model
        }
    }
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }
    }
     
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
