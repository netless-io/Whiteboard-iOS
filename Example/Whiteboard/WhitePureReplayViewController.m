//
//  WhitePureReplayViewController.m
//  Whiteboard_Example
//
//  Created by yleaf on 2020/3/22.
//  Copyright © 2020 leavesster. All rights reserved.
//

#import "WhitePureReplayViewController.h"
#import "WhiteSDK.h"
#import "WhiteUtils.h"
#import "CommandHandler.h"
#import "PlayerCommandListController.h"
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

@interface WhitePureReplayViewController ()<WhiteCommonCallbackDelegate, WhitePlayerEventDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, nullable, strong) WhitePlayer *player;
@property (nonatomic, nullable, strong) NSString *roomToken;

@end

@implementation WhitePureReplayViewController

- (void)dealloc {
    NSLog(@"");
}

- (void)viewDidAppear:(BOOL)animated
{
    // 断点在这里可以打开safari调试
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"设置", nil) style:UIBarButtonItemStylePlain target:self action:@selector(settingAPI:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"初始化", nil) style:UIBarButtonItemStylePlain target:self action:@selector(initPlayer)];
    [self getRoomToken];
    self.navigationItem.rightBarButtonItems = @[item1, item2];
}

- (WhitePlayerConfig *)playerConfig
{
    if (!_playerConfig) {
        _playerConfig = [[WhitePlayerConfig alloc] initWithRoom:self.roomUuid roomToken:self.roomToken];
//        _playerConfig.mediaURL = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/oceans.mp4";
    }
    return _playerConfig;
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
    __weak typeof(self)weakSelf = self;
    [self.sdk createReplayerWithConfig:self.playerConfig callbacks:self.eventDelegate completionHandler:^(BOOL success, WhitePlayer * _Nonnull player, NSError * _Nonnull error) {
        if (weakSelf.playBlock) {
            weakSelf.playBlock(player, error);
        } else if (error) {
            [weakSelf alert:NSLocalizedString(@"回放失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]]];
        } else {
            weakSelf.player = player;
            [weakSelf.player addMagixEventListener:WhiteCommandCustomEvent];
            [weakSelf.player addHighFrequencyEventListener:@"a" fireInterval:1000];
             [player seekToScheduleTime:0];
        }
        [weakSelf setupExampleControl];
    }];
}

- (void)setupExampleControl {
    NSMutableArray *items = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [[CommandHandler generateCommandsForReplay:self.player] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, void (^ _Nonnull obj)(WhitePlayer * _Nonnull), BOOL * _Nonnull stop) {
        ExampleItem* item = [[ExampleItem alloc] initWithTitle:key status:nil enable:YES clickBlock:^(ExampleItem * _Nonnull i) {
            obj(weakSelf.player);
        }];
        [items addObject:item];
    }];
    self.controlView.items = items;
}

#pragma mark -

- (void)settingAPI:(id)sender
{
    if (self.player != nil) {
        PlayerCommandListController *controller = [[PlayerCommandListController alloc] initWithWhitePlayer:self.player];
        [self showPopoverViewController:controller sourceView:sender];
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"数据未初始化", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"确认", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertVC addAction:doneAction];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

#pragma mark - CallbackDelegate

- (id<WhitePlayerEventDelegate>)eventDelegate
{
    if (!_eventDelegate) {
        _eventDelegate = self;
    }
    return _eventDelegate;
}

#pragma mark - WhitePlayerEventDelegate

- (void)phaseChanged:(WhitePlayerPhase)phase
{
    NSLog(@"player %s %ld", __FUNCTION__, (long)phase);
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
