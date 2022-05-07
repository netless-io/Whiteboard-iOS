//
//  CombinePlayerTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/5/6.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WhitePlayerViewController.h"
#import "TestUtility.h"

@interface WhitePlayerViewController ()
@property (nonatomic, nullable, strong) WhiteCombinePlayer *combinePlayer;
@end

@interface CombinePlayerOnlyVideoTest : XCTestCase<WhiteCombineDelegate>
@property (nonatomic, strong) WhitePlayerViewController *playerVC;
@property (nonatomic, copy) void(^combinePlayingBlock)(BOOL);
@end

@implementation CombinePlayerOnlyVideoTest

- (void)setUp {
    self.playerVC = [self createPlayerVC];
    [self pushPlayerVC];
}

- (void)tearDown {
    [self.playerVC.combinePlayer.whitePlayer stop];
    [self popToRoot];
}

- (void)testPlay {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.playerVC.playBlock = ^(WhiteCombinePlayer * _Nullable player, NSError * _Nullable eroror) {
        weakSelf.playerVC.combinePlayer.delegate = weakSelf;
        weakSelf.combinePlayingBlock = ^(BOOL playing) {
            if (playing) {
                [exp fulfill];
            }
        };
        [player play];
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testPause {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    __weak typeof(self) weakSelf = self;
    self.playerVC.playBlock = ^(WhiteCombinePlayer * _Nullable player, NSError * _Nullable eroror) {
        weakSelf.playerVC.combinePlayer.delegate = weakSelf;
        [player play];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.combinePlayingBlock = ^(BOOL playing) {
                if (!playing) {
                    [exp fulfill];
                }
            };
            [player pause];
        });
    };
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

#pragma mark - Prepare

- (void)pushPlayerVC {
    //Webview 在视图栈中才能正确执行 js
    __unused UIView *view = [self.playerVC view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.playerVC animated:YES];
    }
}

- (void)popToRoot {
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
   if ([nav isKindOfClass:[UINavigationController class]]) {
       [nav popToRootViewControllerAnimated:YES];
   }
}

- (WhitePlayerViewController *)createPlayerVC
{
    WhitePlayerViewController *vc = [[WhitePlayerViewController alloc] init];
    vc.roomUuid = WhiteReplayRoomUUID;
    vc.ignoreWhitePlayer = YES;
    return vc;
}

#pragma mark - Delegate
- (void)combineVideoPlayStateChange:(BOOL)isPlaying
{
    if (self.combinePlayingBlock) {
        self.combinePlayingBlock(isPlaying);
    }
}

@end
