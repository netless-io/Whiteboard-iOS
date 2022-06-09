//
//  WhiteSDKTests.m
//  WhiteSDKTests
//
//  Created by leavesster on 08/12/2018.
//  Copyright (c) 2018 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

@interface CustomGlobalTestModel : WhiteGlobalState
@property (nonatomic, copy) NSString *name;
@end

@implementation CustomGlobalTestModel

@end

typedef void(^InterrupterBlock)(NSString *url);

@interface RoomTests : BaseRoomTest
@property (nonatomic, copy) InterrupterBlock interrupterBlock;
@end


@implementation RoomTests

#pragma mark - Consts
static NSString * const kTestingCustomEventName = @"WhiteCommandCustomEvent";
#define CustomEventPayload @{@"test": @"1234"}

- (void)roomConfigDidSetup:(WhiteRoomConfig *)config
{
    if ([self.name containsString:@"testWritableFalseInit"]) {
        config.isWritable = NO;
    }
}

#pragma mark - roomConfig
- (void)testNan
{
    NSNumber *r = self.roomConfig.windowParams.containerSizeRatio;
    self.roomConfig.windowParams.containerSizeRatio = @(1.0 / 0);
    XCTAssertTrue([r isEqualToNumber:self.roomConfig.windowParams.containerSizeRatio]);
    self.roomConfig.windowParams.containerSizeRatio = [NSDecimalNumber notANumber];
    XCTAssertTrue([r isEqualToNumber:self.roomConfig.windowParams.containerSizeRatio]);
}

#pragma mark - setting
- (void)testSetGlobalState
{
    [WhiteDisplayerState setCustomGlobalStateClass:[CustomGlobalTestModel class]];
    NSDictionary *dict = @{@"globalState": @{@"name": @"testName"}};
    WhiteDisplayerState *result = [WhiteDisplayerState modelWithJSON:dict];
    [self.room setGlobalState:result.globalState];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([self.room.globalState isKindOfClass:[CustomGlobalTestModel class]]);
        CustomGlobalTestModel *globalModel = (CustomGlobalTestModel *)self.room.globalState;
        XCTAssertTrue([globalModel.name isEqualToString:@"testName"]);
    });
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
        XCTAssertTrue([state.globalState isKindOfClass:[CustomGlobalTestModel class]]);
        CustomGlobalTestModel *globalModel = (CustomGlobalTestModel *)state.globalState;
        XCTAssertTrue([globalModel.name isEqualToString:@"testName"]);
        [exp fulfill];
    }];
    
    [self.room getGlobalStateWithResult:^(WhiteGlobalState * _Nonnull state) {
        XCTAssertTrue([state isKindOfClass:[CustomGlobalTestModel class]]);
        CustomGlobalTestModel *globalModel = (CustomGlobalTestModel *)state;
        XCTAssertTrue([globalModel.name isEqualToString:@"testName"]);
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSetMemberState
{
    WhiteMemberState *mState = [[WhiteMemberState alloc] init];
    mState.currentApplianceName = ApplianceRectangle;
    mState.strokeColor = @[@12, @24, @36];
    [self.room setMemberState:mState];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getMemberStateWithResult:^(WhiteMemberState *state) {
        XCTAssertTrue([state isKindOfClass:[WhiteMemberState class]], @"state is not a WhiteMemberState instance");
        XCTAssertTrue([state.currentApplianceName isEqualToString:mState.currentApplianceName], @"set appliance %@ but realy appliance is: %@", mState.currentApplianceName, state.currentApplianceName);
        for (NSInteger i=0; i < [state.strokeColor count]; i++) {
            XCTAssertTrue([mState.strokeColor[i] isEqualToNumber:state.strokeColor[i]], @"set color %@ but realy color is: %@", mState.strokeColor[i], state.strokeColor[i]);
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
        XCTAssertTrue(state.viewMode == viewMode, @"set viewMode as %ld but real is %ld", (long)viewMode, (long)viewMode);
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
    
    // 动画需要时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.room getZoomScaleWithResult:^(CGFloat scale) {
            XCTAssertTrue(scale == zoomScale);
            [exp fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testWritableFalseInit {
    XCTAssertEqual(self.roomConfig.isWritable, self.room.isWritable, @"roomVC writable is :%d room writbale is :%d", self.roomConfig.isWritable, self.room.isWritable);
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
    
    // 动画时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.room getZoomScaleWithResult:^(CGFloat scale) {
            XCTAssertTrue(scale == zoomScale, @"set scale is:%f realy scale is:%f", scale, zoomScale);
            [exp fulfill];
        }];
    });
    
    
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
    
    [self.roomVC.boardView evaluateJavaScript:@"room.disableDeviceInputs && room.disableCameraTransform" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
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

    [self.roomVC.boardView evaluateJavaScript:@"room.disableDeviceInputs && room.disableCameraTransform" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
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

- (void)testSceneTypePage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    [self.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
        [self.room getScenePathType:state.sceneState.scenePath result:^(WhiteScenePathType pathType) {
            XCTAssertEqual(pathType, WhiteScenePathTypePage);
            [exp fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSceneTypeDir
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    WhitePptPage *pptPage = [[WhitePptPage alloc] initWithSrc:@"https://example.com/1.png" size:CGSizeMake(600, 800)];
    WhiteScene *scene = [[WhiteScene alloc] initWithName:@"1" ppt:pptPage];
    [self.room putScenes:@"/ppt" scenes:@[scene] index:0];

    [self.room getScenePathType:@"/ppt" result:^(WhiteScenePathType pathType) {
        XCTAssertEqual(pathType, WhiteScenePathTypeDir);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSceneTypeEmpty
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room getScenePathType:@"/dadasijdisajdisaj/disajdiosajdiasjdoisa" result:^(WhiteScenePathType pathType) {
        XCTAssertEqual(pathType, WhiteScenePathTypeEmpty);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

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
    
    [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
        XCTAssertTrue([state.scenePath isEqualToString:@"/ppt/opt"]);
        //FIXME: sdk 覆盖插入时，index 没有发生修改
        XCTAssertTrue([state.scenes[state.index].ppt.src isEqualToString:pptPage.src]);
        [exp fulfill];
    }];

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
            WhiteScene *current = state.scenes[state.index];
            if (retainPPT) {
                XCTAssertTrue([current.ppt.src isEqualToString:pptPage.src]);
            } else {
                XCTAssertNil(current.ppt);
            }
            [exp fulfill];
        }];

    });
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testAddPage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    NSInteger oldLength = self.room.state.pageState.length;
    __weak typeof(self) weakSelf = self;
    [self.room addPage:^(BOOL success) {
        [weakSelf.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
            XCTAssertTrue(state.pageState.length == oldLength + 1);
            [exp fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRemovePage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSInteger oldLength = self.room.state.pageState.length;
    NSInteger oldIndex = self.room.state.pageState.index;
    __weak typeof(self) weakSelf = self;
    [self.room addPage:^(BOOL success) {
        [weakSelf.room removePage:oldIndex completionHandler:^(BOOL success) {
            [weakSelf.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
                XCTAssertTrue(state.pageState.length == oldLength);
                [exp fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:999 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRemoveCurrentPage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSInteger oldLength = self.room.state.pageState.length;

    __weak typeof(self) weakSelf = self;
    [self.room addPage:^(BOOL success) {
        [weakSelf.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
            [weakSelf.room removePage:^(BOOL success) {
                [weakSelf.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
                    XCTAssertTrue(state.pageState.length == oldLength);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRemoveLastPage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSInteger oldLength = self.room.state.pageState.length;
    XCTAssertTrue(oldLength > 0);
    
    [self loopToOnlyOnePage:^{
        [self.room removePage:0 completionHandler:^(BOOL success) {
            XCTAssertTrue(!success);
            [exp fulfill];
        }];
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
    
    [self.room getScenesWithResult:^(NSArray<WhiteScene *> * _Nonnull scenes) {
        XCTAssertTrue([[scenes firstObject].ppt.src isEqualToString:pptPage.src]);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

// 暂时移除该测试，待web-sdk修复后加回
//- (void)testInsertImage
//{
//    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
//    WhiteImageInformation *info = [[WhiteImageInformation alloc] initWithSize:CGSizeMake(200, 300)];
//    [self.room insertImage:info src:@"https://white-pan.oss-cn-shanghai.aliyuncs.com/101/image/alin-rusu-1239275-unsplash_opt.jpg"];
//    
//    self.interrupterBlock = ^(NSString *url) {
//        [exp fulfill];
//    };
//    
//    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"%s error: %@", __FUNCTION__, error);
//        }
//    }];
//}

#pragma mark - Get

- (void)testGetScene
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
        [self.room getSceneFromScenePath:state.sceneState.scenePath result:^(WhiteScene * _Nullable scene) {
            XCTAssertNotNil(scene);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testGetSceneFail
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getSceneFromScenePath:@"/initA" result:^(WhiteScene * _Nullable scene) {
        XCTAssertNil(scene);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testGetRoomMember
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    [TestUtility updateRoomWithUuid:WhiteRoomUUID ban:YES completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [TestUtility updateRoomWithUuid:WhiteRoomUUID ban:NO completionHandler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            
            [self popToRoot];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self pushRoomVC];
                
                [self.roomVC performSelector:NSSelectorFromString(@"joinExistRoom")];
                self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
                    [room getRoomMembersWithResult:^(NSArray<WhiteRoomMember *> *roomMembers) {
                        for (WhiteRoomMember *member in roomMembers) {
                            XCTAssertTrue([member isKindOfClass:[WhiteRoomMember class]]);
                            NSLog(@"%s %@", __FUNCTION__, [member jsonString]);
                        }
                        XCTAssertTrue([roomMembers count] == 1, @"room should be 1 people, but has %lu", (unsigned long)[roomMembers count]);
                        [exp fulfill];
                    }];
                };
            });
        }];
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
//    NSLog(@"%s, %ld", __func__, (long)phase);
}

- (void)fireRoomStateChanged:(WhiteRoomState *)magixPhase;
{
//    NSLog(@"%s, %@", __func__, [magixPhase jsonString]);
}

- (void)fireDisconnectWithError:(NSString *)error
{
//    NSLog(@"%s, %@", __func__, error);
    XCTFail(@"fireDisconnectWithError：%@", error);
}

- (void)fireKickedWithReason:(NSString *)reason
{
//    XCTFail(@"fireKickedWithReason：%@", reason);
//    NSLog(@"%s, %@", __func__, reason);
}

- (void)fireCatchErrorWhenAppendFrame:(NSUInteger)userId error:(NSString *)error
{
//    NSLog(@"%s, %lu %@", __func__, (unsigned long)userId, error);
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
    XCTFail(@"调用出现报错：%@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url
{
    if (self.interrupterBlock) {
        self.interrupterBlock(url);
    }
    return url;
}

#pragma - private
- (void)loopToOnlyOnePage:(void (^)(void))completionHandler
{
    [self.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
        if (state.pageState.length > 1) {
            [self.room removePage:^(BOOL success) {
                [self loopToOnlyOnePage:completionHandler];
            }];
        } else {
            completionHandler();
        }
    }];
}

@end
