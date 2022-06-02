//
//  PlayerTests.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/8.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhitePureReplayViewController.h"

typedef void(^InterrupterBlock)(NSString *url);

@interface PlayerTests : XCTestCase<WhitePlayerEventDelegate, WhiteCommonCallbackDelegate>

@property (nonatomic, strong) WhitePureReplayViewController *vc;
@property (nonatomic, strong) WhitePlayer *player;

@property (nonatomic, copy) dispatch_block_t loadFirstFrameBlock;
@property (nonatomic, copy) void (^seekBlock)(NSTimeInterval time);
@property (nonatomic, copy) dispatch_block_t playBlock;
@property (nonatomic, copy) dispatch_block_t pauseBlock;
@property (nonatomic, copy) void (^eventBlock)(WhiteEvent *event);
@property (nonatomic, copy) void (^eventsBlock)(NSArray<WhiteEvent *> *events);
@property (nonatomic, copy) InterrupterBlock interrupterBlock;

@end

/**
 测试 Player 时，需要在 Tests-Prefix.pch 里面填写  WhiteReplayRoomUUID 以及 WhiteReplayRoomToken
 */
@implementation PlayerTests
#pragma mark - Const
static NSTimeInterval kTimeout = 30;
static NSString * const kTestingCustomEventName = @"WhiteCommandCustomEvent";

#pragma mark - Test
- (void)setUp
{
    [super setUp];
    self.continueAfterFailure = NO;
    
    WhitePureReplayViewController *vc = [[WhitePureReplayViewController alloc] init];
    vc.sdkConfig.enableInterrupterAPI = YES;
    vc.eventDelegate = self;
    vc.commonDelegate = self;
    WhitePlayerConfig *playerConfig = [[WhitePlayerConfig alloc] initWithRoom:WhiteReplayRoomUUID roomToken:WhiteReplayRoomToken];
    vc.playerConfig = playerConfig;

    self.vc = vc;

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

- (void)testSeekToScheduleTimeWithCompletionHandler
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    CGFloat expTime = 5;
    [self.player play];
    [self.player seekToScheduleTime:expTime completionHandler:^(WhitePlayerSeekingResult  _Nonnull result) {
        if ([result isEqualToString:WhitePlayerSeekingResultSuccess]) {
            [exp fulfill];
        }
    }];
    
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

    
    __weak typeof(self)weakSelf = self;
    
    self.loadFirstFrameBlock = ^{
        [weakSelf.player setObserverMode:WhiteObserverModeFreedom];
    };
    
    self.playBlock = ^{
        [weakSelf.player getPlayerStateWithResult:^(WhitePlayerState * _Nonnull state) {
            id self = weakSelf;
            XCTAssertTrue(state.observerMode == WhiteObserverModeFreedom, @"already set %ld but still %ld", (long)WhiteObserverModeFreedom, (long)state.observerMode);
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

// 暂时移除该测试，待web-sdk修复后加回
//- (void)testInsertImage
//{
//    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
//
//    self.interrupterBlock = ^(NSString *url) {
//        [exp fulfill];
//    };
//
//    [self setupPlayer];
//
//    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"%s error: %@", __FUNCTION__, error);
//        }
//    }];
//}

//FIXME:添加一个异步获取，反而获得的是 1
- (void)testPlaybackSpeed
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    self.player.playbackSpeed = 1.25;
    __weak typeof(self)weakSelf = self;
    [self.player getPlaybackSpeed:^(CGFloat speed) {
        if (speed == weakSelf.player.playbackSpeed) {
            [exp fulfill];
        } else {
            id self = weakSelf;
            XCTFail(@"倍率调整失败");
        }
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Get
- (void)testGetScene
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self setupPlayer];
    __weak typeof(self) weakSelf = self;
    self.loadFirstFrameBlock = ^{
        [weakSelf.player getSceneFromScenePath:@"/init" result:^(WhiteScene * _Nullable scene) {
            XCTAssertNotNil(scene);
            [exp fulfill];
        }];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testGetSceneFail
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self setupPlayer];
    __weak typeof(self) weakSelf = self;
    self.loadFirstFrameBlock = ^{
        [weakSelf.player getSceneFromScenePath:@"/initA" result:^(WhiteScene * _Nullable scene) {
            XCTAssertNil(scene);
            [exp fulfill];
        }];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

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
//    NSLog(@"PlayerTest %s %ld", __FUNCTION__, (long)phase);
    if (phase == WhitePlayerPhasePlaying && self.playBlock) {
        self.playBlock();
    } else if (phase == WhitePlayerPhasePause && self.pauseBlock) {
        self.pauseBlock();
    }
}

- (void)loadFirstFrame
{
//    NSLog(@"PlayerTest %s", __FUNCTION__);
    if (self.loadFirstFrameBlock) {
        self.loadFirstFrameBlock();
    }
}

- (void)sliceChanged:(NSString *)slice
{
//    NSLog(@"PlayerTest %s slice:%@", __FUNCTION__, slice);
}

- (void)playerStateChanged:(WhitePlayerState *)modifyState
{
//    NSString *str = [modifyState jsonString];
//    NSLog(@"PlayerTest %s state:%@", __FUNCTION__, str);
}

- (void)stoppedWithError:(NSError *)error
{
//    NSLog(@"PlayerTest %s error:%@", __FUNCTION__, error);
    XCTFail(@"异常停止：%@", error.userInfo);
}

- (void)scheduleTimeChanged:(NSTimeInterval)time
{
//    NSLog(@"PlayerTest %s time:%f", __FUNCTION__, (double)time);
    if (self.seekBlock) {
        self.seekBlock(time);
    }
}

- (void)fireMagixEvent:(WhiteEvent *)event
{
    XCTAssertNotNil(event);
//    NSLog(@"fireMagixEvent: %@", event);
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
- (void)throwError:(NSError *)error
{
    XCTFail(@"调用出现报错：%@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url
{
    if (self.interrupterBlock) {
        self.interrupterBlock(url);
    }
    return url;
}

@end
