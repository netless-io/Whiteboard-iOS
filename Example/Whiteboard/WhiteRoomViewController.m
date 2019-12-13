//
//  WhiteViewController.m
//  WhiteSDK
//
//  Created by leavesster on 08/12/2018.
//  Copyright (c) 2018 leavesster. All rights reserved.
//

#import "WhiteRoomViewController.h"

@interface WhiteRoomViewController ()<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, copy) NSString *roomToken;
@property (nonatomic, assign, getter=isReconnecting) BOOL reconnecting;

@end

#import <Masonry/Masonry.h>
#import "RoomCommandListController.h"
#import "WhiteUtils.h"

@implementation WhiteRoomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    # warning 请在 WhiteBaseViewController 中查看 SDK 初始化代码，以及注意事项。
    NSString *sdkToken = [WhiteUtils sdkToken];
    self.view.backgroundColor = [UIColor orangeColor];
    
    if ([sdkToken length] == 0) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"sdk token 不合法", nil) message:NSLocalizedString(@"请在 https://console.herewhite.com 注册并申请 Token，并在 WhiteUtils sdkToken 方法中，填入 SDKToken 进行测试", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertVC addAction:action];
        [self presentViewController:alertVC animated:YES completion:nil];
    } else if ([self.roomUuid length] > 0) {
        [self joinRoom];
    } else {
        [self createRoom];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDismiss:) name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark - CallbackDelegate
- (id<WhiteRoomCallbackDelegate>)roomCallbackDelegate
{
    if (!_roomCallbackDelegate) {
        _roomCallbackDelegate = self;
    }
    return _roomCallbackDelegate;
}

#pragma mark - BarItem
- (void)setupShareBarItem
{
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"设置 API", nil) style:UIBarButtonItemStylePlain target:self action:@selector(settingAPI:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"分享", nil) style:UIBarButtonItemStylePlain target:self action:@selector(shareRoom:)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"pre", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pptPreviousStep)];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pptNextStep)];
    
    self.navigationItem.rightBarButtonItems = @[item1, item2, item3, item4];
}

- (void)pptPreviousStep
{
    [self.room pptPreviousStep];
}

- (void)pptNextStep
{
    [self.room pptNextStep];
}

- (void)settingAPI:(id)sender
{
    RoomCommandListController *controller = [[RoomCommandListController alloc] initWithRoom:self.room];
    controller.roomToken = self.roomToken;
    [self showPopoverViewController:controller sourceView:sender];
}

- (void)shareRoom:(id)sender
{
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.roomUuid ? :@""] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = [self.navigationItem.rightBarButtonItem valueForKey:@"view"];
    [self presentViewController:activityVC animated:YES completion:nil];
    NSLog(@"%@", [NSString stringWithFormat:NSLocalizedString(@"房间 UUID: %@", nil), self.roomUuid]);
}

#pragma mark - Room Action

/**
 创建房间：
    1. 调用创建房间API，服务器会同时返回了该房间的 roomToken；
    2. 通过 roomToken 进行加入房间操作。
 */
- (void)createRoom
{
    self.title = NSLocalizedString(@"创建房间中...", nil);
    [WhiteUtils createRoomWithCompletionHandler:^(NSString * _Nullable uuid, NSString * _Nullable roomToken, NSError * _Nullable error) {
        if (error) {
            if (self.roomBlock) {
                self.roomBlock(nil, error);
            } else {
                NSLog(NSLocalizedString(@"创建房间失败，error:", nil), [error localizedDescription]);
                self.title = NSLocalizedString(@"创建失败", nil);
            }
        } else {
            self.roomUuid = uuid;
            if (self.roomUuid && roomToken) {
                [self joinRoomWithToken:roomToken];
            } else {
                NSLog(NSLocalizedString(@"连接房间失败，room uuid:%@ roomToken:%@", nil), self.roomUuid, roomToken);
                self.title = NSLocalizedString(@"创建失败", nil);
            }
        }
    }];
}

/**
 已有 room uuid，加入房间
 1. 与服务器通信，获取该房间的 room token
 2. 通过 roomToken 进行加入房间操作。
 */
- (void)joinRoom
{
//    NSString *copyPast = [UIPasteboard generalPasteboard].string;
//    if ([copyPast length] == 32 && !self.roomUuid) {
//        NSLog(@"%@", [NSString stringWithFormat:NSLocalizedString(@"粘贴板 UUID：%@", nil), copyPast]);
//        self.roomUuid = copyPast;
//    }
    self.title = NSLocalizedString(@"加入房间中...", nil);
    [WhiteUtils getRoomTokenWithUuid:self.roomUuid Result:^(BOOL success, id response, NSError *error) {
        if (success) {
            NSString *roomToken = response[@"msg"][@"roomToken"];
            [self joinRoomWithToken:roomToken];
        } else {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"加入房间失败", nil) message:[NSString stringWithFormat:@"服务器信息:%@，系统错误信息:%@", [error localizedDescription], [response description]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [alertVC addAction:action];
            [self presentViewController:alertVC animated:YES completion:nil];
        }
    }];
}

- (void)joinRoomWithToken:(NSString *)roomToken
{
    self.title = NSLocalizedString(@"正在连接房间", nil);
    
    NSDictionary *payload = @{@"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg"};
    WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUuid:self.roomUuid roomToken:roomToken userPayload:payload];
//    roomConfig.disableEraseImage = YES;
    [self.sdk joinRoomWithConfig:roomConfig callbacks:self.roomCallbackDelegate completionHandler:^(BOOL success, WhiteRoom * _Nonnull room, NSError * _Nonnull error) {
        if (success) {
            self.title = NSLocalizedString(@"我的白板", nil);

            self.roomToken = roomToken;
            self.room = room;
            [self.room addMagixEventListener:WhiteCommandCustomEvent];
            [self setupShareBarItem];
            
            if (self.roomBlock) {
                self.roomBlock(self.room, nil);
            }
        } else if (self.roomBlock) {
            self.roomBlock(nil, error);
        } else {
            self.title = NSLocalizedString(@"加入失败", nil);
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"加入房间失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [alertVC addAction:action];
            [self presentViewController:alertVC animated:YES completion:nil];
        }
    }];
}

#pragma mark - Keyboard

- (void)setRectangle {
    [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
        if (state.scenes) {
            WhitePptPage *ppt = state.scenes[state.index].ppt;
            WhiteRectangleConfig *rectangle = [[WhiteRectangleConfig alloc] initWithInitialPosition:ppt.width height:ppt.height];
            [self.room moveCameraToContainer:rectangle];
        }
    }];
}

/**
 处理文字教具键盘隐藏时，内容偏移。
 可以
 @param n 键盘通知
 */
- (void)keyboardDidDismiss:(NSNotification *)n
{
    [self.boardView.scrollView setContentOffset:CGPointZero animated:YES];
}

#pragma mark - WhiteRoomCallbackDelegate
- (void)firePhaseChanged:(WhiteRoomPhase)phase
{
    NSLog(@"%s, %ld", __FUNCTION__, (long)phase);
    if (phase == WhiteRoomPhaseDisconnected && self.sdk && !self.isReconnecting) {
        self.reconnecting = YES;
        [self.sdk joinRoomWithUuid:self.roomUuid roomToken:self.roomToken completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
            self.reconnecting = NO;
            NSLog(@"reconnected");
            if (error) {
                NSLog(@"error:%@", [error localizedDescription]);
            } else {
                self.room = room;
            }
        }];
    }
}

- (void)fireRoomStateChanged:(WhiteRoomState *)magixPhase;
{
    NSLog(@"%s, %@", __func__, [magixPhase jsonString]);
}

- (void)fireBeingAbleToCommitChange:(BOOL)isAbleToCommit
{
    NSLog(@"%s, %d", __func__, isAbleToCommit);
}

- (void)fireDisconnectWithError:(NSString *)error
{
    NSLog(@"%s, %@", __func__, error);
}

- (void)fireKickedWithReason:(NSString *)reason
{
    NSLog(@"%s, %@", __func__, reason);
}

- (void)fireCatchErrorWhenAppendFrame:(NSUInteger)userId error:(NSString *)error
{
    NSLog(@"%s, %lu %@", __func__, (unsigned long)userId, error);
}

- (void)fireMagixEvent:(WhiteEvent *)event
{
    NSLog(@"fireMagixEvent: %@", [event jsonString]);
}

- (void)fireHighFrequencyEvent:(NSArray<WhiteEvent *>*)events
{
    NSLog(@"%s", __func__);
}

@end
