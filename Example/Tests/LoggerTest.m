//
//  LoggerTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2023/11/6.
//  Copyright © 2023 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"
#import "Whiteboard.h"

@interface RoomLoggerTest : BaseRoomTest<WhiteCommonCallbackDelegate>
@end

@implementation RoomLoggerTest
{
    XCTestExpectation* _currentExpectation;
}

- (void)roomVCDidSetup:(WhiteRoomViewController *)roomVC {
    [roomVC.sdk setCommonCallbackDelegate:self];
}

- (void)testConsoleLog {
    _currentExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

// MARK: - Delegate
- (void)logger:(NSDictionary *)dict {
    if ([self.name containsString:@"testConsoleLog"]) {
        if ([dict[@"[WhiteWKConsole]"] length] > 0) {
            [_currentExpectation fulfill];
            _currentExpectation = nil;
        }
    }
}

@end
