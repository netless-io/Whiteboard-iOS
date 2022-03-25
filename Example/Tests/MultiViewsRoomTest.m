//
//  MultiViewsRoomTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/25.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"

static NSTimeInterval kTimeout = 30;
static WhiteAppParam* _Nonnull testMp4AppParam;

@interface MultiViewsRoomTest : XCTestCase
@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;
@end

@implementation MultiViewsRoomTest

+ (void)load
{
    testMp4AppParam = [WhiteAppParam createMediaPlayerApp:@"https://flat-web-dev.whiteboard.agora.io/preview/https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-01/25/d9bbde94-5a80-43bd-9727-660197f20d28/d9bbde94-5a80-43bd-9727-660197f20d28.mp4/" title:@"testApp"];
}

- (void)setUp
{
    [super setUp];
    [self refreshRoomVC];
}

- (void)testAddApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        __weak typeof(room) weakRoom = room;
        [room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
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
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testCloseApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        __weak typeof(room) weakRoom = room;
        [room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
            [weakRoom closeApp:appId completionHandler:^{
                [exp fulfill];
            }];
        }];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)refreshRoomVC
{
    _roomVC = [[WhiteRoomViewController alloc] init];
    _roomVC.useMultiViews = YES;
    _roomVC.roomConfig = self.roomConfig;
    //Webview 在视图栈中才能正确执行 js
    __unused UIView *view = [self.roomVC view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    [nav popToRootViewControllerAnimated:NO];
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.roomVC animated:YES];
    }
}

- (WhiteRoomConfig *)roomConfig
{
    if (!_roomConfig) {
        _roomConfig = [[WhiteRoomConfig alloc] initWithUUID:WhiteRoomUUID roomToken:WhiteRoomToken uid:@"1"];
    }
    return _roomConfig;
}
@end
