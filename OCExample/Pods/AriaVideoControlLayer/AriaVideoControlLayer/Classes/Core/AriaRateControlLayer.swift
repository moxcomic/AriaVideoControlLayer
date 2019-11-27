//
//  AriaRateControlLayer.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/18.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SJVideoPlayer
import SnapKit
import Then

class AriaRateControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    fileprivate var videoPlayer: SJVideoPlayer!
    fileprivate let rateArrList: [Float] = [2.0, 1.5, 1.25, 1.0, 0.75, 0.5]
    fileprivate var items = [SJEdgeControlButtonItem]()
    
    fileprivate var rateIndex = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        rightContainerView.sjv_disappearDirection = SJViewDisappearAnimation_Right
        rightContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func controlView() -> UIView! {
        return self
    }
    
    var restarted: Bool = false
    
    func restartControlLayer() {
        restarted = true
        sj_view_makeAppear(controlView(), true)
        sj_view_makeAppear(rightContainerView, true)
        refreshItems()
        videoPlayer.urlAsset != nil ? videoPlayer.controlLayerNeedAppear() : videoPlayer.controlLayerNeedDisappear()
    }
    
    func exitControlLayer() {
        restarted = false
        
        sj_view_makeDisappear(rightContainerView, true)
        sj_view_makeDisappear(controlView(), true) {
            if !self.restarted { self.controlView()?.removeFromSuperview() }
        }
    }
    
    func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        if type == SJPlayerGestureType_SingleTap {
            if !self.rightContainerView.frame.contains(location) {
                self.videoPlayer.switcher.switchControlLayer(forIdentitfier: LONG_MAX - 1)
            }
        }
        return false
    }
}

extension AriaRateControlLayer {
    func installedControlView(to videoPlayer: SJBaseVideoPlayer!) {
        rateIndex = rateArrList.firstIndex(of: videoPlayer.rate) ?? 0
        self.videoPlayer = videoPlayer as? SJVideoPlayer
        
        if controlView()!.layer.needsLayout() { sj_view_initializes(rightContainerView) }
        
        sj_view_makeDisappear(rightContainerView, false)
    }
}

extension AriaRateControlLayer {
    func setupView() {
        rightWidth = 140
        
        for i in 0..<rateArrList.count {
            let item = SJEdgeControlButtonItem.placeholder(withSize: 38, tag: i)
            item.addTarget(self, action: #selector(clickItem(item:)))
            items.append(item)
            rightAdapter.add(item)
        }
        
        refreshItems()
        rightAdapter.reload()
    }
}

extension AriaRateControlLayer {
    @objc func clickItem(item: SJEdgeControlButtonItem) {
        rateIndex = item.tag
        videoPlayer.rate = rateArrList[rateIndex]
        refreshItems()
        bottomAdapter.reload()
        videoPlayer.prompt.show(NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("\(self.rateArrList[self.rateIndex])X")
            _ = make.textColor(.white)
        }), duration: 3)
        videoPlayer.switcher.switchControlLayer(forIdentitfier: LONG_MAX - 1)
    }
    
    func refreshItems() {
        for item in items {
            item.title = NSAttributedString.sj_UIKitText({ (make) in
                _ = make.append("\(self.rateArrList[item.tag])X")
                _ = make.font(.systemFont(ofSize: 14))
                _ = make.alignment(.center)
                _ = make.textColor(self.rateIndex == item.tag ? biliPink : .white)
            })
        }
    }
}
