//
//  MultiViewsRoomTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/25.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

static WhiteAppParam* _Nonnull testMp4AppParam;

@interface MultiViewsRoomTest : BaseRoomTest
@end

@implementation MultiViewsRoomTest

+ (void)load
{
    testMp4AppParam = [WhiteAppParam createMediaPlayerApp:@"https://flat-web-dev.whiteboard.agora.io/preview/https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-01/25/d9bbde94-5a80-43bd-9727-660197f20d28/d9bbde94-5a80-43bd-9727-660197f20d28.mp4/" title:@"testApp"];
}

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig {
    sdkConfig.useMultiViews = YES;
}

- (void)testAddApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
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
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testCloseApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self.room) weakRoom = self.room;
    [self.room addApp:testMp4AppParam completionHandler:^(NSString * _Nonnull appId) {
        [weakRoom closeApp:appId completionHandler:^{
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}
@end
