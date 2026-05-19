//
//  MultiViewsRoomTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/25.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

typedef void(^WhiteSceneStateBlock)(WhiteSceneState *state);

static WhiteAppParam* _Nonnull testMp4AppParam;
static WhiteAppParam* _Nonnull testPptAppParam;

@interface MultiViewsRoomTest : BaseRoomTest <WhiteSlideDelegate>
@property (nonatomic, assign) BOOL didCallSlideInterrupter;
@property (nonatomic, assign) BOOL didCallSlideError;
@property (nonatomic, assign) NSInteger slideErrorIndex;
@property (nonatomic, assign) BOOL didCallSlidePageStateChanged;
@property (nonatomic, copy, nullable) NSString *slidePageStateAppId;
@property (nonatomic, assign) NSInteger slidePageStatePage;
@property (nonatomic, assign) NSInteger slidePageStatePageCount;
@property (nonatomic, copy, nullable) NSString *expectedWindowBoxState;
@property (nonatomic, copy, nullable) void (^windowBoxStateChangeBlock)(WhiteRoomState *state);
@property (nonatomic, copy, nullable) NSString *expectedSlideAppId;
@property (nonatomic, copy, nullable) NSString *expectedSlideTitle;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, WhiteAppSyncAttributes *> *slideAppsBeforeAdd;
@end

@implementation MultiViewsRoomTest
{
    WhiteSceneStateBlock _stateChangeBlock;
}

+ (void)load
{
    testMp4AppParam = [WhiteAppParam
                       createMediaPlayerApp:@"https://convertcdn.netless.link/1.mp4"
                       title:@"testApp"];
    
    testPptAppParam = [WhiteAppParam createSlideApp:@"/ppt" taskId:@"7f5d2864e82b4f0e9c868f348e922453" url:@"https://convertcdn.netless.link/dynamicConvert" title:@"example_ppt"];
}

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig {
    sdkConfig.useMultiViews = YES;
    
    if ([self.name containsString:@"testSlideUrlInterrupt"]) {
        sdkConfig.enableSlideInterrupterAPI = YES;
        return;
    }
    if ([self.name isEqualToString:@"testApiHostError"]) {
        self.assertJoinRoomError = YES;
        sdkConfig.apiHosts = @[@"t.t.com"];
    }
    if ([self.name isEqualToString:@"testApiHostEmpty"]) {
        self.assertJoinRoomError = YES;
        sdkConfig.apiHosts = @[];
    }
    if ([self.name isEqualToString:@"testApiHostSuccess"]) {
        sdkConfig.apiHosts = @[@"api.baiban.shengwang.cn"];
    }
}

- (void)roomConfigDidSetup:(WhiteRoomConfig *)config {
    if ([self.name isEqualToString:@"testModulesOrigin"]) {
        config.modulesOrigin = @"https://sdk.herewhite.com";
    }
}

- (void)testApiHostError { return; }
- (void)testApiHostEmpty { return; }
- (void)testApiHostSuccess { return; }
- (void)testModulesOrigin { return; }

- (void)testSlideOptionsDefault
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    [self.roomVC.sdk.bridge evaluateJavaScript:@"manager.__proto__.constructor.registered.get('Slide').appOptions.showRenderError" completionHandler:^(NSNumber *renderError, NSError * _Nullable error) {
        [self.roomVC.sdk.bridge evaluateJavaScript:@"manager.__proto__.constructor.registered.get('Slide').appOptions.debug" completionHandler:^(NSNumber *debug, NSError * _Nullable error1) {
            XCTAssertTrue((![renderError boolValue] && ![debug boolValue]));
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSlideUrlInterrupt
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.roomVC.sdk setSlideDelegate:self];
    WhiteAppParam* slide = [WhiteAppParam createSlideApp:@"/test_interrupter" taskId:@"0c17d99a3cfa41dc85a9b9a379d18912" url:@"https://white-us-doc-convert.s3.us-west-1.amazonaws.com/dynamicConvert" title:@"test_interrupter"];
    self.didCallSlideInterrupter = NO;
    __weak typeof(self.room) weakRoom = self.room;
    __weak typeof(self) weakSelf = self;
    [self.roomVC.room addApp:slide completionHandler:^(NSString * _Nonnull appId) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            XCTAssertTrue(weakSelf.didCallSlideInterrupter);
            [weakRoom closeApp:appId completionHandler:^{
                [exp fulfill];
            }];
        });
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSlideError
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.roomVC.sdk setSlideDelegate:self];
    WhiteAppParam* slide = [WhiteAppParam createSlideApp:@"/test_error" taskId:@"1bef9ed799aa40078dafbd2a3feb2c25" url:@"https://white-cover.oss-cn-hangzhou.aliyuncs.com/flat/dynamicConvert" title:@"test_error"];
    self.didCallSlideError = NO;
    __weak typeof(self.room) weakRoom = self.room;
    __weak typeof(self) weakSelf = self;
    [self.roomVC.room addApp:slide completionHandler:^(NSString * _Nonnull appId) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            XCTAssertTrue(weakSelf.didCallSlideError);
            [weakRoom closeApp:appId completionHandler:^{
                [exp fulfill];
            }];
        });
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testNonIndexSlideError
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.roomVC.sdk setSlideDelegate:self];
    // 测试非数字类型
    NSDictionary *invalidDict = @{
        @"type": @"@slide/_error_",
        @"errorType": @"loadError",
        @"errorMsg": @"Failed to load slide",
        @"slideId": @"slide1",
        @"slideIndex": @"invalid"
    };
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue(weakSelf.didCallSlideError);
        XCTAssertEqual(weakSelf.slideErrorIndex, -1);
        [exp fulfill];
    });
    NSData *data = [NSJSONSerialization dataWithJSONObject:invalidDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *invalidJson = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    SEL sel = NSSelectorFromString(@"postMessage:");
    [self.roomVC.boardView.commonCallbacks performSelector:sel withObject:invalidJson];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSlidePageStateChangedCallback
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.roomVC.sdk setSlideDelegate:self];
    self.didCallSlidePageStateChanged = NO;
    NSString *appId = @"Slide-test";
    NSDictionary *pageState = @{
        @"appId": appId,
        @"page": @2,
        @"pageCount": @12
    };

    SEL sel = NSSelectorFromString(@"slidePageStateChanged:");
    [self.roomVC.boardView.commonCallbacks performSelector:sel withObject:pageState];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue(self.didCallSlidePageStateChanged);
        XCTAssertEqualObjects(self.slidePageStateAppId, appId);
        XCTAssertEqual(self.slidePageStatePage, 2);
        XCTAssertEqual(self.slidePageStatePageCount, 12);
        [exp fulfill];
    });

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testPptLocalSnapShot
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    __weak typeof(self) weakSelf = self;
    [self.room addApp:testPptAppParam completionHandler:^(NSString * _Nonnull appId) {
        if ([appId length] > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakRoom closeApp:appId completionHandler:^{
                }];
            });
            [weakRoom getLocalSnapShotWithCompletion:^(UIImage * _Nullable image, NSError * _Nullable error) {
                [weakSelf.roomVC.boardView evaluateJavaScript:@"window.dispatchEvent(new CustomEvent('__slide_ref__'))" completionHandler:^(id _Nullable, NSError * _Nullable error) {
                    [weakSelf.roomVC.boardView evaluateJavaScript:@"__slide.hasOwnProperty('player')" completionHandler:^(id _Nullable hasPlayer, NSError * _Nullable error) {
                        XCTAssertNotNil(image);
                        XCTAssertTrue(hasPlayer);
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [exp fulfill];
                        });
                    }];
                }];
            }];
        } else {
            XCTAssert(NO, @"add app fail");
        }
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testAddPpt
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    [self.room addApp:testPptAppParam completionHandler:^(NSString * _Nonnull appId) {
        if ([appId length] > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakRoom closeApp:appId completionHandler:^{
                }];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [exp fulfill];
            });
            return;
        }
        XCTAssert(NO, @"add app fail");
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testAddMedia
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
        if ([appId length] > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakRoom closeApp:appId completionHandler:^{
                }];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [exp fulfill];
            });
            return;
        }
        XCTAssert(NO, @"add app fail");
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testCloseApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
        [weakRoom closeApp:appId completionHandler:^{
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testGetAttributes
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room getWindowManagerAttributesWithResult:^(NSDictionary * _Nonnull attributes) {
        XCTAssertNotNil(attributes);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testSetAttributes
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    NSString* str = @"{\"apps\":{\"MediaPlayer-7d1c9d50\":{\"kind\":\"MediaPlayer\",\"options\":{\"title\":\"IMG_0005.mov.mp4\"},\"isDynamicPPT\":false,\"createdAt\":1649314556768,\"state\":{\"size\":{},\"position\":{\"x\":0.02421330407559091,\"y\":0.04667614775918025},\"SceneIndex\":0,\"zIndex\":100}}},\"cursors\":{},\"_mainScenePath\":\"/init\",\"_mainSceneIndex\":0,\"registered\":{},\"mainViewCamera\":{\"centerX\":0,\"centerY\":0,\"scale\":1,\"id\":\"5e724ca3-a86c-4672-a1f9-11fac914ac09\"},\"mainViewSize\":{\"width\":825.984375,\"height\":428.484375,\"id\":\"5e724ca3-a86c-4672-a1f9-11fac914ac09\"},\"MediaPlayer-7d1c9d50\":{\"src\":\"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-01/25/d9bbde94-5a80-43bd-9727-660197f20d28/d9bbde94-5a80-43bd-9727-660197f20d28.mp4\"},\"focus\":\"MediaPlayer-7d1c9d50\"}";
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
    XCTAssertNotNil(attributes);
    [self.room setWindowManagerWithAttributes:attributes];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.room closeApp:@"MediaPlayer-7d1c9d50" completionHandler:^{
            [exp fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testSetWindowBoxState
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.expectedWindowBoxState = WhiteWindowBoxStateMax;
    __weak typeof(self) weakSelf = self;
    self.windowBoxStateChangeBlock = ^(WhiteRoomState *state) {
        XCTAssertEqualObjects(state.windowBoxState, WhiteWindowBoxStateMax);
        weakSelf.windowBoxStateChangeBlock = nil;
        [exp fulfill];
    };

    [self.room setWindowBoxState:WhiteWindowBoxStateMax];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testAddSlideAppQuerySlidePageState
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.roomVC.sdk setSlideDelegate:self];
    __weak typeof(self) weakSelf = self;
    NSString *title = [NSString stringWithFormat:@"Mao Slide Integration %@", NSUUID.UUID.UUIDString];
    self.expectedSlideTitle = title;
    WhiteAppParam *slideApp = [self createMaoSlideAppParamWithTitle:title];
    [self.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *,WhiteAppSyncAttributes *> * _Nonnull apps, NSError * _Nullable error) {
        XCTAssertNil(error);
        weakSelf.slideAppsBeforeAdd = apps ?: @{};
        [weakSelf.room addApp:slideApp completionHandler:^(NSString * _Nonnull appId) {
            [weakSelf resolveAddedSlideAppId:appId remainingRetryCount:12 completionHandler:^(NSString * _Nullable resolvedAppId, NSError * _Nullable resolveError) {
                XCTAssertNil(resolveError);
                XCTAssertTrue(resolvedAppId.length > 0);
                weakSelf.expectedSlideAppId = resolvedAppId;
                [weakSelf.room queryApp:resolvedAppId completionHandler:^(WhiteAppSyncAttributes * _Nonnull appParam, NSError * _Nullable queryError) {
                    XCTAssertNil(queryError);
                    XCTAssertEqualObjects(appParam.kind, @"Slide");
                    XCTAssertEqualObjects(appParam.options[@"title"], title);
                    [weakSelf.room querySlidePageState:resolvedAppId completionHandler:^(WhiteSlidePageState * _Nullable pageState, NSError * _Nullable pageStateError) {
                        if (!pageStateError) {
                            XCTAssertEqualObjects(pageState.appId, resolvedAppId);
                            XCTAssertTrue(pageState.page > 0);
                            XCTAssertTrue(pageState.pageCount > 0);
                        }
                        [weakSelf.room closeApp:resolvedAppId completionHandler:^{
                            [exp fulfill];
                        }];
                    }];
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

- (void)testSceneStateUpdate {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSString *sceneName = [[NSUUID UUID] UUIDString];
    NSString *sceneDir = [NSString stringWithFormat:@"/%@", sceneName];
    WhiteScene *scene = [[WhiteScene alloc] initWithName:sceneName ppt:nil];
    [self.room addPageWithScene:scene afterCurrentScene:YES];
    [self.room setScenePath:sceneDir];
    _stateChangeBlock = ^(WhiteSceneState* state) {
        [exp fulfill];
    };

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState {
    if (modifyState.windowBoxState &&
        [modifyState.windowBoxState isEqualToString:self.expectedWindowBoxState] &&
        self.windowBoxStateChangeBlock) {
        self.windowBoxStateChangeBlock(modifyState);
    }
    if (modifyState.sceneState) {
        if (_stateChangeBlock) {
            _stateChangeBlock(modifyState.sceneState);
            _stateChangeBlock = nil;
        }
    }
}

- (NSString *)onJSAnyError:(NSString *)reason {
    if ([reason containsString:@"[Docs Viewer]: empty scenes."]) {
        return @"";
    }
    if ([reason containsString:@"[Slide] no taskId"]) {
        return @"";
    }
    return [super onJSAnyError:reason];
}

#pragma mark - DocsEvent
// 删除该测试，因为该测试和 UI 过于密切，机器卡顿的时候测试过不去。
//- (void)testDocsEvents
//{
//    // 本测试和 UI 有关，所以这里等待的时间要长一些，避免因为机器性能导致测试失败。
//    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
//    __weak typeof(self.room) weakRoom = self.room;
//    [self.room addApp:testPptAppParam completionHandler:^(NSString * _Nonnull appId) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            WhiteWindowDocsEventOptions *ops = [[WhiteWindowDocsEventOptions alloc] init];
//            ops.page = @(1);
//            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventJumpToPage options:ops completionHandler:^(bool success) {
//                XCTAssert(success, @"WhiteWindowDocsEventJumpPage Fail");
//            }];
//        });
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventNextPage options:nil completionHandler:^(bool success) {
//                XCTAssert(success, @"WhiteWindowDocsEventNextPage Fail");
//            }];
//        });
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventPrevPage options:nil completionHandler:^(bool success) {
//                XCTAssert(success, @"WhiteWindowDocsEventPrevPage Fail");
//            }];
//        });
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventNextStep options:nil completionHandler:^(bool success) {
//                XCTAssert(success, @"WhiteWindowDocsEventNextStep Fail");
//            }];
//        });
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventPrevStep options:nil completionHandler:^(bool success) {
//                XCTAssert(success, @"WhiteWindowDocsEventPrevStep Fail");
//            }];
//        });
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            if ([appId length] > 0) {
//                [weakRoom closeApp:appId completionHandler:^{
//                    [exp fulfill];
//                }];
//            }
//        });
//    }];
//    [self waitForExpectationsWithTimeout:40 handler:^(NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"%s error: %@", __FUNCTION__, error);
//        }
//    }];
//}

#pragma mark - App API
- (void)testQueryApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
        [weakSelf.room queryApp:appId completionHandler:^(WhiteAppSyncAttributes * _Nonnull appParam, NSError * _Nullable error) {
            XCTAssert(error == nil);
            [weakSelf.room closeApp:appId completionHandler:^{}];
            [weakSelf.room queryApp:appId completionHandler:^(WhiteAppSyncAttributes * _Nonnull appParam, NSError * _Nullable afterCloseError) {
                XCTAssert(afterCloseError);
                [exp fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testQueryAll
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull id1) {
        [weakSelf.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull id2) {
            [weakSelf.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull id3) {
                [weakSelf.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *,WhiteAppSyncAttributes *> * _Nonnull apps, NSError * _Nullable error) {
                    XCTAssert(apps.allKeys.count > 0);
                    [apps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, WhiteAppSyncAttributes * _Nonnull obj, BOOL * _Nonnull stop) {
                        [weakSelf.room closeApp:key completionHandler:^{}];
                    }];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *,WhiteAppParam *> * _Nonnull afterCloseApps, NSError * _Nullable error) {
                            XCTAssert(afterCloseApps.allKeys.count == 0);
                            [exp fulfill];
                        }];
                    });
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


- (void)testFocusApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull mp4Id1) {
        [weakSelf.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull mp4Id2) {
            [weakSelf.room focusApp:mp4Id1];
            [weakSelf.roomVC.boardView evaluateJavaScript:@"manager.focused" completionHandler:^(NSString* _Nullable focused, NSError * _Nullable error) {
                NSLog(@"focused: %@", focused);
                XCTAssert([focused isEqualToString:mp4Id1]);
                [weakSelf.room focusApp:mp4Id2];
                [weakSelf.roomVC.boardView evaluateJavaScript:@"manager.focused" completionHandler:^(NSString* _Nullable focused1, NSError * _Nullable error) {
                    NSLog(@"focused: %@", focused1);
                    XCTAssert([focused1 isEqualToString:mp4Id2]);
                    [weakSelf.room closeApp:mp4Id1 completionHandler:^{}];
                    [weakSelf.room closeApp:mp4Id2 completionHandler:^{}];
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

#pragma mark - Page API
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

#pragma - private
- (WhiteAppParam *)createMaoSlideAppParamWithTitle:(NSString *)title
{
    NSString *scenePath = [NSString stringWithFormat:@"/mao-slide/%@", NSUUID.UUID.UUIDString];
    return [WhiteAppParam createSlideApp:scenePath
                                  taskId:@"46e8ff5db5714fec818f5594a6c55083"
                                     url:@"https://white-cover.oss-cn-hangzhou.aliyuncs.com/flat/dynamicConvert"
                                   title:title];
}

- (void)resolveAddedSlideAppId:(NSString *)appId remainingRetryCount:(NSInteger)remainingRetryCount completionHandler:(void (^)(NSString * _Nullable appId, NSError * _Nullable error))completionHandler
{
    if (appId.length > 0) {
        completionHandler(appId, nil);
        return;
    }
    if (remainingRetryCount <= 0) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Timed out waiting for added Slide app id"};
        completionHandler(nil, [NSError errorWithDomain:NSStringFromClass([self class]) code:-1002 userInfo:userInfo]);
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *,WhiteAppSyncAttributes *> * _Nonnull apps, NSError * _Nullable error) {
        if (!error) {
            NSString *resolvedAppId = [weakSelf findAddedMaoSlideAppId:apps ?: @{}];
            if (resolvedAppId.length > 0) {
                completionHandler(resolvedAppId, nil);
                return;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf resolveAddedSlideAppId:appId remainingRetryCount:remainingRetryCount - 1 completionHandler:completionHandler];
        });
    }];
}

- (NSString *)findAddedMaoSlideAppId:(NSDictionary<NSString *, WhiteAppSyncAttributes *> *)apps
{
    __block NSString *candidate = nil;
    NSDictionary<NSString *, WhiteAppSyncAttributes *> *previousApps = self.slideAppsBeforeAdd ?: @{};
    [apps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, WhiteAppSyncAttributes * _Nonnull obj, BOOL * _Nonnull stop) {
        if (previousApps[key]) {
            return;
        }
        if (([key hasPrefix:@"Slide-"] || [obj.kind isEqualToString:@"Slide"]) &&
            (!self.expectedSlideTitle || [obj.options[@"title"] isEqualToString:self.expectedSlideTitle])) {
            candidate = key;
            *stop = YES;
        }
    }];
    return candidate;
}

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

#pragma - Delegate
- (void)slideUrlInterrupter:(NSString *)url completionHandler:(SlideUrlInterrupterCallback)completionHandler {
    self.didCallSlideInterrupter = YES;
    NSString *questUrl = [NSString stringWithFormat:@"https://abacus-api-us.netless.group/aws/s3/presigned"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:questUrl]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"us-sv" forHTTPHeaderField:@"region"];
    request.HTTPMethod = @"POST";
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:@{@"src": url} options:NSJSONWritingFragmentsAllowed error:nil];
    request.HTTPBody = bodyData;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSString *signedUrl = dict[@"signedUrl"];
        if (signedUrl.length > 0) {
            completionHandler(signedUrl);
        }
    }] resume] ;
}

- (void)onSlideError:(WhiteSlideErrorType)slideError errorMessage:(NSString *)errorMessage slideId:(NSString *)slideId slideIndex:(NSInteger)slideIndex {
    self.didCallSlideError = YES;
    self.slideErrorIndex = slideIndex;
}

- (void)onSlidePageStateChanged:(NSString *)appId page:(NSInteger)page pageCount:(NSInteger)pageCount {
    if (self.expectedSlideAppId && ![self.expectedSlideAppId isEqualToString:appId]) {
        return;
    }
    self.didCallSlidePageStateChanged = YES;
    self.slidePageStateAppId = appId;
    self.slidePageStatePage = page;
    self.slidePageStatePageCount = pageCount;
}

@end
