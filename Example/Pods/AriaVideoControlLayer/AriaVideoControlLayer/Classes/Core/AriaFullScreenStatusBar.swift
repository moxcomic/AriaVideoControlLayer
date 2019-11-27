//
//  AriaFullScreenStatusBar.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/14.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import SJVideoPlayer
import Then

class AriaFullScreenStatusBar: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 时间显示
    fileprivate lazy var timeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 13)
        $0.text = getTimeString()
    }
    
    /// 电池外框
    fileprivate lazy var batteryView = UIImageView().then {
        $0.image = UIImage(named: "battery")
        $0.contentMode = .scaleToFill
    }
    
    /// 剩余电量
    fileprivate lazy var batteryProgressView = UIView().then {
        $0.backgroundColor = .white
    }
    
    /// 网络状态
    fileprivate lazy var networkView = UIImageView().then {
        $0.image = UIImage(named: "wifi")
        $0.contentMode = .scaleToFill
    }
    
    fileprivate var timer: Timer!
}

extension AriaFullScreenStatusBar {
    /// 获取时间
    fileprivate func getTimeString() -> String {
        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
    
    fileprivate func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    /// 改变时间、网络状态图标、电池图标电量
    @objc fileprivate func refresh() {
        self.timeLabel.text = self.getTimeString()
        self.batteryProgressView.snp.makeConstraints { (make) in
            make.width.equalTo(18.5 * UIDevice.current.batteryLevel)
        }
        if UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full {
            self.batteryView.image = UIImage(named: "battery_charging")
            self.batteryProgressView.backgroundColor = .green
        } else {
            self.batteryView.image = UIImage(named: "battery")
            self.batteryProgressView.backgroundColor = .white
        }
        self.networkView.image =
        SJReachability.shared().networkStatus == SJNetworkStatus.reachableViaWiFi ?
            UIImage(named: "wifi") : UIImage(named: "cellular")
    }
}

extension AriaFullScreenStatusBar {
    fileprivate func setUI() {
        addSubview()
        setLayout()
        setControl()
    }
    
    fileprivate func addSubview() {
        addSubview(timeLabel)
        addSubview(batteryView)
        addSubview(batteryProgressView)
        addSubview(networkView)
    }
    
    fileprivate func setLayout() {
        frame = CGRect(x: 0, y: 0, width: screenH, height: 34)
        
        timeLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(16)
        }
        
        batteryView.snp.makeConstraints { (make) in
            make.centerY.equalTo(timeLabel)
            make.right.equalToSuperview().offset(-34)
            make.height.equalTo(12).priority(999)
            make.width.equalTo(22)
            //make.bottom.equalTo(timeLabel.snp.bottom)
        }
        
        batteryProgressView.snp.makeConstraints { (make) in
            make.top.equalTo(batteryView.snp.top).offset(1.8)
            make.left.equalTo(batteryView.snp.left).offset(1.4)
            make.bottom.equalTo(batteryView.snp.bottom).offset(-1.8)
            make.width.equalTo(18.5)
        }
        sendSubviewToBack(batteryProgressView)
        
        networkView.snp.makeConstraints { (make) in
            make.centerY.equalTo(timeLabel)
            make.right.equalTo(batteryView.snp.left).offset(-10)
            make.height.equalTo(12).priority(999)
            make.width.equalTo(28)
        }
    }
    
    fileprivate func setControl() {
        // 开启电池监控,否则获取不到电池电量
        UIDevice.current.isBatteryMonitoringEnabled = true
        // 默认隐藏,全屏状态时取消隐藏
        isHidden = true
        startTimer()
    }
}
