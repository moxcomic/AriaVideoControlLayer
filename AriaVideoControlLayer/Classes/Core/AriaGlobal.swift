//
//  AriaGlobal.swift
//  AriaVideoControlLayer
//
//  Created by 神崎H亚里亚 on 2019/11/28.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit

let imageBundlePath = Bundle.main.url(forResource: "Frameworks", withExtension: nil)!.appendingPathComponent("AriaVideoControlLayer.framework/Settings.bundle")

let imageBunde = Bundle(url: imageBundlePath)!

let biliPink = UIColor(red: 244 / 255, green: 89 / 255, blue: 136 / 255, alpha: 1)
let defaultGray = UIColor(red: 224 / 255, green: 224 / 255, blue: 224 / 255, alpha: 1)
let systemGray4 = UIColor(red: 0.8196078431372549, green: 0.8196078431372549, blue: 0.8392156862745098, alpha: 1.0)

let screenW = UIScreen.main.bounds.width
let screenH = UIScreen.main.bounds.height
