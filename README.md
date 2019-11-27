# AriaVideoControlLayer
SJVideoPlayer控制层扩展
# Requirements
- iOS 11.0
- Swift 5.0
# Installation
```
pod 'AriaVideoControlLayer'
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