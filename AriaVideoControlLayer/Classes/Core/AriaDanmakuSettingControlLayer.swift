//
//  AriaDanmakuSettingControlLayer.swift
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

class AriaDanmakuSettingControlLayer: SJEdgeControlLayerAdapters, SJControlLayer {
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
    
    var model: [[[String : Any]]]! = AriaSettingsUtil.getDanmakuSettings()
    fileprivate var dataListArr = BehaviorSubject(value: [SectionModel<String, [String: Any]>]())
    
    fileprivate let kSliderCellId = "com.moxcomic.DanmakuSetting.Slider.CellId"
    fileprivate lazy var tableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.tableFooterView = UIView()
        $0.rowHeight = 44
    }
}

extension AriaDanmakuSettingControlLayer {
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

extension AriaDanmakuSettingControlLayer {
    func setupView() {
        rightWidth = 300
        
        tableView.register(DanmakuSettingSliderTableViewCell.self, forCellReuseIdentifier: self.kSliderCellId)
        rightContainerView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(controlView()!.safeAreaLayoutGuide.snp.right)
        }
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, [String: Any]>>(configureCell: {
            (_, tv, indexPath, element) in
            let cell = tv.dequeueReusableCell(withIdentifier: self.kSliderCellId, for: indexPath) as! DanmakuSettingSliderTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.model = element
            return cell
        })
        dataListArr.asObserver().bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: (Int(currentHeight) - 44 * model[0].count) / 2))
        var settingsModel = [SectionModel<String, [String: Any]>]()
        for i in 0..<model.count {
            settingsModel.append(SectionModel<String, [String : Any]>(model: String(i), items: model[i]))
        }
        dataListArr.onNext(settingsModel)
        
        rightAdapter.reload()
    }
}
