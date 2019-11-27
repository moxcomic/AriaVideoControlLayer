//
//  AriaVideoControlLayer.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/16.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SJVideoPlayer
import SnapKit
import Then
import RxSwift
import RxDataSources
import SJUIKit
import AriaSwiftyChain

// MARK: - Top
let SJEdgeControlLayerTopItem_Back = 10000
let SJEdgeControlLayerTopItem_Title = 10001
let SJEdgeControlLayerTopItem_PlaceholderBack = 10002

// MARK: - Left
let SJEdgeControlLayerLeftItem_Lock = 2000

// MARK: - Bottom
let SJEdgeControlLayerBottomItem_Play = 30000
let SJEdgeControlLayerBottomItem_CurrentTime = 30001
let SJEdgeControlLayerBottomItem_DurationTime = 30002
let SJEdgeControlLayerBottomItem_Separator = 30003
let SJEdgeControlLayerBottomItem_Progress = 30004
let SJEdgeControlLayerBottomItem_FullBtn = 30005
let SJEdgeControlLayerBottomItem_LIVEText = 30006

// MARK: - Center
let SJEdgeControlLayerCenterItem_Replay = 40000

// MARK: - 
let kDanmakuSwitchTag = 300007
let kDanmakuSettingTag = 300008
let kDanmakuInputTag = 300009
let kRateTag = 300010
let kDefinitionTag = 300011
let kNextVideoTag = 300100
let kMoreTag = 300101
let kShareTag = 300102

let kFullScreenSliderTag = 400001

let rateControlLayerTag = LONG_MAX - 10
let danmakuControlLayerTag = LONG_MAX - 11
let selectionControlLayerTag = LONG_MAX - 12
let protraitMoreSettingControlLayerTag = LONG_MAX - 13
let landscapeMoreSettingControlLayerTag = LONG_MAX - 14
let danmakuSettingControlLayerTag = LONG_MAX - 15

public class AriaVideoControlLayer: SJEdgeControlLayerAdapters, SJControlLayer, SJEdgeControlLayerDelegate {
    fileprivate let disposeBag = DisposeBag()
    fileprivate weak var videoPlayer: SJVideoPlayer!
    fileprivate var reachabilityObserver: SJReachabilityObserver!
    fileprivate var backItem: SJEdgeControlButtonItem!
    
    fileprivate lazy var fullScreenStatusBar = AriaFullScreenStatusBar()
    
    fileprivate lazy var selectionControlLayer = AriaSelectionControlLayer()
    
    weak var delegate: SJEdgeControlLayerDelegate!
    
    open var isShowNetworkSpeedToLoadingView = true
    open var isHiddenBackButtonWhenOrientationIsPortrait = false
    open var bottomProgressIndicatorHeight: CGFloat = 2.0
    open var isShowResidentBackButton = true
    open var isDisabledPromptWhenNetworkStatusChanges = false
    open var isHiddenBottomProgressIndicator = false
    open var isDanmakuEnable = false
    
    open var currentPlayIndex = 0 {
        didSet {
            selectionControlLayer.currentPlayIndex = currentPlayIndex
        }
    }
    open var playListCount = 1 {
        didSet {
            if playListCount < 1 { playListCount = 1 }
            else { selectionControlLayer.playListCount = playListCount }
        }
    }
    open var playTheIndexBlock: ((Int) -> ())? {
        didSet {
            selectionControlLayer.playTheIndexBlock = playTheIndexBlock
        }
    }
    open var shareBlock: (() -> ())?
    
    fileprivate lazy var loadingView: SJEdgeControlLayerLoadingViewProtocol = SJNetworkLoadingView().then {
        $0.lineColor = SJEdgeControlLayerSettings.common().loadingLineColor
        controlView()?.addSubview($0)
        $0.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    lazy var bottomProgressIndicator = SJProgressSlider().then {
        $0.pan.isEnabled = true
        $0.trackHeight = bottomProgressIndicatorHeight
        let setting = SJEdgeControlLayerSettings.common()
        let traceColor = setting.bottomIndicator_traceColor ?? setting.progress_traceColor
        let trackColor = setting.bottomIndicator_trackColor ?? setting.progress_trackColor
        $0.traceImageView.backgroundColor = traceColor
        $0.trackImageView.backgroundColor = trackColor
    }
    
    lazy var draggingProgressView = SJVideoPlayerDraggingProgressView().then {
        if let image = self.videoPlayer.presentView.placeholderImageView.image {
            $0.setPreviewImage(image)
        }
        sj_view_makeDisappear($0, false)
    }
    
    lazy var lockStateTappedTimerControl = SJTimerControl().then {
        $0.exeBlock = { [weak self] (control) in
            guard let strongSelf = self else { return }
            sj_view_makeDisappear(strongSelf.rightContainerView, true);
            control.clear()
        }
    }
    
    lazy var residentBackButton = UIButton().then {
        $0.setImage(SJEdgeControlLayerSettings.common().backBtnImage, for: .normal)
        $0.addTarget(self, action: #selector(tappedBackItem), for: .touchUpInside)
    }
    
    public func controlView() -> UIView! {
        return self
    }
    
    public var restarted: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        autoAdjustTopSpacing = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - internal method
extension AriaVideoControlLayer {
    public func restartControlLayer() {
        restarted = true
        sj_view_makeAppear(controlView(), true)
        showOrHiddenLoadingView()
        videoPlayer.urlAsset != nil ? videoPlayer.controlLayerNeedAppear() : videoPlayer.controlLayerNeedDisappear()
    }
    
    public func exitControlLayer() {
        restarted = false
        
        sj_view_makeDisappear(controlView(), true) {
            if !self.restarted { self.controlView()?.removeFromSuperview() }
        }
        
        sj_view_makeDisappear(topContainerView, true)
        sj_view_makeDisappear(leftContainerView, true)
        sj_view_makeDisappear(bottomContainerView, true)
        sj_view_makeDisappear(rightContainerView, true)
        sj_view_makeDisappear(draggingProgressView, true)
        sj_view_makeDisappear(centerContainerView, true)
    }
    
    public func controlLayer(ofVideoPlayerCanAutomaticallyDisappear videoPlayer: SJBaseVideoPlayer!) -> Bool {
        let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)?.customView ?? getFullScreenSlider()
        guard
            let slider = progressItem as? SJProgressSlider else { return false }
        return !slider.isDragging
    }
    
    public func controlLayerNeedAppear(_ videoPlayer: SJBaseVideoPlayer!) {
        if videoPlayer.isLockedScreen { return }
        
        updateResidentBackButtonAppearStateIfNeeded()
        updateContainerViewsAppearState()
        updateAdaptersIfNeeded()
        updateBottomCurrentTimeItemIfNeeded()
        updateBottomProgressSliderItemIfNeeded()
    }
    
    public func controlLayerNeedDisappear(_ videoPlayer: SJBaseVideoPlayer!) {
        if videoPlayer.isLockedScreen { return }
        
        updateResidentBackButtonAppearStateIfNeeded()
        updateContainerViewsAppearState()
    }
    
    public func installedControlView(to videoPlayer: SJBaseVideoPlayer!) {
        videoPlayer.popPromptController.bottomMargin = bottomHeight
        
        self.videoPlayer = videoPlayer as? SJVideoPlayer
        self.videoPlayer.switcher.addControlLayer(forIdentifier: rateControlLayerTag) { (id) -> SJControlLayer in
            return AriaRateControlLayer()
        }
        
        self.videoPlayer.switcher.addControlLayer(forIdentifier: danmakuControlLayerTag) { (id) -> SJControlLayer in
            return AriaDanmakuControlLayer()
        }
        
        self.videoPlayer.switcher.addControlLayer(forIdentifier: selectionControlLayerTag) { (id) -> SJControlLayer in
            return self.selectionControlLayer
        }
        
        self.videoPlayer.switcher.addControlLayer(forIdentifier: landscapeMoreSettingControlLayerTag) { (id) -> SJControlLayer in
            return AriaLandscapeMoreSettingControlLayer()
        }
        
        self.videoPlayer.switcher.addControlLayer(forIdentifier: danmakuSettingControlLayerTag) { (id) -> SJControlLayer in
            return AriaDanmakuSettingControlLayer()
        }
        
        sj_view_makeDisappear(topContainerView, false);
        sj_view_makeDisappear(leftContainerView, false);
        sj_view_makeDisappear(bottomContainerView, false);
        sj_view_makeDisappear(rightContainerView, false);
        sj_view_makeDisappear(centerContainerView, false);
        
        updateBottomTimeLabelSize()
        updateBottomCurrentTimeItemIfNeeded()
        updateBottomDurationItemIfNeeded()
        
        reachabilityObserver = videoPlayer.reachability.getObserver()
        reachabilityObserver.networkSpeedDidChangeExeBlock = { [weak self] r in
            guard let strongSelf = self else { return }
            strongSelf.updateNetworkSpeedStrForLoadingView()
        }
        
        showOrRemoveBottomProgressIndicator()
    }
    
    public func lockedVideoPlayer(_ videoPlayer: SJBaseVideoPlayer!) {
        updateResidentBackButtonAppearStateIfNeeded()
        updateContainerViewsAppearState()
        updateAdaptersIfNeeded()
        lockStateTappedTimerControl.start()
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, panGestureTriggeredInTheHorizontalDirection state: SJPanGestureRecognizerState, progressTime: TimeInterval) {
        switch state {
        case SJPanGestureRecognizerStateBegan: onDragStart()
        case SJPanGestureRecognizerStateChanged: onDragMoving(progressTime: progressTime)
        case SJPanGestureRecognizerStateEnded: onDragMoveEnd()
        default: break
        }
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, gestureRecognizerShouldTrigger type: SJPlayerGestureType, location: CGPoint) -> Bool {
        var adapter: SJEdgeControlLayerItemAdapter!
        
        let locationInTheView: ((UIView?) -> Bool)? = { container in
            return container!.frame.contains(location) && !sj_view_isDisappeared(container!)
        }

        if locationInTheView!(topContainerView) { adapter = topAdapter }
        else if locationInTheView!(bottomContainerView) { adapter = bottomAdapter }
        else if locationInTheView!(leftContainerView) { adapter = leftAdapter }
        else if locationInTheView!(rightContainerView) { adapter = rightAdapter }
        else if locationInTheView!(centerContainerView) { adapter = centerAdapter }
        
        if adapter == nil { return true }
        
        let point = self.controlView().convert(location, to: adapter.view)
        if !adapter.view.frame.contains(point) { return true }

        guard
            let item = adapter.item(at: point),
            let target = item.target
        else { return false }
        
        return target.responds(to: item.action)
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, prepareToPlay asset: SJVideoPlayerURLAsset!) {
        updateBottomTimeLabelSize()
        updateBottomDurationItemIfNeeded()
        updateBottomCurrentTimeItemIfNeeded()
        updateBottomProgressIndicatorIfNeeded()
        updateResidentBackButtonAppearStateIfNeeded()
        updateAdaptersIfNeeded()
        showOrHiddenLoadingView()
    }
    
    public func videoPlayerPlaybackStatusDidChange(_ videoPlayer: SJBaseVideoPlayer!) {
        updateAdaptersIfNeeded()
        showOrHiddenLoadingView()
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, currentTimeDidChange currentTime: TimeInterval) {
        updateBottomCurrentTimeItemIfNeeded()
        updateBottomProgressIndicatorIfNeeded()
        updateBottomProgressSliderItemIfNeeded()
        updateDraggingProgressViewCurrentTimeIfNeeded()
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, durationDidChange duration: TimeInterval) {
        updateBottomTimeLabelSize()
        updateBottomDurationItemIfNeeded()
        updateBottomProgressIndicatorIfNeeded()
        updateBottomProgressSliderItemIfNeeded()
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, willRotateView isFull: Bool) {
        updateResidentBackButtonAppearStateIfNeeded()
        updateContainerViewsAppearState()
        updateAdaptersIfNeeded()
        
        updateBottomProgressSliderItemIfNeeded()
        updateDraggingProgressViewCurrentTimeIfNeeded()

        if !sj_view_isDisappeared(bottomProgressIndicator) { sj_view_makeDisappear(bottomProgressIndicator, false) }
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, didEndRotation isFull: Bool) {
        if isFull {
            addLandscapeItemsToBottomAdapter()
            fullScreenStatusBar.isHidden = false
            setHiddenBottomProgressIndicator(isHiddenBottomProgressIndicator: true)
            topAdapter.item(forTag: kShareTag)?.isHidden = false
            topAdapter.item(forTag: kMoreTag)?.isHidden = false
        }
        else {
            addPortraitItemsToBottomAdapter()
            fullScreenStatusBar.isHidden = true
            setHiddenBottomProgressIndicator(isHiddenBottomProgressIndicator: false)
            topAdapter.item(forTag: kShareTag)?.isHidden = true
            topAdapter.item(forTag: kMoreTag)?.isHidden = true
        }
        
        updateBottomTimeLabelSize()
        updateBottomCurrentTimeItemIfNeeded()
        updateBottomDurationItemIfNeeded()
        
        updateResidentBackButtonAppearStateIfNeeded()
        updateContainerViewsAppearState()
        updateAdaptersIfNeeded()
        
        updateBottomProgressSliderItemIfNeeded()
        updateDraggingProgressViewCurrentTimeIfNeeded()

        if !sj_view_isDisappeared(bottomProgressIndicator) { sj_view_makeDisappear(bottomProgressIndicator, false) }
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, willFitOnScreen isFitOnScreen: Bool) {
        updateResidentBackButtonAppearStateIfNeeded()
        updateContainerViewsAppearState()
        updateAdaptersIfNeeded()
        
        updateBottomProgressSliderItemIfNeeded()
        updateDraggingProgressViewCurrentTimeIfNeeded()
        
        if !sj_view_isDisappeared(bottomProgressIndicator) { sj_view_makeDisappear(bottomProgressIndicator, false) }
    }
    
    public func tappedPlayer(onTheLockedState videoPlayer: SJBaseVideoPlayer!) {
        if sj_view_isDisappeared(rightContainerView) {
            sj_view_makeAppear(rightContainerView, true)
            lockStateTappedTimerControl.start()
        } else {
            sj_view_makeDisappear(rightContainerView, true);
            lockStateTappedTimerControl.clear()
        }
    }
    
    public func unlockedVideoPlayer(_ videoPlayer: SJBaseVideoPlayer!) {
        lockStateTappedTimerControl.clear()
        videoPlayer.controlLayerNeedAppear()
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, playbackTypeDidChange playbackType: SJPlaybackType) {
        let currentTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_CurrentTime)
        let separatorItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Separator)
        let durationTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_DurationTime)
        let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)
        let liveItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_LIVEText)
        switch playbackType {
        case SJPlaybackTypeLIVE:
            currentTimeItem?.isHidden = true
            separatorItem?.isHidden = true
            durationTimeItem?.isHidden = true
            progressItem?.isHidden = true
            liveItem?.isHidden = false
        case SJPlaybackTypeUnknown, SJPlaybackTypeVOD, SJPlaybackTypeVOD, SJPlaybackTypeFILE:
            currentTimeItem?.isHidden = false
            separatorItem?.isHidden = false
            durationTimeItem?.isHidden = false
            progressItem?.isHidden = false
            liveItem?.isHidden = true
            bottomAdapter.removeItem(forTag: SJEdgeControlLayerBottomItem_LIVEText)
        default: break
        }
        bottomAdapter.reload()
        showOrRemoveBottomProgressIndicator()
    }
    
    public func videoPlayer(_ videoPlayer: SJBaseVideoPlayer!, reachabilityChanged status: SJNetworkStatus) {
        if isDisabledPromptWhenNetworkStatusChanges { return }
        if videoPlayer.assetURL!.isFileURL { return } // return when is local video.
        switch status {
            
        case .notReachable:
            videoPlayer.prompt.show(NSAttributedString.sj_UIKitText({ (make) in
                _ = make.append(SJEdgeControlLayerSettings.common().notReachablePrompt)
                _ = make.textColor(.white)
            }), duration: 3)
        case .reachableViaWWAN:
            videoPlayer.prompt.show(NSAttributedString.sj_UIKitText({ (make) in
                _ = make.append(SJEdgeControlLayerSettings.common().reachableViaWWANPrompt)
                _ = make.textColor(.white)
            }), duration: 3)
        case .reachableViaWiFi: break
        default: break
        }
    }
}

// MARK: - setup view
extension AriaVideoControlLayer {
    fileprivate func setupView() {
        addItemsToTopAdapter()
        addItemsToLeftAdapter()
        addPortraitItemsToBottomAdapter()
        addItemsToRightAdapter()
        addItemsToCenterAdapter()
        
        topContainerView.sjv_disappearDirection = SJViewDisappearAnimation_Top
        leftContainerView.sjv_disappearDirection = SJViewDisappearAnimation_Left
        bottomContainerView.sjv_disappearDirection = SJViewDisappearAnimation_Bottom
        rightContainerView.sjv_disappearDirection = SJViewDisappearAnimation_Right
        centerContainerView.sjv_disappearDirection = SJViewDisappearAnimation_None
        
        sj_view_initializes(
            [topContainerView,
             leftContainerView,
             bottomContainerView,
             rightContainerView
            ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetControlLayerAppearIntervalForItemIfNeeded(note:)), name: NSNotification.Name.SJEdgeControlButtonItemPerformedAction, object: nil)
    }
    
    fileprivate func addItemsToTopAdapter() {
        topContainerView.addSubview(fullScreenStatusBar)
        
        backItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: SJEdgeControlLayerTopItem_Back)
        backItem.addTarget(self, action: #selector(tappedBackItem))
        topAdapter.add(backItem)

        let titleItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49xFill, tag: SJEdgeControlLayerTopItem_Title)
        topAdapter.add(titleItem)
        
        let shareItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kShareTag)
        shareItem.addTarget(self, action: #selector(tappedShareItem))
        shareItem.isHidden = true
        shareItem.image = UIImage(named: "share", in: imageBunde, compatibleWith: nil)
        topAdapter.add(shareItem)
        
        let moreItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kMoreTag)
        moreItem.addTarget(self, action: #selector(tappedMoreItem))
        moreItem.isHidden = true
        moreItem.image = UIImage(named: "moreButton", in: imageBunde, compatibleWith: nil)
        topAdapter.add(moreItem)
        
        topAdapter.reload()
    }
    
    func addItemsToLeftAdapter() {
        
    }
    
    func addItemsToRightAdapter() {
        let lockItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: SJEdgeControlLayerLeftItem_Lock)
        lockItem.addTarget(self, action: #selector(tappedLockItem))
        rightAdapter.add(lockItem)
        
        rightAdapter.reload()
    }
    
    func addItemsToCenterAdapter() {
        let replayLabel = UILabel().then { $0.numberOfLines = 0 }
        let replayItem = SJEdgeControlButtonItem.frameLayout(withCustomView: replayLabel, tag: SJEdgeControlLayerCenterItem_Replay)
        replayItem.addTarget(self, action: #selector(tappedReplayItem))
        centerAdapter.add(replayItem)
        centerAdapter.reload()
    }
    
    fileprivate func addPortraitItemsToBottomAdapter() {
        getFullScreenSlider()?.removeFromSuperview()
        bottomAdapter.removeAllItems()
        
        // 播放按钮
        let playItem = SJEdgeControlButtonItem.placeholder(with:SJButtonItemPlaceholderType_49x49, tag: SJEdgeControlLayerBottomItem_Play)
        playItem.image = SJEdgeControlLayerSettings.common().playBtnImage
        playItem.addTarget(self, action: #selector(tappedPlayItem))
        bottomAdapter.add(playItem)
        
        let liveItem = SJEdgeControlButtonItem(tag: SJEdgeControlLayerBottomItem_LIVEText)
        liveItem.isHidden = true
        bottomAdapter.add(liveItem)
        
        // 播放进度条
        let slider = SJProgressSlider()
        slider.thumbImageView.image = UIImage(named: "slider", in: imageBunde, compatibleWith: nil)
        slider.thumbImageView.contentMode = .scaleToFill
        slider.setThumbCornerRadius(0, size: CGSize(width: 16, height: 14), thumbBackgroundColor: .clear)
        slider.trackHeight = 2
        slider.delegate = self
        slider.tap.isEnabled = true
        slider.enableBufferProgress = true
        slider.tappedExeBlock = { [weak self] (slider, location) in
            guard
                let strongSelf = self,
                let videoPlayer = strongSelf.videoPlayer,
                let canSeekToTime = strongSelf.videoPlayer.canSeekToTime
            else { return }

            if !canSeekToTime(videoPlayer) { return }

            if strongSelf.videoPlayer.assetStatus == .readyToPlay { return }

            videoPlayer.seek(toTime: TimeInterval(location), completionHandler: nil)
        }
        let progressItem = SJEdgeControlButtonItem(customView: slider, tag: SJEdgeControlLayerBottomItem_Progress)
        progressItem.insets = SJEdgeInsetsMake(8, 8)
        progressItem.fill = true
        bottomAdapter.add(progressItem)
        
        // 当前时间
        let currentTimeItem = SJEdgeControlButtonItem.placeholder(withSize:8, tag: SJEdgeControlLayerBottomItem_CurrentTime)
        bottomAdapter.add(currentTimeItem)
        
        // 时间分隔符
        let separatorItem = SJEdgeControlButtonItem(title: NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("/ ").font(UIFont.systemFont(ofSize: 11)).textColor(.white).alignment(.center)
        }), target: nil, action: nil, tag: 100005)
        bottomAdapter.add(separatorItem)
        
        // 全部时长
        let durationTimeItem = SJEdgeControlButtonItem.placeholder(withSize:8, tag: SJEdgeControlLayerBottomItem_DurationTime)
        bottomAdapter.add(durationTimeItem)

        // 全屏按钮
        let fullItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: 100007)
        fullItem.image = UIImage(named: "fullScreenButton", in: imageBunde, compatibleWith: nil)
        fullItem.addTarget(self, action:#selector(tappedFullItem))
        bottomAdapter.add(fullItem)
        
        bottomAdapter.reload()
    }
    
    fileprivate func addLandscapeItemsToBottomAdapter() {
        if let porSlider = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)?.customView as? SJProgressSlider {
            porSlider.delegate = nil
        }
        bottomAdapter.removeAllItems()
        
        // 播放进度条
        let slider = SJProgressSlider()
        slider.thumbImageView.image = UIImage(named: "slider", in: imageBunde, compatibleWith: nil)
        slider.thumbImageView.contentMode = .scaleToFill
        slider.setThumbCornerRadius(0, size: CGSize(width: 16, height: 14), thumbBackgroundColor: .clear)
        slider.trackHeight = 2
        slider.delegate = self
        slider.tap.isEnabled = true
        slider.enableBufferProgress = true
        slider.tappedExeBlock = { [weak self] (slider, location) in
            guard
                let strongSelf = self,
                let videoPlayer = strongSelf.videoPlayer,
                let canSeekToTime = strongSelf.videoPlayer.canSeekToTime
            else { return }

            if !canSeekToTime(videoPlayer) { return }

            if strongSelf.videoPlayer.assetStatus == .readyToPlay { return }

            videoPlayer.seek(toTime: TimeInterval(location), completionHandler: nil)
        }
        slider.tag = kFullScreenSliderTag
        
        bottomContainerView.addSubview(slider)
        bottomContainerView.bringSubviewToFront(slider)
        slider.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalTo(bottomAdapter.view.snp.left)
            make.right.equalTo(bottomAdapter.view.snp.right)
            make.height.equalTo(10)
        }
        
        // 播放按钮
        let playItem = SJEdgeControlButtonItem.placeholder(with:SJButtonItemPlaceholderType_49x49, tag: SJEdgeControlLayerBottomItem_Play)
        playItem.image = SJEdgeControlLayerSettings.common().playBtnImage
        playItem.addTarget(self, action: #selector(tappedPlayItem))
        bottomAdapter.add(playItem)

        let liveItem = SJEdgeControlButtonItem(tag: SJEdgeControlLayerBottomItem_LIVEText)
        liveItem.isHidden = true
        bottomAdapter.add(liveItem)
        
        // 下一集按钮
        if playListCount > 1 {
            let nextItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kNextVideoTag)
            nextItem.image = UIImage(named: "nextVideo", in: imageBunde, compatibleWith: nil)
            nextItem.addTarget(self, action: #selector(tappedNextItem))
            bottomAdapter.add(nextItem)
        }
        
        // 当前时间
        let currentTimeItem = SJEdgeControlButtonItem.placeholder(withSize:8, tag: SJEdgeControlLayerBottomItem_CurrentTime)
        bottomAdapter.add(currentTimeItem)
        
        // 时间分隔符
        let separatorItem = SJEdgeControlButtonItem(title: NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("/ ").font(UIFont.systemFont(ofSize: 11)).textColor(.white).alignment(.center)
        }), target: nil, action: nil, tag: 300004)
        bottomAdapter.add(separatorItem)
        
        // 全部时长
        let durationTimeItem = SJEdgeControlButtonItem.placeholder(withSize:8, tag: SJEdgeControlLayerBottomItem_DurationTime)
        bottomAdapter.add(durationTimeItem)
        
        let danmakuSwitch = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kDanmakuSwitchTag)
        danmakuSwitch.image = UIImage(named: "danmakuSwitchOn", in: imageBunde, compatibleWith: nil)
        danmakuSwitch.addTarget(self, action: #selector(tappedDanmakuSwitchItem))
        bottomAdapter.add(danmakuSwitch)
        
        let danmakuSetting = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kDanmakuSettingTag)
        danmakuSetting.image = UIImage(named: "danmakuSetting", in: imageBunde, compatibleWith: nil)
        danmakuSetting.addTarget(self, action: #selector(tappedDanmakuSettingItem))
        bottomAdapter.add(danmakuSetting)
        
        let danmakuInput = SJEdgeControlButtonItem(customView: UIView().then { (v) in
            let input = UITextField().then { (tf) in
                tf.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
                tf.layer.cornerRadius = 7
                tf.layer.masksToBounds = true
                tf.attributedPlaceholder = NSAttributedString.sj_UIKitText({ (make) in
                    _ = make.append("发个友善的弹幕见证当下")
                    _ = make.textColor(UIColor.white.withAlphaComponent(0.5))
                    _ = make.font(.systemFont(ofSize: 12))
                })
                tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
                tf.leftViewMode = .always
            }
            input.rx.controlEvent([.editingDidBegin]).asObservable().bind {
                self.tappedDanmakuInputItem()
            }.disposed(by: disposeBag)
            v.addSubview(input)
            input.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.right.equalToSuperview()
                make.height.equalTo(30)
            }
        }, tag: kDanmakuInputTag)
        danmakuInput.addTarget(self, action: #selector(tappedDanmakuInputItem))
        danmakuInput.insets = SJEdgeInsetsMake(8, 8)
        danmakuInput.fill = true
        bottomAdapter.add(danmakuInput)
        
        let selection = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: 300009)
        selection.addTarget(self, action: #selector(tappedSelectionItem))
        selection.title = NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("选集")
            _ = make.font(.systemFont(ofSize: 16))
            _ = make.alignment(.center)
            _ = make.textColor(.white)
        })
        selection.insets = SJEdgeInsetsMake(8, 8)
        bottomAdapter.add(selection)
        
        let rate = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kRateTag)
        rate.addTarget(self, action: #selector(tappedRateItem))
        rate.title = NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("倍速")
            _ = make.font(.systemFont(ofSize: 16))
            _ = make.alignment(.center)
            _ = make.textColor(.white)
        })
        rate.insets = SJEdgeInsetsMake(8, 8)
        bottomAdapter.add(rate)
        
        let definition = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag: kDefinitionTag)
        definition.addTarget(self, action: #selector(tappedDefinitionItem))
        definition.title = NSAttributedString.sj_UIKitText({ (make) in
            _ = make.append("自动")
            _ = make.font(.systemFont(ofSize: 16))
            _ = make.alignment(.center)
            _ = make.textColor(.white)
        })
        definition.insets = SJEdgeInsetsMake(8, 0)
        bottomAdapter.add(definition)
        
        bottomAdapter.reload()
    }
}

// MARK: - resident Back Button
extension AriaVideoControlLayer {
    func setShowResidentBackButton(isShowResidentBackButton: Bool) {
        if isShowResidentBackButton == self.isShowResidentBackButton { return }
        
        self.isShowResidentBackButton = isShowResidentBackButton
        DispatchQueue.main.async {
            if self.isShowResidentBackButton {
                self.controlView()?.addSubview(self.residentBackButton)
                self.residentBackButton.snp.makeConstraints { (make) in
                    make.top.left.bottom.equalTo(self.topAdapter.view)
                    make.width.equalTo(self.topAdapter.view.snp.height)
                }
                
                // placeholder item
                var placeholderItem = self.topAdapter.item(forTag: SJEdgeControlLayerTopItem_PlaceholderBack)
                if ( placeholderItem == nil ) {
                    placeholderItem = SJEdgeControlButtonItem.placeholder(with: SJButtonItemPlaceholderType_49x49, tag:SJEdgeControlLayerTopItem_PlaceholderBack)
                }
                self.topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_Back)
                self.topAdapter.insert(placeholderItem!, at:0)
                self.updateResidentBackButtonAppearStateIfNeeded()
                self.topAdapter.reload()
            } else {
                self.residentBackButton.removeFromSuperview()
                
                // back item
                self.topAdapter.removeItem(forTag: SJEdgeControlLayerTopItem_PlaceholderBack)
                self.topAdapter.insert(self.backItem, at: 0)
                self.topAdapter.reload()
            }
        }
    }
}

// MARK: - bottom progress slider delegate
extension AriaVideoControlLayer: SJProgressSliderDelegate {
    public func sliderWillBeginDragging(_ slider: SJProgressSlider) {
        if videoPlayer.assetStatus != SJAssetStatus.readyToPlay {
            slider.cancelDragging()
            return
        }
        else if videoPlayer.canSeekToTime != nil && !videoPlayer.canSeekToTime!(videoPlayer) {
            slider.cancelDragging()
            return
        }
        
        onDragStart()
    }
    
    public func slider(_ slider: SJProgressSlider, valueDidChange value: CGFloat) {
        if slider.isDragging { onDragMoving(progressTime: TimeInterval(value)) }
    }
    
    public func sliderDidEndDragging(_ slider: SJProgressSlider) {
        onDragMoveEnd()
    }
}

// MARK: - bottom progress indicator
extension AriaVideoControlLayer {
    func setHiddenBottomProgressIndicator(isHiddenBottomProgressIndicator: Bool) {
        if self.isHiddenBottomProgressIndicator != isHiddenBottomProgressIndicator {
            self.isHiddenBottomProgressIndicator = isHiddenBottomProgressIndicator
            
            DispatchQueue.main.async {
                self.showOrRemoveBottomProgressIndicator()
            }
        }
    }
    
    func setBottomProgressIndicatorHeight(bottomProgressIndicatorHeight: CGFloat) {
        if self.bottomProgressIndicatorHeight != bottomProgressIndicatorHeight {
            self.bottomProgressIndicatorHeight = bottomProgressIndicatorHeight
            
            DispatchQueue.main.async {
                self.bottomProgressIndicator.trackHeight = bottomProgressIndicatorHeight
                self.bottomProgressIndicator.snp.makeConstraints { (make) in
                    make.height.equalTo(bottomProgressIndicatorHeight)
                }
            }
        }
    }
}

// MARK: - loading view
extension AriaVideoControlLayer {
    func setLoadingView(loadingView: SJEdgeControlLayerLoadingViewProtocol?) {
        guard let lv = self.loadingView as? UIView else { return }
        lv.removeFromSuperview()
        self.loadingView = loadingView!
        
        guard let l = loadingView as? UIView else { return }
        self.controlView()?.addSubview(l)
        l.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    func setShowNetworkSpeedToLoadingView(isShowNetworkSpeedToLoadingView: Bool) {
        self.isShowNetworkSpeedToLoadingView = isShowNetworkSpeedToLoadingView
        if !isShowNetworkSpeedToLoadingView { self.loadingView.networkSpeedStr = nil }
    }
}

// MARK: - update view
extension AriaVideoControlLayer {
    func updateAdaptersIfNeeded() {
        updateTopAdapterIfNeeded()
        updateLeftAdapterIfNeeded()
        updateBottomAdapterIfNeeded()
        updateRightAdapterIfNeeded()
        updateCenterAdapterIfNeeded()
    }
    
    func updateTopAdapterIfNeeded() {
        if sj_view_isDisappeared(topContainerView) { return }
        let sources = SJEdgeControlLayerSettings.common()
        let isFullscreen = videoPlayer.isFullScreen
        let isFitOnScreen = videoPlayer.isFitOnScreen
        let isPlayOnScrollView = videoPlayer.isPlayOnScrollView
        
        // back item
        if let backItem = topAdapter.item(forTag: SJEdgeControlLayerTopItem_Back) {
            if isFullscreen || isFitOnScreen { backItem.isHidden = false }
            else if isHiddenBackButtonWhenOrientationIsPortrait { backItem.isHidden = true }
            else { backItem.isHidden = isPlayOnScrollView }
            
            if !backItem.isHidden { backItem.image = sources.backBtnImage }
        }
        
        // title item
        if let titleItem = topAdapter.item(forTag: SJEdgeControlLayerTopItem_Title) {
            if let asset = videoPlayer.urlAsset?.origin ?? videoPlayer.urlAsset {
                let attributedTitle = asset.attributedTitle
                let title = asset.title
                if attributedTitle != nil && attributedTitle!.length != 0 { titleItem.title = attributedTitle }
                else if title != nil && title!.count != 0 {
                    if titleItem.title != nil && titleItem.title!.isEqual(title!) { return }
                    titleItem.title = NSAttributedString.sj_UIKitText({ (make) in
                        _ = make.append(title!)
                        _ = make.font(sources.titleFont)
                        _ = make.textColor(sources.titleColor)
                        _ = make.lineBreakMode(.byTruncatingTail)
                        _ = make.shadow({ (make) in
                            make.shadowOffset = CGSize(width: 0, height: 0.5)
                            make.shadowColor = UIColor.black
                        })
                    })
                }
                
                titleItem.isHidden = (titleItem.title!.length == 0)
                
                if !titleItem.isHidden {
                    // margin
                    let atIndex = topAdapter.indexOfItem(forTag: SJEdgeControlLayerTopItem_Title)
                    let left: CGFloat  = topAdapter.itemsIsHidden(with: NSRange(location: 0, length: atIndex)) ? 16 : 0
                    let right: CGFloat = topAdapter.itemsIsHidden(with: NSRange(location: atIndex, length: topAdapter.itemCount)) ? 16 : 0
                    titleItem.insets = SJEdgeInsetsMake(left, right);
                }
            }
        }
        
        topAdapter.reload()
    }
    
    func updateLeftAdapterIfNeeded() {
        //        if sj_view_isDisappeared(leftContainerView) { return }
    }
    
    func updateRightAdapterIfNeeded() {
        //if sj_view_isDisappeared(rightContainerView) { return }
        
        let isFullscreen = videoPlayer.isFullScreen
        let isLockedScreen = videoPlayer.isLockedScreen

        if let lockItem = rightAdapter.item(forTag: SJEdgeControlLayerLeftItem_Lock) {
            lockItem.isHidden = !isFullscreen
            if !lockItem.isHidden {
                let setting = SJEdgeControlLayerSettings.common()
                lockItem.image = isLockedScreen ? setting.lockBtnImage : setting.unlockBtnImage
            }
        }
        
        rightAdapter.reload()
    }
    
    func updateCenterAdapterIfNeeded() {
        if sj_view_isDisappeared(centerContainerView) { return }
        
        if let replayItem = centerAdapter.item(forTag: SJEdgeControlLayerCenterItem_Replay) {
            replayItem.isHidden = !videoPlayer.isPlayedToEndTime
            if !replayItem.isHidden && replayItem.title == nil {
                let sources = SJEdgeControlLayerSettings.common()
                if let textLabel = replayItem.customView as? UILabel {
                    textLabel.attributedText = NSAttributedString.sj_UIKitText({ (make) in
                        _ = make.alignment(.center).lineSpacing(6)
                        _ = make.font(sources.replayBtnFont)
                        _ = make.textColor(sources.replayBtnTitleColor)
                        if sources.replayBtnImage.cgImage != nil {
                            _ = make.appendImage({ (make) in
                                make.image = sources.replayBtnImage
                            })
                        }
                        if sources.replayBtnTitle.count != 0 {
                            if sources.replayBtnImage.cgImage != nil { _ = make.append("\n") }
                            _ = make.append(sources.replayBtnTitle)
                        }
                    })
                    textLabel.bounds = CGRect(origin: CGPoint.zero, size: textLabel.attributedText!.sj_textSize())
                }
            }
        }
        
        centerAdapter.reload()
    }
    
    func updateBottomTimeLabelSize() {
        // 00:00
        // 00:00:00
        let ms = "00:00";
        let hms = "00:00:00";
        let durationTimeStr = videoPlayer.string(forSeconds: Int(videoPlayer!.duration))
        let format = (durationTimeStr.count == ms.count) ? ms : hms
        let formatSize = textForTimeString(timeStr: format).sj_textSize()
        
        guard
            let currentTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_CurrentTime),
            let durationTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_DurationTime)
        else { return }
        
        currentTimeItem.size = formatSize.width
        durationTimeItem.size = formatSize.width
        bottomAdapter.reload()
    }
    
    func updateBottomCurrentTimeItemIfNeeded() {
        if sj_view_isDisappeared(bottomContainerView) { return }
        
        let currentTimeStr = videoPlayer.string(forSeconds: Int(videoPlayer!.currentTime))
        let currentTimeItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_CurrentTime)
        if currentTimeItem != nil && !currentTimeItem!.isHidden {
            currentTimeItem?.title = textForTimeString(timeStr: currentTimeStr)
            bottomAdapter.updateContentForItem(withTag: SJEdgeControlLayerBottomItem_CurrentTime)
        }
    }
    
    func updateBottomDurationItemIfNeeded() {
        let durationTimeItem = bottomAdapter.item(forTag:SJEdgeControlLayerBottomItem_DurationTime)
        if durationTimeItem != nil && !durationTimeItem!.isHidden {
            durationTimeItem?.title = textForTimeString(timeStr: videoPlayer.string(forSeconds: Int(videoPlayer!.duration)))
            bottomAdapter.updateContentForItem(withTag: SJEdgeControlLayerBottomItem_DurationTime)
        }
    }
    
    func updateNetworkSpeedStrForLoadingView() {
        if videoPlayer == nil || !self.loadingView.isAnimating { return }
        
        if isShowNetworkSpeedToLoadingView && videoPlayer.assetURL != nil && !videoPlayer.assetURL!.isFileURL {
            self.loadingView.networkSpeedStr = NSAttributedString.sj_UIKitText({ (make) in
                let settings = SJEdgeControlLayerSettings.common()
                _ = make.font(settings.loadingNetworkSpeedTextFont)
                _ = make.textColor(settings.loadingNetworkSpeedTextColor)
                _ = make.alignment(.center)
                _ = make.append(self.videoPlayer.reachability.networkSpeedStr)
            })
        } else { loadingView.networkSpeedStr = nil }
    }
    
    func updateBottomProgressSliderItemIfNeeded() {
        if !sj_view_isDisappeared(bottomContainerView) {
            let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)?.customView ?? getFullScreenSlider()
//            let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)
            if let slider = progressItem as? SJProgressSlider {
                slider.maxValue = CGFloat(videoPlayer.duration)
                if !slider.isDragging { slider.value = CGFloat(videoPlayer.currentTime) }
                slider.bufferProgress = CGFloat(videoPlayer.playableDuration) / slider.maxValue
            }
        }
    }
    
    func updateBottomProgressIndicatorIfNeeded() {
        if !sj_view_isDisappeared(bottomProgressIndicator) {
            bottomProgressIndicator.value = CGFloat(videoPlayer.currentTime)
            bottomProgressIndicator.maxValue = CGFloat(videoPlayer.duration)
        }
    }
    
    func updateDraggingProgressViewCurrentTimeIfNeeded() {
        if !sj_view_isDisappeared(draggingProgressView) { draggingProgressView.setCurrentTime(videoPlayer.currentTime) }
    }
    
    func updateBottomAdapterIfNeeded() {
        if sj_view_isDisappeared(bottomContainerView) { return }
        
        let sources = SJEdgeControlLayerSettings.common()
        
        // play item
        if let playItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Play) {
            if !playItem.isHidden {
                let isPaused = videoPlayer.timeControlStatus == SJPlaybackTimeControlStatus.paused
                playItem.image = isPaused ? sources.playBtnImage : sources.pauseBtnImage
            }
        }
        
        // progress item
        if let progressItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_Progress)?.customView ?? getFullScreenSlider() {
            if !progressItem.isHidden {
                if let slider = progressItem as? SJProgressSlider {
                    slider.traceImageView.backgroundColor = sources.progress_traceColor
                    slider.trackImageView.backgroundColor = sources.progress_trackColor
                    slider.bufferProgressColor = sources.progress_bufferColor
                    slider.trackHeight = CGFloat(sources.progress_traceHeight)
                    slider.loadingColor = sources.loadingLineColor
                    
                    //                    if sources.progress_thumbImage != nil { slider.thumbImageView.image = sources.progress_thumbImage }
                    //                    else if !sources.progress_thumbSize.isNaN {
                    //                        slider.setThumbCornerRadius(1, size: CGSize(width: 16, height: 14), thumbBackgroundColor: sources.progress_thumbColor!)
                    //                    }
                }
            }
        }
        
        // full item
//        if let fullItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_FullBtn) {
//            if !fullItem.isHidden {
//                let isFullscreen = videoPlayer.isFullScreen
//                let isFitOnScreen = videoPlayer.isFitOnScreen
//                fullItem.image = (isFullscreen || isFitOnScreen) ? sources.shrinkscreenImage : sources.fullBtnImage
//            }
//        }
        
        // live text
        if let liveItem = bottomAdapter.item(forTag: SJEdgeControlLayerBottomItem_LIVEText) {
            if !liveItem.isHidden {
                liveItem.title = NSAttributedString.sj_UIKitText({ (make) in
                    _ = make.append(sources.liveText)
                    _ = make.font(sources.titleFont)
                    _ = make.textColor(sources.titleColor)
                    _ = make.shadow({ (make) in
                        make.shadowOffset = CGSize(width: 0, height: 0.5)
                        make.shadowColor = UIColor.black
                    })
                })
            }
        }
        
        // danmaku switch
        if let danmakuSwitch = bottomAdapter.item(forTag: kDanmakuSwitchTag) {
            danmakuSwitch.image = isDanmakuEnable ? UIImage(named: "danmakuSwitchOn", in: imageBunde, compatibleWith: nil) : UIImage(named: "danmakuSwitchOff", in: imageBunde, compatibleWith: nil)
        }
        
        // danmaku setting
        if let danmakuSetting = bottomAdapter.item(forTag: kDanmakuSettingTag) {
            if !isDanmakuEnable { danmakuSetting.isHidden = true }
            else { danmakuSetting.isHidden = false }
        }
        
        // danmaku input
        if let danmakuInput = bottomAdapter.item(forTag: kDanmakuInputTag) {
            if !isDanmakuEnable { danmakuInput.isHidden = true }
            else { danmakuInput.isHidden = false }
        }
        
        // rate item
        if let rate = bottomAdapter.item(forTag: kRateTag) {
            if videoPlayer.rate == 1.0 {
                rate.title = NSAttributedString.sj_UIKitText({ (make) in
                    _ = make.append("倍速")
                    _ = make.font(.systemFont(ofSize: 16))
                    _ = make.alignment(.center)
                    _ = make.textColor(.white)
                })
            } else {
                rate.title = NSAttributedString.sj_UIKitText({ (make) in
                    _ = make.append("\(self.videoPlayer.rate)X")
                    _ = make.font(.systemFont(ofSize: 16))
                    _ = make.alignment(.center)
                    _ = make.textColor(.white)
                })
            }
        }
        
        // definition item
        if let definition = bottomAdapter.item(forTag: kDefinitionTag) {
            if videoPlayer.urlAsset != nil && videoPlayer.urlAsset!.definition_lastName != nil {
                definition.title = NSAttributedString.sj_UIKitText({ (make) in
                    _ = make.append(self.videoPlayer.urlAsset!.definition_lastName!)
                    _ = make.font(.systemFont(ofSize: 16))
                    _ = make.alignment(.center)
                    _ = make.textColor(.white)
                })
            }
        }
        
        // next video item
        if let next = bottomAdapter.item(forTag: kNextVideoTag) {
//            if currentPlayIndex >= playListCount - 1 { next.image?.withTintColor(.gray, renderingMode: .alwaysOriginal) }
//            else { next.image?.withTintColor(.white, renderingMode: .alwaysOriginal) }
        }
        
        bottomAdapter.reload()
    }
    
    func updateContainerViewsAppearState() {
        updateTopContainerViewAppearState()
        updateLeftContainerViewAppearState()
        updateBottomContainerViewAppearState()
        updateRightContainerViewAppearState()
        updateCenterContainerViewAppearState()
    }
    
    func updateResidentBackButtonAppearStateIfNeeded() {
        if !isShowResidentBackButton { return }
        
        let placeholderItem = topAdapter.item(forTag: SJEdgeControlLayerTopItem_PlaceholderBack)
        let isFitOnScreen = videoPlayer.isFitOnScreen
        let isFull = videoPlayer.isFullScreen
        let isLockedScreen = videoPlayer.isLockedScreen
        if isLockedScreen { residentBackButton.isHidden = true }
        else {
            let isPlayOnScrollView = videoPlayer.isPlayOnScrollView
            residentBackButton.isHidden = isPlayOnScrollView && !isFitOnScreen && !isFull
            placeholderItem?.isHidden = isPlayOnScrollView && !isFitOnScreen && !isFull
        }
    }
    
    func updateTopContainerViewAppearState() {
        if 0 == topAdapter.itemCount {
            sj_view_makeDisappear(topContainerView, true)
            return
        }
        
        /// 锁屏状态下, 使隐藏
        if videoPlayer.isLockedScreen {
            sj_view_makeDisappear(topContainerView, true)
            return
        }
        
        /// 是否显示
        if videoPlayer.isControlLayerAppeared {
            sj_view_makeAppear(topContainerView, true)
        } else {
            sj_view_makeDisappear(topContainerView, true)
        }
    }
    
    func updateLeftContainerViewAppearState() {
        if 0 == leftAdapter.itemCount {
            sj_view_makeDisappear(leftContainerView, true)
            return
        }
        
        /// 锁屏状态下显示
        if videoPlayer.isLockedScreen {
            sj_view_makeAppear(leftContainerView, true)
            return
        }
        
        /// 是否显示
        if videoPlayer.isControlLayerAppeared {
            sj_view_makeAppear(leftContainerView, true)
        } else {
            sj_view_makeDisappear(leftContainerView, true)
        }
    }
    
    func updateBottomContainerViewAppearState() {
        if 0 == bottomAdapter.itemCount {
            sj_view_makeDisappear(bottomContainerView, true)
            return
        }
        
        /// 锁屏状态下, 使隐藏
        if videoPlayer.isLockedScreen {
            sj_view_makeDisappear(bottomContainerView, true)
            sj_view_makeAppear(bottomProgressIndicator, true)
            return
        }
        
        /// 是否显示
        if videoPlayer.isControlLayerAppeared {
            sj_view_makeAppear(bottomContainerView, true)
            sj_view_makeDisappear(bottomProgressIndicator, true)
        } else {
            sj_view_makeDisappear(bottomContainerView, true)
            sj_view_makeAppear(bottomProgressIndicator, true)
        }
    }
    
    func updateRightContainerViewAppearState() {
        if 0 == rightAdapter.itemCount {
            sj_view_makeDisappear(rightContainerView, true)
            return
        }
        
        /// 锁屏状态下, 使隐藏
        if videoPlayer.isLockedScreen {
            sj_view_makeDisappear(rightContainerView, true)
            return
        }
        
        /// 是否显示
        if videoPlayer.isControlLayerAppeared {
            sj_view_makeAppear(rightContainerView, true)
        } else {
            sj_view_makeDisappear(rightContainerView, true)
        }
    }
    
    func updateCenterContainerViewAppearState() {
        if 0 == centerAdapter.itemCount {
            sj_view_makeDisappear(centerContainerView, true)
            return
        }
        
        sj_view_makeAppear(centerContainerView, true)
    }
}

// MARK: - selector method
extension AriaVideoControlLayer {
    @objc func tappedTest() {
        print("test action tapped...")
    }
    
    public func backItemWasTapped(for controlLayer: SJControlLayer) {
        guard let delegate = self.delegate else { return }
        if delegate.responds(to: #selector(SJEdgeControlLayerDelegate.backItemWasTapped(for:))) {
            delegate.backItemWasTapped(for: self)
        }
    }
    
    @objc func tappedBackItem() {
        if videoPlayer.isFullScreen && !whetherToSupportOnlyOneOrientation() { videoPlayer.rotate() }
        else if videoPlayer.isFitOnScreen { videoPlayer.isFitOnScreen = false }
        else {
            if let vc = UIViewController.topViewController() {
                vc.view.endEditing(true)
                if (vc.presentingViewController != nil) { vc.dismiss(animated: true, completion: nil) }
                else { vc.navigationController?.popViewController(animated: true) }
            }
        }
    }
    
    func whetherToSupportOnlyOneOrientation() -> Bool {
        if videoPlayer.rotationManager.autorotationSupportedOrientations == SJOrientationMaskPortrait { return true }
        if videoPlayer.rotationManager.autorotationSupportedOrientations == SJOrientationMaskLandscapeLeft { return true }
        if videoPlayer.rotationManager.autorotationSupportedOrientations == SJOrientationMaskLandscapeRight { return true }
        return false
    }
    
    @objc func tappedLockItem() {
        videoPlayer.isLockedScreen = !videoPlayer.isLockedScreen
    }
    
    @objc func tappedReplayItem() {
        videoPlayer.replay()
    }
    
    @objc func tappedFullItem() {
        videoPlayer.useFitOnScreenAndDisableRotation ? videoPlayer.isFitOnScreen = !videoPlayer.isFitOnScreen : videoPlayer.rotate()
    }
    
    @objc func tappedPlayItem() {
        videoPlayer.timeControlStatus == SJPlaybackTimeControlStatus.paused ? videoPlayer.play() : videoPlayer.pause()
    }
    
    @objc func tappedDanmakuSwitchItem() {
        isDanmakuEnable = !isDanmakuEnable
    }
    
    @objc func tappedRateItem() {
        videoPlayer.popPromptController.clear()
        videoPlayer.switcher.switchControlLayer(forIdentitfier: rateControlLayerTag)
    }
    
    @objc func tappedDefinitionItem() {
        videoPlayer.popPromptController.clear()
        if videoPlayer.urlAsset!.definition_fullName == nil || videoPlayer.urlAsset!.definition_lastName == nil {
            videoPlayer.urlAsset!.definition_fullName = "自动 (标清)"
            videoPlayer.urlAsset!.definition_lastName = "自动"
        }
        if videoPlayer.definitionURLAssets == nil { videoPlayer.definitionURLAssets = [videoPlayer.urlAsset!] }
        if videoPlayer.defaultSwitchVideoDefinitionControlLayer.assets == nil { videoPlayer.defaultSwitchVideoDefinitionControlLayer.assets = [videoPlayer.urlAsset!] }
        videoPlayer.switcher.switchControlLayer(forIdentitfier: SJControlLayer_SwitchVideoDefinition)
    }
    
    @objc func tappedDanmakuInputItem() {
        videoPlayer.popPromptController.clear()
        videoPlayer.switcher.switchControlLayer(forIdentitfier: danmakuControlLayerTag)
    }
    
    @objc func tappedDanmakuSettingItem() {
        videoPlayer.popPromptController.clear()
        videoPlayer.switcher.switchControlLayer(forIdentitfier: danmakuSettingControlLayerTag)
    }
    
    @objc func tappedSelectionItem() {
        videoPlayer.popPromptController.clear()
        videoPlayer.switcher.switchControlLayer(forIdentitfier: selectionControlLayerTag)
    }
    
    @objc func tappedNextItem() {
        if currentPlayIndex + 1 < playListCount {
            currentPlayIndex += 1
            selectionControlLayer.currentPlayIndex = currentPlayIndex
            videoPlayer.barrageQueueController.removeAll()
            playTheIndexBlock?(currentPlayIndex)
        } else {
            videoPlayer.prompt.show(NSAttributedString.sj_UIKitText({ (make) in
                _ = make.append("已经是最后一集了")
                _ = make.textColor(.white)
            }), duration: 3)
        }
    }
    
    @objc func tappedShareItem() {
        if let exeBlock = shareBlock { exeBlock() }
    }
    
    @objc func tappedMoreItem() {
        videoPlayer.popPromptController.clear()
        if videoPlayer.isFullScreen { videoPlayer.switcher.switchControlLayer(forIdentitfier: landscapeMoreSettingControlLayerTag) }
        else {
            videoPlayer.prompt.show(NSAttributedString.sj_UIKitText({ (make) in
                _ = make.append("功能开发中")
                _ = make.textColor(.white)
            }), duration: 3)
        }
    }
}

// MARK: - util method
extension AriaVideoControlLayer {
    func getFullScreenSlider() -> UIView? {
        for subview in bottomContainerView.subviews {
            if subview.tag == kFullScreenSliderTag { return subview }
        }
        return nil
    }
    
    func textForTimeString(timeStr: String) -> NSAttributedString {
        return NSAttributedString.sj_UIKitText { (make) in
            _ = make.append(timeStr).font(UIFont.systemFont(ofSize: 11)).textColor(.white).alignment(.center)
        }
    }
    
    func showOrHiddenLoadingView() {
        if videoPlayer == nil || videoPlayer.urlAsset == nil {
            loadingView.stop()
            return
        }

        if videoPlayer.assetStatus == .preparing { loadingView.start() }
        else if videoPlayer.assetStatus == .failed { loadingView.stop() }
        else if videoPlayer.assetStatus == .readyToPlay { videoPlayer.reasonForWaitingToPlay == SJWaitingToMinimizeStallsReason ? loadingView.start() : loadingView.stop() }
    }
    
    @objc func resetControlLayerAppearIntervalForItemIfNeeded(note: Notification) {
        if let item = note.object as? SJEdgeControlButtonItem {
            if topAdapter.contains(item) {
                if item.tag == SJEdgeControlLayerTopItem_Back { return }
            }
            
            if bottomAdapter.contains(item) {
                if item.tag == SJEdgeControlLayerBottomItem_FullBtn { return }
            }
            
            if topAdapter.contains(item) ||
                leftAdapter.contains(item) ||
                bottomAdapter.contains(item) ||
                rightAdapter.contains(item) ||
                centerAdapter.contains(item) {
                videoPlayer.controlLayerNeedAppear() // 此处为重置控制层的隐藏间隔.(如果点击到当前控制层上的item, 则重置控制层的隐藏间隔)
            }
        }
    }
    
    func showOrRemoveBottomProgressIndicator() {
        if isHiddenBottomProgressIndicator || videoPlayer.playbackType == SJPlaybackTypeLIVE {
            bottomProgressIndicator.removeFromSuperview()
            //                bottomProgressIndicator = nil;
        } else {
            controlView()?.addSubview(bottomProgressIndicator)
            bottomProgressIndicator.snp.makeConstraints { (make) in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(bottomProgressIndicatorHeight)
            }
            updateBottomContainerViewAppearState()
        }
    }
    
    func onDragStart() {
        if videoPlayer.isFullScreen ||
             !videoPlayer.playbackController.isReadyForDisplay ||
            videoPlayer.urlAsset!.isM3u8 ||
            !videoPlayer.playbackController.responds(to: #selector(SJMediaPlaybackScreenshotController.screenshot(withTime:size:completion:))) {
            draggingProgressView.style = SJVideoPlayerDraggingProgressViewStyle.arrowProgress
        } else { self.draggingProgressView.style = SJVideoPlayerDraggingProgressViewStyle.previewProgress }
        
        controlView().addSubview(draggingProgressView)
        draggingProgressView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        sj_view_initializes(draggingProgressView)
        sj_view_makeAppear(draggingProgressView, false)
        
        draggingProgressView.setMaxValue(videoPlayer.duration)
        draggingProgressView.setProgressTimeStr(
            videoPlayer.string(forSeconds: Int(videoPlayer!.currentTime)),
            totalTimeStr: videoPlayer.string(forSeconds: Int(videoPlayer!.duration))
        )
    }
    
    func onDragMoving(progressTime: TimeInterval) {
        draggingProgressView.progressTime = progressTime
        draggingProgressView.setProgressTimeStr(videoPlayer.string(forSeconds: Int(progressTime)))
        
        // 生成预览图
        if draggingProgressView.style == SJVideoPlayerDraggingProgressViewStyle.previewProgress {
            videoPlayer.screenshot(withTime: progressTime, size: CGSize(width: draggingProgressView.frame.size.width * 2, height: draggingProgressView.frame.size.height * 2)) { [weak self] (videoPlayer, image, error) in
                guard let strongSelf = self else { return }
                if let img = image { strongSelf.draggingProgressView.setPreviewImage(img) }
            }
        }
    }
    
    func onDragMoveEnd() {
        videoPlayer.seek(toTime: draggingProgressView.progressTime, completionHandler: nil)

        sj_view_makeDisappear(draggingProgressView, true) {
            if sj_view_isDisappeared(self.draggingProgressView) { self.draggingProgressView.removeFromSuperview() }
        }
    }
}
