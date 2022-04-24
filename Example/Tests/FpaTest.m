//
//  FpaTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/4.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"
#import <Whiteboard/WhiteFpa.h>
#import "WhiteTestSocket.h"

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

@interface FpaTest : BaseRoomTest
@property (nonatomic, weak) WhiteTestSocket *testSocket;
@end

@implementation FpaTest

- (void)roomConfigDidSetup:(WhiteRoomConfig *)config
{
    if (@available(iOS 13.0, *)) {
        config.nativeWebSocket = YES;
    } else {
        XCTAssert(@"using iOS 13 +");
    };
}

- (void)roomVCDidSetup:(WhiteRoomViewController *)roomVC
{
    __weak typeof(self) weakSelf = self;
    roomVC.beginJoinRoomBlock = ^{
        WhiteTestSocket *socket = [[WhiteTestSocket alloc] initWithBridge:weakSelf.roomVC.boardView];
        [weakSelf.roomVC.boardView addJavascriptObject:socket namespace:@"ws"];
        weakSelf.testSocket = socket;
    };
}

// MARK: - ReadyState
- (void)testOpen
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room.bridge callHandler:@"ws.readyState" completionHandler:^(NSNumber * _Nullable value) {
        SocketReadyState state = [value intValue];
        XCTAssertTrue(state == SocketReadyStateOPEN);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testNativeClose
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak WhiteRoom* weakRoom = self.room;
    [self.room disconnect:^{
        [weakRoom.bridge callHandler:@"ws.readyState" completionHandler:^(NSNumber * _Nullable value) {
            SocketReadyState state = [value intValue];
            XCTAssertTrue(state == SocketReadyStateCLOSED);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testJSClose
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room.bridge callHandler:@"ws.mockCloseFromJs" arguments:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // JS手动关闭之后，white-web-sdk会主动开启一个新的socket
        [self.room.bridge callHandler:@"ws.readyState" completionHandler:^(NSNumber * _Nullable value) {
            SocketReadyState state = [value intValue];
            XCTAssertTrue(state == SocketReadyStateOPEN);
            [exp fulfill];
        }];
    });
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.testSocket.testAbandonMessageDic[@"0"] = @"";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.roomVC.room disconnect:^{
                NSMutableSet *set = [self.testSocket valueForKey:@"workingSocketsIdSet"];
                XCTAssertTrue(set.count == 0);
                [exp fulfill];
            }];
        });
    });
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

@end
