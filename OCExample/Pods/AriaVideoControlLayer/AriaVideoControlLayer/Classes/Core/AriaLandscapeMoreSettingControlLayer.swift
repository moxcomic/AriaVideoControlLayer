//
//  AriaLandscapeMoreSettingControlLayer.swift
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

class AriaLandscapeMoreSettingControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
    fileprivate var videoPlayer: SJVideoPlayer!
    
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
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate var currentScaleIndex = 0
    
    fileprivate var dataListArr = BehaviorSubject(value: [SectionModel<String, String>]())
    
    fileprivate let kHeaderId = "com.moxcomic.Landscape.MoreSetting.HeaderId"
    fileprivate let kCellId = "com.moxcomic.Landscape.MoreSetting.CellId"
    fileprivate var collectionView: UICollectionView!
}

extension AriaLandscapeMoreSettingControlLayer {
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

extension AriaLandscapeMoreSettingControlLayer {
    func setupView() {
        rightWidth = 300
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 49, height: 24.5)
        layout.headerReferenceSize = CGSize(width: 300, height: 44)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(LandscapeMoreSettingCollectionViewCell.self, forCellWithReuseIdentifier: kCellId)
        collectionView.register(LandscapeMoreSettingHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderId)
        
        rightContainerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(controlView()!.safeAreaLayoutGuide.snp.right)
        }
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, String>>(configureCell: {
            (_, cv, indexPath, element) in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: self.kCellId, for: indexPath) as! LandscapeMoreSettingCollectionViewCell
            cell.model = element
            if indexPath.section == 0 {
                if indexPath.row == self.currentScaleIndex { cell.setSelectStyle(isSelect: true) }
                else { cell.setSelectStyle(isSelect: false) }
            }
            return cell
        }, configureSupplementaryView: {
            (ds, cv, kind, indexPath) in
            let header = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kHeaderId, for: indexPath) as! LandscapeMoreSettingHeaderView
            header.model = ds[indexPath.section].model
            return header
        })
        dataListArr.asObservable().bind(to: collectionView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        let playerScale = SectionModel<String, String>(model: "画面尺寸", items: ["适应", "拉伸", "填充"])
        dataListArr.onNext([playerScale])
        
        collectionView.rx.itemSelected.bind { (indexPath) in
            if indexPath.section == 0 {
                self.currentScaleIndex = indexPath.row
                switch indexPath.row {
                case 0: self.videoPlayer.videoGravity = .resizeAspect
                case 1: self.videoPlayer.videoGravity = .resizeAspectFill
                case 2: self.videoPlayer.videoGravity = .resize
                default: break
                }
            }
            self.collectionView.reloadData()
        }.disposed(by: disposeBag)
        
        rightAdapter.reload()
    }
}
