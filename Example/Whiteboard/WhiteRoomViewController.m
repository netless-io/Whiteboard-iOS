//
//  WhiteViewController.m
//  WhiteSDK
//
//  Created by leavesster on 08/12/2018.
//  Copyright (c) 2018 leavesster. All rights reserved.
//

#import "WhiteRoomViewController.h"
#import "CommandHandler.h"

@interface WhiteBaseViewController (WhiteRoomViewControllerSDKAccess)
- (void)initSDK;
@end

@interface WhiteRoomViewController ()<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, copy) NSString *roomToken;
@property (nonatomic, assign, getter=isReconnecting) BOOL reconnecting;
@property (nonatomic, copy, nullable) RoomBlock roomBlock;
@property (nonatomic, strong, nullable) WhiteRoomConfig *roomConfig;
@property (nonatomic, copy, nullable) BeginJoinRoomBlock beginJoinRoomBlock;
@property (nonatomic, assign) BOOL delayJoinRoom;
@property (nonatomic, assign) BOOL embeddedPageRegistered;

@end

#import "WhiteUtils.h"

@implementation WhiteRoomViewController

static NSString * const WhiteEmbeddedPlyrPageURL = @"https://plyr-cdn.netless.group/index.html";
static NSString * const WhiteEmbeddedPlyrMediaURL = @"https://www.youtube.com/watch?v=bTqVqk7FSmY";
static NSString * const WhiteEmbeddedPageAppScriptURL = @"https://cdn.jsdelivr.net/npm/@netless/app-embedded-page@0.1.3/dist/main.iife.js";
static NSString * const WhiteEmbeddedPageAppVariable = @"NetlessAppEmbeddedPageForExample";

static NSString *WhiteEmbeddedPlyrAppIdentityURL(void) {
    NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"localhost";
    return [NSString stringWithFormat:@"https://%@", bundleId];
}

static WhiteRegisterAppParams *WhiteCreateEmbeddedPageRegisterParams(void) {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"embedPage.iife" ofType:@"js"];
    NSError *readError = nil;
    NSString *jsString = jsPath ? [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:&readError] : nil;
    if (jsString.length > 0) {
        jsString = [jsString stringByAppendingFormat:@"\nvar %@ = (typeof NetlessAppEmbeddedPage !== 'undefined' && (NetlessAppEmbeddedPage.default || NetlessAppEmbeddedPage));\n", WhiteEmbeddedPageAppVariable];
        return [WhiteRegisterAppParams paramsWithJavascriptString:jsString
                                                             kind:@"EmbeddedPage"
                                                       appOptions:@{}
                                                         variable:WhiteEmbeddedPageAppVariable];
    }
    NSLog(@"load local embedPage.iife.js failed: %@", readError);
    return [WhiteRegisterAppParams paramsWithUrl:WhiteEmbeddedPageAppScriptURL
                                            kind:@"EmbeddedPage"
                                      appOptions:@{}];
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor orangeColor];

    if (!self.delayJoinRoom) {
        if ([self.roomUuid length] > 0) {
            [self joinExistRoom];
        } else {
            [self joinNewRoom];
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDismiss:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"refresh" object:nil];
}

- (void)initSDK
{
    [super initSDK];
    if (self.useMultiViews) {
        [self registerEmbeddedPageAppIfNeeded];
    }
}

#pragma mark - CallbackDelegate
- (id<WhiteRoomCallbackDelegate>)roomCallbackDelegate
{
    if (!_roomCallbackDelegate) {
        _roomCallbackDelegate = self;
    }
    return _roomCallbackDelegate;
}

#pragma mark - Example Control
- (void)setupExampleControl {
    NSMutableArray *items = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [[CommandHandler generateCommandsForRoom:self.room roomToken:self.roomToken] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, void (^ _Nonnull obj)(WhiteRoom * _Nonnull), BOOL * _Nonnull stop) {
        ExampleItem* item = [[ExampleItem alloc] initWithTitle:key status:nil enable:YES clickBlock:^(ExampleItem * _Nonnull i) {
            obj(weakSelf.room);
        }];
        [items addObject:item];
    }];
    self.controlView.items = items;
}

#pragma mark - BarItem
- (void)setupShareBarItem
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    if (self.useMultiViews) {
        UIBarButtonItem *plyrItem = [[UIBarButtonItem alloc] initWithTitle:@"Plyr"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(addEmbeddedPlyr)];
        [items addObject:plyrItem];
    }
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"分享", nil) style:UIBarButtonItemStylePlain target:self action:@selector(shareRoom:)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"pre", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pptPreviousStep)];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pptNextStep)];
    [items addObjectsFromArray:@[item2, item3, item4]];
    self.navigationItem.rightBarButtonItems = items;
}

- (void)pptPreviousStep
{
    [self.room pptPreviousStep];
}

- (void)pptNextStep
{
    [self.room pptNextStep];
}

- (void)shareRoom:(id)sender
{
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.roomUuid ? :@""] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = [self.navigationItem.rightBarButtonItem valueForKey:@"view"];
    [self presentViewController:activityVC animated:YES completion:nil];
    NSLog(@"%@", [NSString stringWithFormat:NSLocalizedString(@"房间 UUID: %@", nil), self.roomUuid]);
}

- (void)refresh
{
    [self.room refreshViewSize];
}

- (void)registerEmbeddedPageAppIfNeeded
{
    if (self.embeddedPageRegistered || !self.sdk) {
        return;
    }
    self.embeddedPageRegistered = YES;

    WhiteRegisterAppParams *params = WhiteCreateEmbeddedPageRegisterParams();

    __weak typeof(self) weakSelf = self;
    [self.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        if (error) {
            weakSelf.embeddedPageRegistered = NO;
            NSLog(@"registerEmbeddedPageAppIfNeeded failed: %@", error);
        } else {
            NSLog(@"registerEmbeddedPageAppIfNeeded success");
        }
    }];
}

- (void)addEmbeddedPlyr
{
    NSString *title = @"Embedded Plyr";
    WhiteAppOptions *options = [[WhiteAppOptions alloc] init];
    options.title = title;

    WhiteAppParam *app = [[WhiteAppParam alloc] initWithKind:@"EmbeddedPage"
                                                     options:options
                                                       attrs:[self embeddedPlyrAttributesWithPageURL:WhiteEmbeddedPlyrPageURL
                                                                                            mediaURL:WhiteEmbeddedPlyrMediaURL
                                                                                               title:title]];

    [self.room addApp:app completionHandler:^(NSString * _Nonnull appId) {
        NSLog(@"Embedded Plyr app added from WhiteRoomViewController: %@", appId);
    }];
}

- (NSDictionary *)embeddedPlyrAttributesWithPageURL:(NSString *)pageURL
                                           mediaURL:(NSString *)mediaURL
                                              title:(NSString *)title
{
    return @{
        @"src": pageURL ?: @"",
        @"store": @{
            @"state": [self embeddedPlyrStateWithMediaURL:mediaURL title:title]
        }
    };
}

- (NSDictionary *)embeddedPlyrStateWithMediaURL:(NSString *)mediaURL title:(NSString *)title
{
    NSTimeInterval nowMs = [[NSDate date] timeIntervalSince1970] * 1000.0;
    NSMutableDictionary *state = [@{
        @"src": mediaURL ?: @"",
        @"type": [self embeddedPlyrTypeForMediaURL:mediaURL],
        @"poster": @"",
        @"paused": @YES,
        @"currentTime": @0,
        @"useNewPlayer": @YES,
        @"useCustomControls": @YES,
        @"volume": @1,
        @"muted": @NO,
        @"playTimeState": @[@YES, @((long long)nowMs), @((long long)nowMs)],
        @"syncVolume": @NO,
        @"syncMuted": @NO,
        @"customControlsTitle": title ?: @"Embedded Plyr",
        @"allowBackgroundPlayback": @YES,
        @"keepPlayerStateInSync": @YES
    } mutableCopy];

    NSString *provider = [self embeddedPlyrProviderForMediaURL:mediaURL];
    if (provider.length > 0) {
        state[@"provider"] = provider;
        state[@"type"] = @"";
        if ([provider isEqualToString:@"youtube"]) {
            NSString *appIdentityURL = WhiteEmbeddedPlyrAppIdentityURL();
            state[@"youtubeOrigin"] = appIdentityURL;
            state[@"youtubeWidgetReferrer"] = appIdentityURL;
        }
    }

    return state.copy;
}

- (nullable NSString *)embeddedPlyrProviderForMediaURL:(NSString *)mediaURL
{
    NSString *lowercased = mediaURL.lowercaseString;
    if ([lowercased containsString:@"youtube.com"] || [lowercased containsString:@"youtu.be"]) {
        return @"youtube";
    }
    if ([lowercased containsString:@"vimeo.com"]) {
        return @"vimeo";
    }
    return nil;
}

- (NSString *)embeddedPlyrTypeForMediaURL:(NSString *)mediaURL
{
    NSString *sanitized = [[mediaURL componentsSeparatedByString:@"?"] firstObject] ?: mediaURL;
    NSString *lowercased = sanitized.lowercaseString;
    if ([lowercased hasSuffix:@".mp4"]) return @"video/mp4";
    if ([lowercased hasSuffix:@".mp3"]) return @"audio/mpeg";
    if ([lowercased hasSuffix:@".m4a"]) return @"audio/mp4";
    if ([lowercased hasSuffix:@".webm"]) return @"video/webm";
    if ([lowercased hasSuffix:@".wav"]) return @"audio/wav";
    if ([lowercased hasSuffix:@".m3u8"]) return @"application/vnd.apple.mpegurl";
    return @"";
}

#pragma mark - Room Action

/**
 创建房间：
    1. 调用创建房间API，服务器会同时返回了该房间的 roomToken；
    2. 通过 roomToken 进行加入房间操作。
 */
- (void)joinNewRoom
{
    self.title = NSLocalizedString(@"创建房间中...", nil);
    [WhiteUtils createRoomWithCompletionHandler:^(NSString * _Nullable uuid, NSString * _Nullable roomToken, NSError * _Nullable error) {
        if (error) {
            if (self.roomBlock) {
                self.roomBlock(nil, error);
            } else {
                NSLog(NSLocalizedString(@"创建房间失败，error:", nil), [error description]);
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
- (void)joinExistRoom
{
    self.title = NSLocalizedString(@"加入房间中...", nil);
    [WhiteUtils getRoomTokenWithUuid:self.roomUuid completionHandler:^(NSString * _Nullable roomToken, NSError * _Nullable error) {
        if (roomToken) {
            self.roomToken = roomToken;
             [self joinRoomWithToken:roomToken];
         } else {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"获取 RoomToken 失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error description]] preferredStyle:UIAlertControllerStyleAlert];
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
    
    if (!self.roomConfig) {
        NSDictionary *payload = @{@"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg"};
        WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUUID:self.roomUuid roomToken:roomToken uid:@"1" userPayload:payload];
        // 配置，橡皮擦是否能删除图片。默认为 NO，能够删除图片。
//         roomConfig.disableEraseImage = YES;
        // 设置最大最小缩放比例，不设置成 0，会导致画面极小时，出现一些问题。默认不是 0
        WhiteCameraBound *bound = [WhiteCameraBound defaultMinContentModeScale:0 maxContentModeScale:10];
        roomConfig.cameraBound = bound;
        roomConfig.region = WhiteRegionCN;
        if (@available(iOS 13.0, *)) {
            // 将 web端的 webSocket 转成从 native 发起
            // roomConfig.nativeWebSocket = YES;
        }

        self.roomConfig = roomConfig;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.sdk joinRoomWithConfig:self.roomConfig callbacks:self.roomCallbackDelegate completionHandler:^(BOOL success, WhiteRoom * _Nonnull room, NSError * _Nonnull error) {
        if (success) {
            [weakSelf actionAfterSuccessJoinRoom:room roomToken:roomToken];
        } else if (weakSelf.roomBlock) {
            weakSelf.roomBlock(nil, error);
        } else {
            [weakSelf defaultActionAfterJoinRoomError:error];
        }
        [weakSelf setupExampleControl];
    }];
    if (self.beginJoinRoomBlock) { self.beginJoinRoomBlock(); };
}

- (void)actionAfterSuccessJoinRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken
{
    self.title = NSLocalizedString(@"我的白板", nil);
    self.roomToken = roomToken;
    self.room = room;
    [self.room addMagixEventListener:WhiteCommandCustomEvent];
    [self setupShareBarItem];

    if (self.roomBlock) {
        self.roomBlock(room, nil);
    }
}

- (void)defaultActionAfterJoinRoomError:(NSError *)error
{
    self.title = NSLocalizedString(@"加入失败", nil);
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"加入房间失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Keyboard

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
    if (self.room.disconnectedBySelf || self.isReconnecting || !self.sdk) {
        return;
    }
    
    if (phase == WhiteRoomPhaseDisconnected && self.roomUuid && self.roomToken) {
        self.reconnecting = YES;
        [self.sdk joinRoomWithConfig:self.roomConfig callbacks:self completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
            self.reconnecting = NO;
            NSLog(@"reconnected");
            if (error) {
                NSLog(@"error:%@", [error description]);
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

- (void)fireCanUndoStepsUpdate:(NSInteger)canUndoSteps {
    NSLog(@"%s, %ld", __func__, (long)canUndoSteps);
}

- (void)fireCanRedoStepsUpdate:(NSInteger)canRedoSteps {
    NSLog(@"%s, %ld", __func__, (long)canRedoSteps);
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
