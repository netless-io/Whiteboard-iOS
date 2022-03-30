//
//  WritableDetectTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/17.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"

static NSTimeInterval kTimeout = 30;

@interface WritableDetectTest : XCTestCase
@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;
@end

@implementation WritableDetectTest

- (void)setUp {
    [super setUp];
}

- (void)testRepeatUpdateWritable
{
    self.roomConfig.isWritable = YES;
    [self refreshRoomVC];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        [weakSelf.roomVC.room setWritable:YES completionHandler:nil];
        XCTAssertThrows([weakSelf.roomVC.room setWritable:NO completionHandler:nil]);
        [exp fulfill];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testActionsWhenWritable
{
    self.roomConfig.isWritable = YES;
    [self refreshRoomVC];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        [weakSelf performAssertableActions];
        [weakSelf performNotAssertableActions];
        [exp fulfill];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testActionsNotWritable
{
    self.roomConfig.enableWritableAssert = YES;
    self.roomConfig.isWritable = NO;
    [self refreshRoomVC];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        XCTAssertThrows([weakSelf performAssertableActions]);
        [weakSelf performNotAssertableActions];
        [exp fulfill];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testEnableWritableAssert
{
    self.roomConfig.enableWritableAssert = NO;
    self.roomConfig.isWritable = NO;
    [self refreshRoomVC];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
        [weakSelf performAssertableActions];
        [weakSelf performNotAssertableActions];
        [exp fulfill];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)performAssertableActions
{
    [self.roomVC.room dispatchMagixEvent:@"1" payload:@{@"1": @"1"}];
    [self.roomVC.room setMemberState:[WhiteMemberState new]];
}

- (void)performNotAssertableActions
{
    __weak typeof(self) weakSelf = self;
    [self.roomVC.room setWritable:!self.roomVC.room.isWritable completionHandler:^(BOOL isWritable, NSError * _Nullable error) {
        [weakSelf.roomVC.room setWritable:!isWritable completionHandler:nil];
    }];
}

- (void)refreshRoomVC
{
    _roomVC = [[WhiteRoomViewController alloc] init];
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
