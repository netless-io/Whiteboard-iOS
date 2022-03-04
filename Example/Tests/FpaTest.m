//
//  FpaTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/4.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"

typedef enum : NSUInteger {
    SocketReadyStateCONNECTING = 0,
    SocketReadyStateOPEN = 1,
    SocketReadyStateCLOSING = 2,
    SocketReadyStateCLOSED = 3,
} SocketReadyState;

@interface WhiteRoom ()
@property (nonatomic, weak, readonly) WhiteBoardView *bridge;
@end

@implementation WhiteRoom

@end

static NSTimeInterval kTimeout = 30;

@interface FpaTest : XCTestCase
@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;
@end

@implementation FpaTest

- (void)setUp
{
    // To test, should run `./update_web_resource debug`, before
    [super setUp];
    self.continueAfterFailure = NO;
    [self refreshRoomVC];
}

- (void)tearDown
{
}

// MARK: - ReadyState
- (void)testOpen
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        [room.bridge callHandler:@"ws.readyState" completionHandler:^(NSNumber * _Nullable value) {
            SocketReadyState state = [value intValue];
            XCTAssertTrue(state == SocketReadyStateOPEN);
            [exp fulfill];
        }];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testNativeClose
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        __weak WhiteRoom* weakRoom = room;
        [weakRoom disconnect:^{
            [weakRoom.bridge callHandler:@"ws.readyState" completionHandler:^(NSNumber * _Nullable value) {
                SocketReadyState state = [value intValue];
                XCTAssertTrue(state == SocketReadyStateCLOSED);
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

- (void)testJSClose
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        [room.bridge callHandler:@"ws.mockCloseFromJs" arguments:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // JS手动关闭之后，white-web-sdk会主动开启一个新的socket
            [room.bridge callHandler:@"ws.readyState" completionHandler:^(NSNumber * _Nullable value) {
                SocketReadyState state = [value intValue];
                XCTAssertTrue(state == SocketReadyStateOPEN);
                [exp fulfill];
            }];
        });
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - Prepare

- (void)refreshRoomVC
{
    _roomVC = [[WhiteRoomViewController alloc] init];
    _roomVC.roomCallbackDelegate = self;
    _roomVC.commonDelegate = self;
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
        NSDictionary *payload = @{@"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg", @"userId": @1024};
        _roomConfig = [[WhiteRoomConfig alloc] initWithUUID:WhiteRoomUUID roomToken:WhiteRoomToken uid:@"1"];
        _roomConfig.nativeWebSocket = YES;
    }
    return _roomConfig;
}

- (WhiteRoomViewController *)roomVC
{
    return _roomVC;
}
@end
