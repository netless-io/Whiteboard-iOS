//
//  WhiteDisplayerTests.m
//  WhiteSDKPrivate_Tests
//
//  Created by yleaf on 2019/11/1.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"


typedef void(^WhiteEventBlock)(WhiteEvent *event);

// 测试 WhiteRoom 与 WhitePlayer 的共有方法
@interface WhiteDisplayerTests : XCTestCase<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate>
@property (nonatomic, strong) WhiteRoomViewController *vc;
@property (nonatomic, strong) WhiteRoom *room;
@property (nonatomic, copy) WhiteEventBlock eventBlock;
@property (nonatomic, strong) XCTestExpectation *exp;
@end

@implementation WhiteDisplayerTests

static NSString * const kTestingCustomEventName = @"WhiteCommandCustomEvent";
static NSTimeInterval kTimeout = 30;
#define CustomEventPayload @{@"test": @"1234"}

- (WhiteSdkConfiguration *)testingConfig;
{
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    
    //如果不需要拦截图片API，则不需要开启，页面内容较为复杂时，可能会有性能问题
    config.enableInterrupterAPI = YES;
    config.debug = YES;
    return config;
}

- (void)setUp {
    
    [super setUp];
    
    self.vc = [[WhiteRoomViewController alloc] initWithSdkConfig:[self testingConfig]];
    self.vc.roomCallbackDelegate = self;
    self.vc.commonDelegate = self;
    __unused UIView *view = [self.vc view];
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    __weak typeof(self)weakSelf = self;
    self.vc.roomBlock = ^(WhiteRoom *room, NSError *error) {
        if (room) {
            weakSelf.room = room;
            [exp fulfill];
        } else {
            typeof(weakSelf) self = weakSelf;
            XCTFail(@"房间创建失败");
        }
    };
    
    // Webview 执行 js 需要在视图栈中显示
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.vc animated:YES];
    }
    
    // 创建房间超时可能性
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav popToRootViewControllerAnimated:YES];
    }
    [super tearDown];
}

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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimeout / 2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

//TODO:测试移动视角 API

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
