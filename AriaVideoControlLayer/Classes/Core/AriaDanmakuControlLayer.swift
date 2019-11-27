//
//  AriaDanmakuControlLayer.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/18.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SJVideoPlayer
import SnapKit
import Then
import RxSwift
import RxDataSources

class AriaDanmakuControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    fileprivate var isPaused = false
    
    fileprivate var videoPlayer: SJVideoPlayer!
    fileprivate var items = [SJEdgeControlButtonItem]()
    
    fileprivate var rateIndex = 0
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate lazy var input = UITextField().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 7
        $0.layer.masksToBounds = true
        $0.returnKeyType = .send
        $0.attributedPlaceholder = NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("发个友善的弹幕见证当下")
            _ = make.textColor(UIColor.gray.withAlphaComponent(0.8))
            _ = make.font(.systemFont(ofSize: 12))
        })
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        $0.leftViewMode = .always
        $0.rx.controlEvent([.editingDidEndOnExit]).asObservable().bind {
            self.tappedSendItem()
        }.disposed(by: disposeBag)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        topContainerView.sjv_disappearDirection = SJViewDisappearAnimation_Top
        controlView()?.backgroundColor = UIColor.black.withAlphaComponent(0.8)
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
        sj_view_makeAppear(topContainerView, true)
        videoPlayer.urlAsset != nil ? videoPlayer.controlLayerNeedAppear() : videoPlayer.controlLayerNeedDisappear()
    }
    
    func exitControlLayer() {
        restarted = false
        
        sj_view_makeDisappear(topContainerView, true)
        sj_view_makeDisappear(controlView(), true) {
            if !self.restarted { self.controlView()?.removeFromSuperview() }
        }
    }
    
    func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        controlView()?.endEditing(true)
        return false
    }
}

extension AriaDanmakuControlLayer {
    func installedControlView(to videoPlayer: SJBaseVideoPlayer!) {
        isPaused = videoPlayer.timeControlStatus == .paused
        videoPlayer.pause()
        self.videoPlayer = videoPlayer as? SJVideoPlayer
        
        if controlView()!.layer.needsLayout() { sj_view_initializes(topContainerView) }
        
        sj_view_makeDisappear(topContainerView, false)
    }
}

extension AriaDanmakuControlLayer {
    func setupView() {
        let closeItem = SJEdgeControlButtonItem.placeholder(with:SJButtonItemPlaceholderType_49x49, tag: 10001)
        closeItem.image = UIImage(named: "close", in: imageBunde, compatibleWith: nil)
        closeItem.addTarget(self, action: #selector(tappedCloseItem))
        topAdapter.add(closeItem)
        
        let danmakuInput = SJEdgeControlButtonItem(customView: UIView().then {
            $0.addSubview(input)
            input.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.right.equalToSuperview()
                make.height.equalTo(30)
            }
        }, tag: 10002)
        danmakuInput.insets = SJEdgeInsetsMake(8, 8)
        danmakuInput.fill = true
        topAdapter.add(danmakuInput)
        
        let sendItem = SJEdgeControlButtonItem.placeholder(with:SJButtonItemPlaceholderType_49x49, tag: 10003)
        sendItem.image = UIImage(named: "select", in: imageBunde, compatibleWith: nil)
        sendItem.addTarget(self, action: #selector(tappedSendItem))
        topAdapter.add(sendItem)
        
        topAdapter.reload()
        
        input.becomeFirstResponder()
    }
}

extension AriaDanmakuControlLayer {
    @objc func tappedCloseItem() {
        if !isPaused { videoPlayer.play() }
        videoPlayer.switcher.switchControlLayer(forIdentitfier: LONG_MAX - 1)
    }
    
    @objc func tappedSendItem() {
        controlView()?.endEditing(true)
        guard let text = input.text else {
            tappedCloseItem()
            return
        }
        
        if text.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            tappedCloseItem()
            return
        }
        
        let setting = AriaSettingsUtil.getDanmakuSettings()
        let item = SJBarrageItem(content: NSAttributedString.sj_UIKitText({ make in
            _ = make.append(text)
            if let scale = setting[0][1]["value"] as? CGFloat { _ = make.font(UIFont.systemFont(ofSize: 16 * scale)) }
            else { _ = make.font(UIFont.systemFont(ofSize: 16)) }
            if let alpha = setting[0][0]["value"] as? CGFloat { _ = make.textColor(UIColor.white.withAlphaComponent(alpha)) }
            else { _ = make.textColor(.white) }
            _ = make.stroke({ make in
                make.color = UIColor.black
                make.width = -1
            })
        }))
        
        videoPlayer.barrageQueueController.enqueue(item)
        tappedCloseItem()
    }
}
