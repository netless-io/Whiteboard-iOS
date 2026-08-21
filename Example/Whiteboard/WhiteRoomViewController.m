//
//  WhiteViewController.m
//  WhiteSDK
//
//  Created by leavesster on 08/12/2018.
//  Copyright (c) 2018 leavesster. All rights reserved.
//

#import "WhiteRoomViewController.h"
#import "CommandHandler.h"
#import "WhiteRoomLifecycleGuard.h"

@interface WhiteRoomViewController ()<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, copy) NSString *roomToken;
@property (nonatomic, copy, nullable) RoomBlock roomBlock;
@property (nonatomic, strong, nullable) WhiteRoomConfig *roomConfig;
@property (nonatomic, copy, nullable) BeginJoinRoomBlock beginJoinRoomBlock;
@property (nonatomic, assign) BOOL delayJoinRoom;
@property (nonatomic, strong) WhiteRoomLifecycleGuard *lifecycleGuard;
@property (nonatomic, strong) UIView *roomLoadingOverlay;
@property (nonatomic, strong) UIActivityIndicatorView *roomLoadingIndicator;
@property (nonatomic, assign) BOOL handlingRecoveryJoin;
@property (nonatomic, assign) BOOL leavingRoom;

@end

#import "WhiteUtils.h"

@implementation WhiteRoomViewController

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
    [self setupRoomLoadingOverlay];
    [self setupRoomLifecycleGuard];

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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed || self.navigationController.isBeingDismissed) {
        [self leaveRoomWithCompletion:nil];
    }
}

- (void)dealloc
{
    [self.lifecycleGuard stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Room Lifecycle UI

- (void)setupRoomLoadingOverlay
{
    UIView *overlay = [[UIView alloc] init];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.backgroundColor = [UIColor colorWithWhite:1 alpha:0.88];
    overlay.hidden = YES;
    overlay.accessibilityIdentifier = @"room-reconnecting-overlay";
    overlay.accessibilityViewIsModal = YES;
    [self.view addSubview:overlay];

    UIActivityIndicatorView *indicator;
    if (@available(iOS 13.0, *)) {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    indicator.hidesWhenStopped = YES;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = NSLocalizedString(@"正在重新连接...", nil);
    label.textColor = [UIColor colorWithWhite:0.2 alpha:1];
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[indicator, label]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12;
    [overlay addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.boardView.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.boardView.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.boardView.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.boardView.bottomAnchor],
        [stack.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:overlay.leadingAnchor constant:24],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:overlay.trailingAnchor constant:-24],
    ]];

    self.roomLoadingOverlay = overlay;
    self.roomLoadingIndicator = indicator;
}

- (void)setupRoomLifecycleGuard
{
    WhiteRoomLifecycleGuard *guard = [[WhiteRoomLifecycleGuard alloc] init];
    __weak typeof(self) weakSelf = self;
    guard.loadingHandler = ^(BOOL visible) {
        [weakSelf setRoomLoadingVisible:visible];
    };
    guard.reconnectHandler = ^{
        [weakSelf replaceRoomAfterUnexpectedDisconnect];
    };
    self.lifecycleGuard = guard;
    [guard start];
}

- (void)setRoomLoadingVisible:(BOOL)visible
{
    void (^update)(void) = ^{
        self.roomLoadingOverlay.hidden = !visible;
        if (visible) {
            [self.roomLoadingIndicator startAnimating];
            [self.view bringSubviewToFront:self.roomLoadingOverlay];
        } else {
            [self.roomLoadingIndicator stopAnimating];
        }
    };
    if ([NSThread isMainThread]) {
        update();
    } else {
        dispatch_async(dispatch_get_main_queue(), update);
    }
}

- (BOOL)isRoomLoadingVisible
{
    return self.roomLoadingOverlay && !self.roomLoadingOverlay.hidden;
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
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"分享", nil) style:UIBarButtonItemStylePlain target:self action:@selector(shareRoom:)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"pre", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pptPreviousStep)];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pptNextStep)];
    
    self.navigationItem.rightBarButtonItems = @[item2, item3, item4];
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
    self.roomConfig.undoCacheScenesCount = @32;
    
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
    [self.lifecycleGuard rejoinDidSucceed];
    [self.room addMagixEventListener:WhiteCommandCustomEvent];
    [self setupShareBarItem];

    if (self.roomBlock && !self.handlingRecoveryJoin) {
        self.roomBlock(room, nil);
    }
}

- (void)defaultActionAfterJoinRoomError:(NSError *)error
{
    [self.lifecycleGuard stop];
    self.title = NSLocalizedString(@"加入失败", nil);
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"加入房间失败", nil) message:[NSString stringWithFormat:@"错误信息:%@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)leaveRoomWithCompletion:(dispatch_block_t)completion
{
    if (self.leavingRoom) {
        if (completion) {
            completion();
        }
        return;
    }

    self.leavingRoom = YES;
    [self.lifecycleGuard stop];
    WhiteRoom *room = self.room;
    self.room = nil;
    if (!room || room.disconnectedBySelf || room.phase == WhiteRoomPhaseDisconnected) {
        if (completion) {
            completion();
        }
        return;
    }
    [room disconnect:completion];
}

- (void)replaceRoomAfterUnexpectedDisconnect
{
    if (!self.lifecycleGuard.isActive || !self.sdk || !self.roomConfig || self.roomToken.length == 0) {
        [self.lifecycleGuard rejoinDidFail];
        return;
    }

    WhiteRoom *oldRoom = self.room;
    self.room = nil;
    __weak typeof(self) weakSelf = self;
    dispatch_block_t joinBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf performRecoveryJoin];
        });
    };

    if (oldRoom && !oldRoom.disconnectedBySelf && oldRoom.phase != WhiteRoomPhaseDisconnected) {
        [oldRoom disconnect:joinBlock];
    } else {
        joinBlock();
    }
}

- (void)performRecoveryJoin
{
    if (!self.lifecycleGuard.isActive) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.sdk joinRoomWithConfig:self.roomConfig callbacks:self.roomCallbackDelegate completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (!self.lifecycleGuard.isActive) {
                if (success) {
                    [room disconnect:nil];
                }
                return;
            }
            if (!success || !room) {
                NSLog(@"Room lifecycle recovery join failed: %@", error.localizedDescription);
                [self.lifecycleGuard rejoinDidFail];
                return;
            }

            self.handlingRecoveryJoin = YES;
            [self actionAfterSuccessJoinRoom:room roomToken:self.roomToken];
            self.handlingRecoveryJoin = NO;
            [self setupExampleControl];
            NSLog(@"Room lifecycle recovery joined successfully");
        });
    }];
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
    void (^handlePhase)(void) = ^{
        if (self.room.disconnectedBySelf && !self.lifecycleGuard.isRecovering) {
            [self.lifecycleGuard stop];
            return;
        }
        [self.lifecycleGuard handlePhase:phase];
    };
    if ([NSThread isMainThread]) {
        handlePhase();
    } else {
        dispatch_async(dispatch_get_main_queue(), handlePhase);
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
