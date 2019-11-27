//
//  AriaSettingsUtil.swift
//  AiliCili
//
//  Created by 神崎H亚里亚 on 2019/11/10.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit

class AriaSettingsUtil {
    static func getDanmakuSettings() -> [[[String: Any]]] {
        var value = UserDefaults.standard.array(forKey: "danmakuSetting")
        if value == nil {
            value =
            [
                [
                    [
                        "key": "不透明度",
                        "value": CGFloat(1.0)
                    ],
                    [
                        "key": "字体大小",
                        "value": CGFloat(1.0)
                    ]
                ]
            ]
            setDanmakuSetting(value: value as! [[[String : Any]]])
        }
        return value as! [[[String : Any]]]
    }
    
    static func setDanmakuSetting(value: [[[String: Any]]]) {
        UserDefaults.standard.setValue(value, forKey: "danmakuSetting")
        UserDefaults.standard.synchronize()
    }
}
