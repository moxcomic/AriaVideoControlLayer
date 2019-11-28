Pod::Spec.new do |s|
  s.name             = "AriaVideoControlLayer"
  s.version          = "0.0.3"
  s.summary          = "SJVideoPlayer控制层扩展."
  s.homepage         = "https://github.com/moxcomic/AriaVideoControlLayer.git"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "moxcomic" => "656469762@qq.com" }
  s.source           = { :git => "https://github.com/moxcomic/AriaVideoControlLayer.git", :tag => "#{s.version}" }
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.0"
  s.source_files = "AriaVideoControlLayer/Classes/**/*.swift"
  s.resource = 'AriaVideoControlLayer/Classes/Settings.bundle'
  
  s.frameworks = "UIKit", "Foundation"

  s.dependency "Then"
  s.dependency "SnapKit"
  s.dependency "RxSwift"
  s.dependency "RxDataSources"
  s.dependency "NSObject+Rx"
  s.dependency "RxDataSources"
  s.dependency "RxCocoa"
  s.dependency "SJVideoPlayer"
  s.dependency "SJUIKit"
  s.dependency "AriaSwiftyChain"
end