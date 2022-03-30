//
//  WhiteDisplayerTests.m
//  WhiteSDKPrivate_Tests
//
//  Created by yleaf on 2019/11/1.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseRoomTest.h"

typedef void(^WhiteEventBlock)(WhiteEvent *event);

// 测试 WhiteRoom 与 WhitePlayer 的共有方法
@interface WhiteDisplayerTests : BaseRoomTest
@property (nonatomic, copy) WhiteEventBlock eventBlock;
@property (nonatomic, strong) XCTestExpectation *exp;
@end

@implementation WhiteDisplayerTests

static NSString * const kTestingCustomEventName = @"WhiteCommandCustomEvent";
#define CustomEventPayload @{@"test": @"1234"}

- (void)testRefreshViewSize {
    [self.room refreshViewSize];
}

- (void)testConvertToPointInWorld {
    WhitePanEvent *panEvent = [[WhitePanEvent alloc] init];
    panEvent.x = 11;
    panEvent.y = 22;

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room convertToPointInWorld:panEvent result:^(WhitePanEvent * _Nonnull convertPoint) {
        NSLog(@"convertToPointInWorld:%@", convertPoint);
        XCTAssertNotNil(convertPoint);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testEventListener {
    [self.room addMagixEventListener:kTestingCustomEventName];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    __weak typeof(self)weakSelf = self;
    self.eventBlock = ^(WhiteEvent *event) {
        id self = weakSelf;
        XCTAssertTrue([event.eventName isEqualToString:kTestingCustomEventName]);
        XCTAssertTrue([event.payload isEqualToDictionary:CustomEventPayload]);
        [exp fulfill];
    };

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testRemoveEventListener {
    [self.room addMagixEventListener:kTestingCustomEventName];
    [self.room removeMagixEventListener:kTestingCustomEventName];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    __weak typeof(self)weakSelf = self;
    self.eventBlock = ^(WhiteEvent *event) {
        typeof(weakSelf) self = weakSelf;
        XCTFail(@"移除失败");
    };

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeout / 5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [exp fulfill];
    });

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testFrequencyEventListener {
    [self.room addHighFrequencyEventListener:kTestingCustomEventName fireInterval:500];

    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];
    [self.room dispatchMagixEvent:kTestingCustomEventName payload:CustomEventPayload];

    self.exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testPreview {

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room getScenePreviewImage:@"/init" completion:^(UIImage * _Nullable image) {
        if (image) {
            [exp fulfill];
        }
    }];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testCover {

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room getSceneSnapshotImage:@"/init" completion:^(UIImage * _Nullable image) {
        if (image) {
            [exp fulfill];
        }
    }];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testEntireScene {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room getEntireScenes:^(NSDictionary<NSString *,NSArray<WhiteScene *> *> * _Nonnull dict) {
        XCTAssertTrue(dict.allKeys.count > 0);
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<WhiteScene *> * _Nonnull obj, BOOL * _Nonnull stop) {
            XCTAssertTrue(obj.count > 0);
            [obj enumerateObjectsUsingBlock:^(WhiteScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                XCTAssertTrue([obj isKindOfClass:[WhiteScene class]]);
            }];
        }];
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];

}

#pragma mark - WhiteRoomCallbackDelegate

- (void)firePhaseChanged:(WhiteRoomPhase)phase
{
    NSLog(@"%s, %ld", __func__, (long)phase);
}

- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState;
{
    NSLog(@"%s, %@", __func__, [modifyState jsonString]);
}

- (void)fireDisconnectWithError:(NSString *)error
{
    NSLog(@"%s, %@", __func__, error);
}

- (void)fireKickedWithReason:(NSString *)reason
{
    NSLog(@"%s, %@", __func__, reason);
}

- (void)fireCatchErrorWhenAppendFrame:(NSUInteger)userId error:(NSString *)error
{
    NSLog(@"%s, %lu %@", __func__, (unsigned long)userId, error);
}

- (void)fireMagixEvent:(WhiteEvent *)event
{
    NSLog(@"fireMagixEvent: %@", [event jsonString]);
    if (self.eventBlock) {
        self.eventBlock(event);
    }
}

- (void)fireHighFrequencyEvent:(NSArray<WhiteEvent *>*)events
{
    XCTAssertNotNil(events);
    NSLog(@"fireHighFrequencyEvent: %lu", (unsigned long)[events count]);
    [self.exp fulfill];
}

#pragma mark - WhiteCommonCallbackDelegate
- (void)throwError:(NSError *)error
{
    NSLog(@"throwError: %@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url
{
    if (self.exp) {
        [self.exp fulfill];
    }
    return url;
}

@end
