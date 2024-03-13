//
//  RoomLeakTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2024/3/12.
//  Copyright © 2024 leavesster. All rights reserved.
//

#import "XCTest/XCTest.h"
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"
#import "TestUtility.h"

@interface RoomLeakTest : XCTestCase
@property (nonatomic, weak) id target;
@end

@implementation RoomLeakTest

- (void)testWhiteboardViewLeak {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    @autoreleasepool {
        WhiteRoomViewController *vc = [[WhiteRoomViewController alloc] init];
        vc.sdkConfig.log = YES;
        vc.sdkConfig.loggerOptions = @{
            @"printLevelMask": WhiteSDKLoggerOptionLevelDebug
        };
        vc.sdkConfig.useMultiViews = YES;
        WhiteRoomConfig *config = [[WhiteRoomConfig alloc] initWithUUID:WhiteRoomUUID roomToken:WhiteRoomToken uid:@"1"];
        vc.roomConfig = config;
        
        __unused UIView *view = [vc view];
        UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        if ([nav isKindOfClass:[UINavigationController class]]) {
            [nav pushViewController:vc animated:NO];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.target = vc.boardView;
            [nav popViewControllerAnimated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [exp fulfill]; // VC need time to be released.
            });
        });
    }
    [self addTeardownBlock:^{
        XCTAssertNil(self.target);
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

@end
