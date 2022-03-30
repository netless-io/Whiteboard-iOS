//
//  WritableDetectTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/17.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseRoomTest.h"

@interface WritableDetectTest : BaseRoomTest
@end

@implementation WritableDetectTest

- (void)roomConfigDidSetup:(WhiteRoomConfig *)config {
    if ([self.name containsString:@"testActionsNotWritable"]) {
        config.enableWritableAssert = YES;
        config.isWritable = NO;
    }
    if ([self.name containsString:@"testEnableWritableAssert"]) {
        config.enableWritableAssert = NO;
        config.isWritable = NO;
    }
}

- (void)testRepeatUpdateWritable
{
    [self.roomVC.room setWritable:YES completionHandler:nil];
    XCTAssertThrows([self.roomVC.room setWritable:NO completionHandler:nil]);
}

- (void)testActionsWhenWritable
{
    [self performAssertableActions];
    [self performNotAssertableActions];
}

- (void)testActionsNotWritable
{
    XCTAssertThrows([self performAssertableActions]);
    [self performNotAssertableActions];
}

- (void)testEnableWritableAssert
{
    [self performAssertableActions];
    [self performNotAssertableActions];
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
@end
