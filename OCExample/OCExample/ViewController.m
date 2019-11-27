//
//  ViewController.m
//  OCExample
//
//  Created by 神崎H亚里亚 on 2019/11/28.
//  Copyright © 2019 moxcomic. All rights reserved.
//

#import "ViewController.h"
#import <AriaVideoControlLayer-Swift.h>
#import <SJVideoPlayer/SJVideoPlayer.h>
#import <Masonry/Masonry.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (strong, nonatomic) SJVideoPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _player = [SJVideoPlayer new];
    [_player.switcher addControlLayerForIdentifier:LONG_MAX - 1 lazyLoading:^id<SJControlLayer> _Nonnull(SJControlLayerIdentifier identifier) {
        return [AriaVideoControlLayer new];
    }];
    
    [self.view addSubview:_player.view];
    [_player.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_playView);
    }];
    
    SJVideoPlayerURLAsset *asset = [[SJVideoPlayerURLAsset alloc] initWithURL:[NSURL URLWithString:@"https://youku.cdn7-okzy.com/20191128/15965_000b016f/index.m3u8"]];
    asset.title = @"仿B站控制层";
    _player.URLAsset = asset;
}


@end
