//
//  ViewController.swift
//  Example
//
//  Created by 神崎H亚里亚 on 2019/11/28.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SJVideoPlayer
import SnapKit
import AriaVideoControlLayer

class ViewController: UIViewController {

    @IBOutlet weak var playView: UIView!
    
    var player = SJVideoPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player.switcher.addControlLayer(forIdentifier: LONG_MAX - 1) { (id) -> SJControlLayer in
            return AriaVideoControlLayer()
        }
        
        playView.addSubview(player.view)
        player.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

