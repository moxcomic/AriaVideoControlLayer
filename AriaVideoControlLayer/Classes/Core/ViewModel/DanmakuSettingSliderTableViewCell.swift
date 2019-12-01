//
//  DanmakuSettingSliderTableViewCell.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/20.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import Then
import SnapKit
import SJVideoPlayer

class DanmakuSettingSliderTableViewCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var model: [String: Any]! {
        didSet {
            if let value = model["key"] as? String {
                infoLabel.text = value
                if value == "字体大小" { slider.maxValue = 2.0 }
            }
            if let value = model["value"] as? CGFloat { slider.value = value }
        }
    }
    
    fileprivate lazy var infoLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 14)
    }
    
    fileprivate lazy var slider = SJProgressSlider().then {
        let sources = SJEdgeControlLayerSettings.common()
        $0.traceImageView.backgroundColor = sources.progress_traceColor
        $0.trackImageView.backgroundColor = sources.progress_trackColor
        $0.bufferProgressColor = sources.progress_bufferColor
        $0.trackHeight = CGFloat(sources.progress_traceHeight)
        $0.loadingColor = sources.loadingLineColor
        $0.thumbImageView.image = UIImage(named: "ieSlider", in: imageBunde, compatibleWith: nil)
        $0.thumbImageView.contentMode = .scaleToFill
        $0.setThumbCornerRadius(0, size: CGSize(width: 16, height: 14), thumbBackgroundColor: .clear)
        $0.trackHeight = 2
        $0.delegate = self
        $0.tap.isEnabled = true
        $0.enableBufferProgress = true
        $0.tappedExeBlock = { [weak self] (slider, location) in
            
        }
    }
    
    fileprivate lazy var percentageLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 14)
    }
}

extension DanmakuSettingSliderTableViewCell {
    fileprivate func setupView() {
        contentView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(5)
        }
        
        contentView.addSubview(percentageLabel)
        percentageLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-5)
            make.width.equalTo(38)
        }
        
        contentView.addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.left.equalTo(infoLabel.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.equalTo(percentageLabel.snp.left).offset(-10)
            make.height.equalTo(20)
        }
    }
}

extension DanmakuSettingSliderTableViewCell: SJProgressSliderDelegate {
    func sliderWillBeginDragging(_ slider: SJProgressSlider) {
        
    }
    
    func slider(_ slider: SJProgressSlider, valueDidChange value: CGFloat) {
        percentageLabel.text = "\(Int(value / 1.0 * 100))%"
    }
    
    func sliderDidEndDragging(_ slider: SJProgressSlider) {
        if let value = model["key"] as? String {
            var setting = AriaSettingsUtil.getDanmakuSettings()
            if value == "不透明度" { setting[0][0]["value"] = slider.value }
            if value == "字体大小" { setting[0][1]["value"] = slider.value }
            AriaSettingsUtil.setDanmakuSetting(value: setting)
        }
    }
}
