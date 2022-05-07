//
//  WhitePlayerViewController.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/2.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import "WhitePlayerViewController.h"
#import "CommandHandler.h"
#import "WhiteSDK.h"
#import "WhiteUtils.h"
#import "PlayerCommandListController.h"
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

@interface WhitePlayerViewController ()<WhiteCommonCallbackDelegate, WhitePlayerEventDelegate, WhiteCombineDelegate, UIPopoverPresentationControllerDelegate>
@property (nonatomic, nullable, strong) WhitePlayer *player;
@property (nonatomic, nullable, strong) WhiteCombinePlayer *combinePlayer;
@property (nonatomic, nullable, copy) NSString *roomToken;
@property (nonatomic, nullable, strong) WhiteVideoView *videoView;
@property (nonatomic, nullable, copy) NSURL *nativePlayerURL;
@end

#import "Masonry.h"
//#import <Masonry/Masonry.h>

@implementation WhitePlayerViewController

- (instancetype)init {
    if (self = [super init]) {
        //        [NSURL URLWithString:@"https://netless-media.oss-cn-hangzhou.aliyuncs.com/c447a98ece45696f09c7fc88f649c082_3002a61acef14e4aa1b0154f734a991d.m3u8"]
        _nativePlayerURL = [NSURL URLWithString:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/oceans.mp4"];
    }
    return self;
}

- (instancetype)initWithNativeURL:(NSURL *)nativeURL {
    if (self = [super init]) {
        self.nativePlayerURL = nativeURL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"设置", nil) style:UIBarButtonItemStylePlain target:self action:@selector(settingAPI:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"初始化", nil) style:UIBarButtonItemStylePlain target:self action:@selector(initPlayer)];
    [self addVideoView];
    [self getRoomToken];
    self.navigationItem.rightBarButtonItems = @[item1, item2];
}

- (void)addVideoView
{
    self.videoView = [[WhiteVideoView alloc] init];
    // 展示用的 m3u8 有 3 秒黑屏，显示黑色时，就是加载成功
    self.videoView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.videoView];
    
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.height.equalTo(@144);
        make.width.equalTo(self.videoView.mas_height).multipliedBy(16.0/9.0);
    }];
    
    [self.boardView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.left.equalTo(self.videoView.mas_right);
        make.right.equalTo(self.view);
        make.height.equalTo(self.boardView.mas_width).multipliedBy(9.0 / 16.0);
    }];
}

- (void)alert:(NSString *)title message:(NSString *)message
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (WhitePlayerConfig *)playerConfig
{
    if (!_playerConfig) {
        _playerConfig = [[WhitePlayerConfig alloc] initWithRoom:self.roomUuid roomToken:self.roomToken];
        _playerConfig.region = WhiteRegionCN;
    }
    return _playerConfig;
}

- (void)getRoomToken;
{
    __weak typeof(self)weakSelf = self;
    [WhiteUtils getRoomTokenWithUuid:self.roomUuid completionHandler:^(NSString * _Nullable roomToken, NSError * _Nullable error) {
        if (roomToken) {
            weakSelf.roomToken = roomToken;
            [weakSelf initPlayer];
        } else {
            [weakSelf alert:NSLocalizedString(@"获取 RoomToken 失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]]];
        }
    }];
}

- (void)initPlayer
{
    if (self.nativePlayerURL) {
        //音视频，白板混合播放处理类
        self.combinePlayer = [[WhiteCombinePlayer alloc] initWithMediaUrl: self.nativePlayerURL];
        //显示 AVPlayer 画面
        [self.videoView setAVPlayer:self.combinePlayer.nativePlayer];
        if (!self.ignoreWhitePlayer) {
            [self initWhiteCombinePlayer];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.playBlock) {
                    self.playBlock(self.combinePlayer, nil);
                }
            });
        }
    } else {
        [self initWhiteCombinePlayer];
    }
    //配置代理
    self.combinePlayer.delegate = self;
}

- (void)initWhiteCombinePlayer
{
    __weak typeof(self)weakSelf = self;
    [self.sdk createReplayerWithConfig:self.playerConfig callbacks:self.eventDelegate completionHandler:^(BOOL success, WhitePlayer * _Nonnull player, NSError * _Nonnull error) {
        if (error) {
            [weakSelf alert:NSLocalizedString(@"回放失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]]];
        } else {
            weakSelf.player = player;
            [weakSelf.player addMagixEventListener:WhiteCommandCustomEvent];
            [weakSelf.player addHighFrequencyEventListener:@"a" fireInterval:1000];
            
            if (weakSelf.combinePlayer) {
                //配置 WhitePlayer
                weakSelf.combinePlayer.whitePlayer = player;
            } else {
                weakSelf.combinePlayer = [[WhiteCombinePlayer alloc] initWithWhitePlayer:player];
            }
            //WhitePlayer 需要先手动 seek 到 0 才会触发缓冲行为
            [player seekToScheduleTime:0];
            
            if (weakSelf.playBlock) {
                weakSelf.playBlock(weakSelf.combinePlayer, error);
            }
            [weakSelf setupExampleControl];
        }
    }];
}

- (void)setupExampleControl {
    NSMutableArray *items = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [[CommandHandler generateCommandsForCombineReplay:self.combinePlayer] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, void (^ _Nonnull obj)(WhiteCombinePlayer * _Nonnull), BOOL * _Nonnull stop) {
        ExampleItem* item = [[ExampleItem alloc] initWithTitle:key status:nil enable:YES clickBlock:^(ExampleItem * _Nonnull i) {
            obj(weakSelf.combinePlayer);
        }];
        [items addObject:item];
    }];
    self.controlView.items = items;
}

#pragma mark -

- (void)settingAPI:(id)sender
{
    PlayerCommandListController *controller = [[PlayerCommandListController alloc] initWithPlayer:self.combinePlayer];
    [self showPopoverViewController:controller sourceView:sender];
}

#pragma mark - CallbackDelegate

- (id<WhitePlayerEventDelegate>)eventDelegate
{
    if (!_eventDelegate) {
        _eventDelegate = self;
    }
    return _eventDelegate;
}

#pragma mark - WhiteCombinePlayerDelegate


- (void)combinePlayerStartBuffering
{
    //任意一端进入缓冲
    NSLog(@"combinePlayerStartBuffering");
}

- (void)combinePlayerEndBuffering
{
    //两端都结束缓冲
    NSLog(@"combinePlayerEndBuffering");
}

- (void)nativePlayerDidFinish
{
    //可能音视频和白板时长不同
}

- (void)combineVideoPlayStateChange:(BOOL)isPlaying
{
    
}

- (void)combinePlayerError:(NSError *)error
{
    
}

- (void)loadedTimeRangeChange:(NSArray<NSValue *> *)loadedTimeRanges
{
    
}


#pragma mark - WhitePlayerEventDelegate

- (void)phaseChanged:(WhitePlayerPhase)phase
{
    NSLog(@"player %s %ld", __FUNCTION__, (long)phase);
    [self.combinePlayer updateWhitePlayerPhase:phase];
}

- (void)loadFirstFrame
{
    NSLog(@"player %s", __FUNCTION__);
}

- (void)sliceChanged:(NSString *)slice
{
    NSLog(@"player %s slice:%@", __FUNCTION__, slice);
}

- (void)playerStateChanged:(WhitePlayerState *)modifyState
{
    NSString *str = [modifyState jsonString];
    NSLog(@"player %s state:%@", __FUNCTION__, str);
}

- (void)stoppedWithError:(NSError *)error
{
    NSLog(@"player %s error:%@", __FUNCTION__, error);
}

- (void)scheduleTimeChanged:(NSTimeInterval)time
{
    NSLog(@"player %s time:%f", __FUNCTION__, (double)time);
}

- (void)fireMagixEvent:(WhiteEvent *)event;
{
    NSLog(@"%s", __func__);
}

- (void)fireHighFrequencyEvent:(NSArray<WhiteEvent *>*)events;
{
    NSLog(@"%s %@", __func__, events);
}

#pragma mark - WhiteCommonCallback

- (void)throwError:(NSError *)error
{
    NSLog(@"throwError: %@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url
{
    return @"https://white-pan-cn.oss-cn-hangzhou.aliyuncs.com/124/image/image.png";
}

@end
