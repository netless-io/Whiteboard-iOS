//
//  SDKTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/4/24.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

@interface SDKTest : BaseRoomTest
@end

static const NSArray<NSString *> *ua;

@implementation SDKTest

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig
{
    ua = @[@"fffff/1.0.0", @"kkkk/1.2.2"];
    [sdkConfig setValue: ua forKey:@"netlessUA"];
}

- (void)testUA
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.roomVC.sdk.bridge evaluateJavaScript:@"window.__netlessUA" completionHandler:^(id _Nullable value, NSError * _Nullable error) {
        [ua enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            XCTAssertTrue([(NSString *)value containsString:obj]);
        }];
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

@end
