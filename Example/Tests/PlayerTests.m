//
//  PlayerTests.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/8.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhitePlayerViewController.h"

typedef void(^InterrupterBlock)(NSString *url);

@interface PlayerTests : XCTestCase<WhitePlayerEventDelegate, WhiteCommonCallbackDelegate>

@property (nonatomic, strong) WhitePlayerViewController *vc;
@property (nonatomic, strong) WhitePlayer *player;

@property (nonatomic, copy) dispatch_block_t loadFirstFrameBlock;
@property (nonatomic, copy) void (^seekBlock)(NSTimeInterval time);
@property (nonatomic, copy) dispatch_block_t playBlock;
@property (nonatomic, copy) dispatch_block_t pauseBlock;
@property (nonatomic, copy) void (^eventBlock)(WhiteEvent *event);
@property (nonatomic, copy) void (^eventsBlock)(NSArray<WhiteEvent *> *events);
@property (nonatomic, copy) InterrupterBlock interrupterBlock;

@end


@implementation PlayerTests
#pragma mark - Const
static NSTimeInterval kTimeout = 30;
static NSString * const kTestingCustomEventName = @"TestingCustomEventName";

#pragma mark - Test
- (void)setUp
{
    [super setUp];
    
    self.vc = [[WhitePlayerViewController alloc] initWithSdkConfig:[self testingConfig]];

    self.vc.eventDelegate = self;
    self.vc.commonDelegate = self;

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    __weak typeof(self)weakSelf = self;
    self.vc.playBlock = ^(WhitePlayer * _Nullable player, NSError * _Nullable eroror) {
        id self = weakSelf;
        weakSelf.player = player;
        XCTAssertNotNil(player);
        [exp fulfill];
    };
    
    __unused UIView *view = [self.vc view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.vc animated:YES];
    }
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)tearDown
{
    [super tearDown];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - Private
- (void)setupPlayer
{
    [self.player seekToScheduleTime:0];
    [self.player play];
}

- (WhiteSdkConfiguration *)testingConfig;
{
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    
    //为了测试图片 拦截 API，开启
    config.enableInterrupterAPI = YES;
    config.debug = YES;
    
    //打开用户头像显示信息
    config.userCursor = YES;
    return config;
}

#pragma mark - Player Control

- (void)testPlay
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    self.playBlock = ^{
        [exp fulfill];
    };
    [self setupPlayer];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testPause
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    __weak typeof(self)weakSelf = self;
    
    self.playBlock = ^{
        [weakSelf.player pause];
    };
    
    self.pauseBlock = ^{
        [exp fulfill];
    };
    
    [self setupPlayer];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testSeekToScheduleTime
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    CGFloat expTime = 5;
    __weak typeof(self)weakSelf = self;
    self.seekBlock = ^(NSTimeInterval time) {
        if (time == expTime) {
            [exp fulfill];
        } else if (time < expTime) {
            id self = weakSelf;
            XCTFail(@"seek 失败");
        }
    };
    
    //FIXME:如果带音视频的回放，初始化player，不先播放一次的话，无法 seek
    [self.player seekToScheduleTime:expTime];
    [self.player play];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - Event
- (void)testEvent {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.player addMagixEventListener:kTestingCustomEventName];
    
    [self setupPlayer];
    self.eventBlock = ^(WhiteEvent *event) {
        [exp fulfill];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testFrequencyEvents {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.player addHighFrequencyEventListener:kTestingCustomEventName fireInterval:500];
    
    [self setupPlayer];
    self.eventsBlock = ^(NSArray<WhiteEvent *> *events) {
        [exp fulfill];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - Set

- (void)testSetObserverMode
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.player setObserverMode:WhiteObserverModeFreedom];
    
    __weak typeof(self)weakSelf = self;
    self.playBlock = ^{
        [weakSelf.player getPlayerStateWithResult:^(WhitePlayerState * _Nonnull state) {
            id self = weakSelf;
            XCTAssertTrue(state.observerMode == WhiteObserverModeFreedom);
            [exp fulfill];
        }];
    };
    
    [self setupPlayer];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testInsertImage
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    self.interrupterBlock = ^(NSString *url) {
        [exp fulfill];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Get
- (void)testGetPhase
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    __weak typeof(self)weakSelf = self;
    [weakSelf.player getPhaseWithResult:^(WhitePlayerPhase phase) {
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testGetPlayerState
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    __weak typeof(self)weakSelf = self;
    self.loadFirstFrameBlock = ^{
        [weakSelf.player getPlayerStateWithResult:^(WhitePlayerState * _Nonnull state) {
            [exp fulfill];
        }];
    };
    
    [self setupPlayer];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testGetPlayerTimeInfo
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    [self setupPlayer];
    
    [self.player getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
        XCTAssertNotNil(info);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - WhitePlayerEventDelegate

- (void)phaseChanged:(WhitePlayerPhase)phase
{
    NSLog(@"PlayerTest %s %ld", __FUNCTION__, (long)phase);
    if (phase == WhitePlayerPhasePlaying && self.playBlock) {
        self.playBlock();
    } else if (phase == WhitePlayerPhasePause && self.pauseBlock) {
        self.pauseBlock();
    }
}

- (void)loadFirstFrame
{
    NSLog(@"PlayerTest %s", __FUNCTION__);
    if (self.loadFirstFrameBlock) {
        self.loadFirstFrameBlock();
    }
}

- (void)sliceChanged:(NSString *)slice
{
    NSLog(@"PlayerTest %s slice:%@", __FUNCTION__, slice);
}

- (void)playerStateChanged:(WhitePlayerState *)modifyState
{
    NSString *str = [modifyState jsonString];
    NSLog(@"PlayerTest %s state:%@", __FUNCTION__, str);
}

- (void)stoppedWithError:(NSError *)error
{
    NSLog(@"PlayerTest %s error:%@", __FUNCTION__, error);
}

- (void)scheduleTimeChanged:(NSTimeInterval)time
{
    NSLog(@"PlayerTest %s time:%f", __FUNCTION__, (double)time);
    if (self.seekBlock) {
        self.seekBlock(time);
    }
}

- (void)fireMagixEvent:(WhiteEvent *)event
{
    XCTAssertNotNil(event);
    NSLog(@"fireMagixEvent: %@", event);
    if (self.eventBlock) {
        self.eventBlock(event);
    }
}

- (void)fireHighFrequencyEvent:(NSArray<WhiteEvent *>*)events
{
    XCTAssertNotNil(events);
    NSLog(@"fireHighFrequencyEvent: %lu", (unsigned long)[events count]);
    if (self.eventsBlock) {
        self.eventsBlock(events);
    }
}

#pragma mark - WhiteCommonCallbackDelegate
- (NSString *)urlInterrupter:(NSString *)url
{
    if (self.interrupterBlock) {
        self.interrupterBlock(url);
    }
    return url;
}

@end
