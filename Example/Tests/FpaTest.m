//
//  FpaTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/4.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import <Whiteboard/WhiteFpa.h>
#import "WhiteRoomViewController.h"
#import "WhiteTestSocket.h"

typedef enum : NSUInteger {
    SocketReadyStateCONNECTING = 0,
    SocketReadyStateOPEN = 1,
    SocketReadyStateCLOSING = 2,
    SocketReadyStateCLOSED = 3,
} SocketReadyState;

static NSTimeInterval kTimeout = 30;

@interface WhiteRoom ()
@property (nonatomic, weak, readonly) WhiteBoardView *bridge;
@end

@implementation WhiteRoom
@end

@interface WhiteSDK ()
@property (nonatomic, weak) WhiteBoardView *bridge;
@end

@implementation WhiteSDK
@end

@interface FpaTest : XCTestCase
@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;
@property (nonatomic, weak) WhiteTestSocket *testSocket;
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

- (void)testTimeout
{
    // 启动第一个socket, 3秒成功之后，模拟网络没有响应，切断第一个socket的sendMessage
    // js会启动第二个socket, 这个socket的通信不会被切断
    // 结果会有两个socket，并且两个socket都被正确关闭
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.testSocket.testAbandonMessageDic[@"0"] = @"";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.roomVC.room disconnect:^{
                    NSMutableSet *set = [weakSelf.testSocket valueForKey:@"workingSocketsIdSet"];
                    XCTAssertTrue(set.count == 0);
                    [exp fulfill];
                }];
            });
        });
    };
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
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
    __weak typeof(self) weakSelf = self;
    _roomVC.beginJoinRoomBlock = ^{
        [WhiteFPA setupFpa:[WhiteFPA defaultFpaConfig] chain:[WhiteFPA defaultChain]];
        WhiteTestSocket *socket = [[WhiteTestSocket alloc] initWithBridge:weakSelf.roomVC.boardView];
        [weakSelf.roomVC.boardView addJavascriptObject:socket namespace:@"ws"];
        weakSelf.testSocket = socket;
    };
    
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
