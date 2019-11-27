//
//  AriaSelectionControlLayer.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/18.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SJVideoPlayer
import SnapKit
import Then

class AriaSelectionControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    fileprivate var videoPlayer: SJVideoPlayer!
    fileprivate let kCellId = "com.moxcomic.selection.cellId"
    
    open var currentPlayIndex = 0 {
        didSet {
            collectionView.reloadData()
        }
    }
    open var playListCount = 1 {
        didSet {
            if playListCount < 1 { playListCount = 1 }
            else { infoLabel.text = "选集 (\(playListCount))" }
        }
    }
    open var playTheIndexBlock: ((Int) -> ())?
    
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
    
    lazy var infoLabel = UILabel().then {
        $0.text = "选集 (\(playListCount))"
        $0.textColor = .gray
        $0.font = .systemFont(ofSize: 14)
    }
    
    var collectionView: UICollectionView!
}

extension AriaSelectionControlLayer {
    func installedControlView(to videoPlayer: SJBaseVideoPlayer!) {
        self.videoPlayer = videoPlayer as? SJVideoPlayer
        
        if controlView()!.layer.needsLayout() { sj_view_initializes(rightContainerView) }
        
        sj_view_makeDisappear(rightContainerView, false)
    }
    
    func restartControlLayer() {
        restarted = true
        sj_view_makeAppear(controlView(), true)
        sj_view_makeAppear(rightContainerView, true)
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

extension AriaSelectionControlLayer {
    func setupView() {
        rightWidth = 300
        
        rightContainerView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(10)
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: Int((336 - 35) / 4), height: 44)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(AriaSelectionCollectionViewCell.self, forCellWithReuseIdentifier: kCellId)
        collectionView.delegate = self
        collectionView.dataSource = self
        rightContainerView.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(infoLabel.snp.bottom).offset(10)
            make.left.bottom.equalToSuperview()
            make.right.equalTo(controlView()!.safeAreaLayoutGuide.snp.right)
        }
        
        rightAdapter.reload()
    }
}

extension AriaSelectionControlLayer: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playListCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellId, for: indexPath) as! AriaSelectionCollectionViewCell
        cell.model = "\(indexPath.row + 1)"
        if self.currentPlayIndex == indexPath.row { cell.setSelectStyle(isSelect: true) }
        else { cell.setSelectStyle(isSelect: false) }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let exeBlock = playTheIndexBlock {
            currentPlayIndex = indexPath.row
            collectionView.reloadData()
            videoPlayer.barrageQueueController.removeAll()
            exeBlock(indexPath.row)
        }
        videoPlayer.switcher.switchControlLayer(forIdentitfier: LONG_MAX - 1)
    }
}
