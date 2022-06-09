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

@interface MultiViewsRoomTest : BaseRoomTest
@end

@implementation MultiViewsRoomTest
{
    WhiteSceneStateBlock _stateChangeBlock;
}

+ (void)load
{
    testMp4AppParam = [WhiteAppParam createMediaPlayerApp:@"https://flat-web-dev.whiteboard.agora.io/preview/https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-01/25/d9bbde94-5a80-43bd-9727-660197f20d28/d9bbde94-5a80-43bd-9727-660197f20d28.mp4/" title:@"testApp"];
}

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig {
    sdkConfig.useMultiViews = YES;
}

- (void)testAddApp
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
        }
    }
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

@end
