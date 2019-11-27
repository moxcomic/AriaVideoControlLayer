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
        
        let asset = SJVideoPlayerURLAsset(url: URL(string: "https://youku.cdn7-okzy.com/20191128/15965_000b016f/index.m3u8")!)
        asset?.title = "仿B站控制层"
        
        player.urlAsset = asset
    }
}

