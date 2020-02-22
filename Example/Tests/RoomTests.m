//
//  WhiteSDKTests.m
//  WhiteSDKTests
//
//  Created by leavesster on 08/12/2018.
//  Copyright (c) 2018 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"

typedef void(^InterrupterBlock)(NSString *url);

@interface RoomTests : XCTestCase<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate>
@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoom *room;
@property (nonatomic, copy) InterrupterBlock interrupterBlock;
@end


@implementation RoomTests
#pragma mark - Test
- (void)setUp
{
    [super setUp];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    __weak typeof(self)weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom *room, NSError *error) {
        typeof(weakSelf)self = weakSelf;
        weakSelf.room = room;
        XCTAssertEqual(weakSelf.roomVC.isWritable, room.isWritable);
        XCTAssertNotNil(room);
        [exp fulfill];
    };

    [self pushRoomVC];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}


- (void)tearDown
{
    
    if (self.room.phase == WhiteRoomPhaseDisconnected) {
        [self popToRoot];
        [super tearDown];
        return;
    }
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room disconnect:^{
        [self popToRoot];
        [exp fulfill];
        [super tearDown];
    }];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - Prepare

- (void)pushRoomVC {
    //Webview 在视图栈中才能正确执行 js
    __unused UIView *view = [self.roomVC view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.roomVC animated:YES];
    }
}

- (void)popToRoot {
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
   if ([nav isKindOfClass:[UINavigationController class]]) {
       [nav popToRootViewControllerAnimated:YES];
   }
}

- (WhiteRoomViewController *)roomVC {
    if (!_roomVC) {
        _roomVC = [[WhiteRoomViewController alloc] initWithSdkConfig:[self testingConfig]];
        _roomVC.roomCallbackDelegate = self;
        _roomVC.commonDelegate = self;
    }
    return _roomVC;
}

- (WhiteSdkConfiguration *)testingConfig;
{
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    
    //为了测试图片 拦截 API，开启
    config.enableInterrupterAPI = YES;
    config.debug = YES;
    
    //打开用户头像显示信息
    config.userCursor = YES;
    return config;
}

#pragma mark - Consts

static NSString * const kTestingCustomEventName = @"WhiteCommandCustomEvent";
static NSTimeInterval kTimeout = 30;
#define CustomEventPayload @{@"test": @"1234"}

#pragma mark - setting

- (void)testSetMemberState
{
    WhiteMemberState *mState = [[WhiteMemberState alloc] init];
    mState.currentApplianceName = ApplianceRectangle;
    mState.strokeColor = @[@12, @24, @36];
    [self.room setMemberState:mState];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getMemberStateWithResult:^(WhiteMemberState *state) {
        XCTAssertTrue([state isKindOfClass:[WhiteMemberState class]]);
        XCTAssertTrue([state.currentApplianceName isEqualToString:mState.currentApplianceName]);
        for (NSInteger i=0; i < [state.strokeColor count]; i++) {
            XCTAssertTrue([mState.strokeColor[i] isEqualToNumber:state.strokeColor[i]]);
        }
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSetBroadcaster
{
    //单个用户无法成为观众，只能测试主播
    [self viewModeTest:WhiteViewModeBroadcaster];
}

- (void)testSetFreedom
{
    [self viewModeTest:WhiteViewModeFreedom];
}

- (void)viewModeTest:(WhiteViewMode)viewMode
{
    [self.room setViewMode:viewMode];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getBroadcastStateWithResult:^(WhiteBroadcastState *state) {
        XCTAssertTrue([state isKindOfClass:[WhiteBroadcastState class]]);
        XCTAssertTrue(state.viewMode == viewMode);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}


/**
 旧 API 兼容性测试。正常请使用新 API moveCamera:
 */
- (void)testZoomChange
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    CGFloat zoomScale = 5;
    
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [self.room zoomChange:0.5];
    [self.room zoomChange:zoomScale];
#pragma GCC diagnostic pop

    [self.room getZoomScaleWithResult:^(CGFloat scale) {
        XCTAssertTrue(scale == zoomScale);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testWritableFalseInit {
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    self.roomVC = nil;
    [self popToRoot];
    
    self.roomVC.isWritable = NO;
    __weak typeof(self)weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom *room, NSError *error) {
        typeof(weakSelf)self = weakSelf;
        weakSelf.room = room;
        XCTAssertNotNil(room);
        XCTAssertEqual(weakSelf.roomVC.isWritable, room.isWritable);
        [exp fulfill];
    };

    [self pushRoomVC];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];

}

- (void)testSetWritable {
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    __weak typeof(self)weakSelf = self;
    
    BOOL writable = NO;
    [self.room setWritable:writable completionHandler:^(BOOL isWritable, NSError * _Nullable error) {
        id self = weakSelf;
        XCTAssertEqual(writable, weakSelf.room.isWritable);
        XCTAssertEqual(writable, isWritable);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Camera

- (void)testCameraScale
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    CGFloat zoomScale = 5;
    
    WhiteCameraConfig *config = [[WhiteCameraConfig alloc] init];
    config.scale = @(zoomScale);
    config.animationMode = WhiteAnimationModeContinuous;
    
    [self.room moveCamera:config];
    
    [self.room getZoomScaleWithResult:^(CGFloat scale) {
        XCTAssertTrue(scale == zoomScale);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - disable API
- (void)testDisableOperations
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room disableOperations:YES];
    
    [self.roomVC.boardView evaluateJavaScript:@"room.disableOperations" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result boolValue]) {
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRestoreDisableOperations
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room disableOperations:YES];
    [self.room disableOperations:NO];

    [self.roomVC.boardView evaluateJavaScript:@"room.disableOperations" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (![result boolValue]) {
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}


- (void)testDisableDeviceInputs
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room disableDeviceInputs:YES];

    [self.roomVC.boardView evaluateJavaScript:@"room.disableDeviceInputs" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result boolValue]) {
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRestoreDisableDeviceInputs
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room disableDeviceInputs:YES];
    [self.room disableDeviceInputs:NO];

    [self.roomVC.boardView evaluateJavaScript:@"room.disableDeviceInputs" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (![result boolValue]) {
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testDisableCameraTransform
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room disableCameraTransform:YES];

    [self.roomVC.boardView evaluateJavaScript:@"room.disableCameraTransform" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if ([result boolValue]) {
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRestoreDisableCameraTransform
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room disableCameraTransform:YES];
    [self.room disableCameraTransform:NO];

    [self.roomVC.boardView evaluateJavaScript:@"room.disableCameraTransform" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (![result boolValue]) {
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Scene API

/**
 put and setScene
 */
- (void)testSceneAPI
{
    WhitePptPage *pptPage = [[WhitePptPage alloc] init];
    pptPage.src = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg";
    pptPage.width = 400;
    pptPage.height = 600;
    
    //因为这个场景目录，只插入了一页
    NSInteger index = 0;
    
    WhiteScene *scene = [[WhiteScene alloc] initWithName:@"opt" ppt:pptPage];
    [self.room putScenes:@"/ppt" scenes:@[scene] index:index];
    [self.room setScenePath:@"/ppt/opt"];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
        XCTAssertTrue([state.scenePath isEqualToString:@"/ppt/opt"]);
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [self.room getScenesWithResult:^(NSArray<WhiteScene *> * _Nonnull scenes) {
        XCTAssertTrue([scenes[index].ppt.src isEqualToString:pptPage.src]);
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [exp fulfill];
    });
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSetScenePathFail
{
    WhitePptPage *pptPage = [[WhitePptPage alloc] init];
    pptPage.src = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg";
    pptPage.width = 400;
    pptPage.height = 600;
    WhiteScene *scene = [[WhiteScene alloc] initWithName:@"opt" ppt:pptPage];
    [self.room putScenes:@"/ppt" scenes:@[scene] index:0];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    //传入错误的路径(正确路径应该以 "/" 开始)，获取错误回调
    [self.room setScenePath:@"ppt/opt" completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(@"setScenePath fail");
            [exp fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testCleanSceneNoPpt
{
    [self cleanScene:NO];
}

- (void)testCleanSceneRetainPpt
{
    [self cleanScene:YES];
}

- (void)cleanScene:(BOOL)retainPPT
{
    WhitePptPage *pptPage = [[WhitePptPage alloc] init];
    pptPage.src = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg";
    pptPage.width = 400;
    pptPage.height = 600;
    WhiteScene *scene = [[WhiteScene alloc] initWithName:@"opt" ppt:pptPage];
    [self.room putScenes:@"/ppt" scenes:@[scene] index:0];
    [self.room setScenePath:@"/ppt/opt"];
    
    [self.room cleanScene:retainPPT];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
        WhiteScene *current = state.scenes[state.index];
        if (retainPPT) {
            XCTAssertTrue([current.ppt.src isEqualToString:pptPage.src]);
            XCTAssertTrue(current.componentsCount == 1);
        } else {
            XCTAssertNil(current.ppt);
            XCTAssertTrue(current.componentsCount == 0);
        }
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Image

- (void)testScenesImages
{
    WhitePptPage *pptPage = [[WhitePptPage alloc] init];
    pptPage.src = @"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg";
    pptPage.width = 400;
    pptPage.height = 600;
    WhiteScene *scene = [[WhiteScene alloc] initWithName:@"opt" ppt:pptPage];
    [self.room putScenes:@"/ppt" scenes:@[scene] index:0];
    [self.room setScenePath:@"/ppt/opt"];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
        NSLog(@"SceneState: %@", [state jsonString]);
    }];
    
    [self.room getScenesWithResult:^(NSArray<WhiteScene *> * _Nonnull scenes) {
        XCTAssertTrue([[scenes lastObject].ppt.src isEqualToString:pptPage.src]);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testInsertImage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    WhiteImageInformation *info = [[WhiteImageInformation alloc] init];
    info.width = 200;
    info.height = 300;
    info.uuid = @"WhiteImageInformation";
    [self.room insertImage:info src:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg"];
    
    self.interrupterBlock = ^(NSString *url) {
        [exp fulfill];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Get

- (void)testGetRoomMember
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getRoomMembersWithResult:^(NSArray<WhiteRoomMember *> *roomMembers) {
        for (WhiteRoomMember *member in roomMembers) {
            XCTAssertTrue([member isKindOfClass:[WhiteRoomMember class]]);
            NSLog(@"%s %@", __FUNCTION__, [member jsonString]);
        }
        XCTAssertTrue([roomMembers count] == 1);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testGetRoomState
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
        if ([state isKindOfClass:[WhiteRoomState class]]) {
            [exp fulfill];
        } else {
            XCTFail(@"获取失败");
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - disconnect
- (void)testDisconnectCallback
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    [self.room disconnect:^{
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - WhiteRoomCallbackDelegate
- (void)firePhaseChanged:(WhiteRoomPhase)phase
{
    NSLog(@"%s, %ld", __func__, (long)phase);
}

- (void)fireRoomStateChanged:(WhiteRoomState *)magixPhase;
{
    NSLog(@"%s, %@", __func__, [magixPhase jsonString]);
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
    XCTAssertTrue([event.eventName isEqualToString:kTestingCustomEventName]);
    XCTAssertTrue([event.payload isEqualToDictionary:CustomEventPayload]);
    NSLog(@"fireMagixEvent: %@", [event jsonString]);
}

- (void)fireHighFrequencyEvent:(NSArray<WhiteEvent *>*)events
{
    XCTAssertNotNil(events);
    NSLog(@"fireHighFrequencyEvent: %lu", (unsigned long)[events count]);
}

#pragma mark - WhiteCommonCallbackDelegate
- (void)throwError:(NSError *)error
{
    NSLog(@"throwError: %@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url
{
    if (self.interrupterBlock) {
        self.interrupterBlock(url);
    }
    return url;
}

@end
