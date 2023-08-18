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
@end

@implementation MultiViewsRoomTest
{
    WhiteSceneStateBlock _stateChangeBlock;
}

+ (void)load
{
    testMp4AppParam = [WhiteAppParam
                       createMediaPlayerApp:@"https://flat-web-dev.whiteboard.agora.io/preview/https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-01/25/d9bbde94-5a80-43bd-9727-660197f20d28/d9bbde94-5a80-43bd-9727-660197f20d28.mp4/"
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
    if (modifyState.sceneState) {
        if (_stateChangeBlock) {
            _stateChangeBlock(modifyState.sceneState);
            _stateChangeBlock = nil;
        }
    }
}

#pragma mark - DocsEvent
- (void)testDocsEvents
{
    // 本测试和 UI 有关，所以这里等待的时间要长一些，避免因为机器性能导致测试失败。
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    [self.room addApp:testPptAppParam completionHandler:^(NSString * _Nonnull appId) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WhiteWindowDocsEventOptions *ops = [[WhiteWindowDocsEventOptions alloc] init];
            ops.page = @(1);
            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventJumpToPage options:ops completionHandler:^(bool success) {
                XCTAssert(success, @"WhiteWindowDocsEventJumpPage Fail");
            }];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventNextPage options:nil completionHandler:^(bool success) {
                XCTAssert(success, @"WhiteWindowDocsEventNextPage Fail");
            }];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventPrevPage options:nil completionHandler:^(bool success) {
                XCTAssert(success, @"WhiteWindowDocsEventPrevPage Fail");
            }];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventNextStep options:nil completionHandler:^(bool success) {
                XCTAssert(success, @"WhiteWindowDocsEventNextStep Fail");
            }];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakRoom dispatchDocsEvent:WhiteWindowDocsEventPrevStep options:nil completionHandler:^(bool success) {
                XCTAssert(success, @"WhiteWindowDocsEventPrevStep Fail");
            }];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([appId length] > 0) {
                [weakRoom closeApp:appId completionHandler:^{
                    [exp fulfill];
                }];
            }
        });
    }];
    [self waitForExpectationsWithTimeout:40 handler:^(NSError * _Nullable error) {
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

@end
