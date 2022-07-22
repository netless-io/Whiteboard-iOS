//
//  WebCrashTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/28.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

typedef void(^Block)();
typedef void(^ErrorBlock)(NSError *);
@interface WebCrashTest : BaseRoomTest
@property (nonatomic, copy) Block startRecoveringBlock;
@property (nonatomic, copy) Block endRecoveringBlock;
@property (nonatomic, copy) ErrorBlock sdkErrorBlock;
@end

// 该测试只能在真机上测试
@implementation WebCrashTest

- (void)testWebCrash {
    XCTestExpectation *startRecoverExp = [self expectationWithDescription:@"startRecoverExp"];
    XCTestExpectation *endRecoverExp = [self expectationWithDescription:@"endRecoverExp"];
    [self tryCrashJS];

    __weak typeof(self) weakSelf = self;
    [self setStartRecoveringBlock:^{
        weakSelf.startRecoveringBlock = nil;
        [startRecoverExp fulfill];
    }];
    
    [self setEndRecoveringBlock:^{
        weakSelf.endRecoveringBlock = nil;
        [weakSelf.room getRoomStateWithResult:^(WhiteRoomState * _Nonnull state) {
            [endRecoverExp fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)tryCrashJS {
    WhiteBoardView* bridge = [self.room valueForKey:@"bridge"];
    NSInteger step = 5000000000;
    NSString *randomString = [[NSUUID UUID] UUIDString];
    NSString *js = [NSString stringWithFormat:@"window.foo={};for (let index = %d; index < %ld; index++) {window.foo[`${index}`] = {value: `%@`}}", 0, (long)step, randomString];
    [bridge evaluateJavaScript:js completionHandler:nil];
}

static int crashTime = 0;
- (void)testWebCrashOverTimes {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    [self tryCrashJS];
    __weak typeof(self) weakSelf = self;
    self.sdkErrorBlock = ^(NSError *error) {
        XCTAssertTrue(error.code == -500);
        [exp fulfill];
    };
    [self setEndRecoveringBlock:^{
        crashTime += 1;
        XCTAssertTrue(crashTime <= 3);
        [weakSelf tryCrashJS];
    }];
    
    [self waitForExpectationsWithTimeout:300 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)throwError:(NSError *)error {
    if (self.sdkErrorBlock) {
        self.sdkErrorBlock(error);
    }
}

- (void)startRecoveringFromMemoryIssues {
    if (self.startRecoveringBlock) {
        self.startRecoveringBlock();
    }
}

- (void)endRecoveringFromMemoryIssues:(BOOL)success {
    if (self.endRecoveringBlock) {
        self.endRecoveringBlock();
    }
}

@end
