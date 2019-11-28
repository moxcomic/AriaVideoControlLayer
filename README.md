# AriaVideoControlLayer
SJVideoPlayer控制层扩展
# Requirements
- iOS 11.0
- Swift 5.0
# Installation
```
pod 'AriaSwiftyChain', :git => 'https://github.com/moxcomic/AriaSwiftyChain.git'
pod 'AriaVideoControlLayer', :git => 'https://github.com/moxcomic/AriaVideoControlLayer.git'
```
# Usage
## Swift
```
import AriaVideoControlLayer

player.switcher.addControlLayer(forIdentifier: LONG_MAX - 1) { (id) -> SJControlLayer in
    return AriaVideoControlLayer()
}
```
## OC
```
#import <AriaVideoControlLayer-Swift.h>

[_player.switcher addControlLayerForIdentifier:LONG_MAX - 1 lazyLoading:^id<SJControlLayer> _Nonnull(SJControlLayerIdentifier identifier) {
    return [AriaVideoControlLayer new];
}];
```
# ScreenShot
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S1.PNG)
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S2.PNG)
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S3.PNG)
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S4.PNG)
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S5.PNG)
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S6.PNG)
![image](https://raw.githubusercontent.com/moxcomic/AriaVideoControlLayer/master/ScreenShot/S7.PNG)