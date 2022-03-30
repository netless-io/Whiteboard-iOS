//
//  BaseRoomTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/30.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

@implementation BaseRoomTest

- (void)setUp
{
    [super setUp];
    self.continueAfterFailure = NO;

    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    self.roomConfig = [self createNewNewConfig];
    [self roomConfigDidSetup:self.roomConfig];
    self.roomVC = [self createNewRoomVC];
    [self sdkConfigDidSetup:self.roomVC.sdkConfig];
    [self roomVCDidSetup:self.roomVC];
    
    [self pushRoomVC];
    
    __weak typeof(self)weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom *room, NSError *error) {
        weakSelf.room = room;
        XCTAssertEqual(weakSelf.roomVC.roomConfig.isWritable, room.isWritable, @"roomVC writable is :%d room writbale is :%d", weakSelf.roomVC.roomConfig.isWritable, room.isWritable);
        XCTAssertNotNil(room);
        [exp fulfill];
    };

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)roomVCDidSetup:(WhiteRoomViewController *)roomVC;
{
}

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig
{
}

- (void)roomConfigDidSetup:(WhiteRoomConfig *)config
{
}

- (void)tearDown
{
    if (self.room.phase == WhiteRoomPhaseDisconnected) {
        [self popToRoot];
        [super tearDown];
        return;
    }
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [self.room disconnect:^{
        [self popToRoot];
        [exp fulfill];
        [super tearDown];
    }];

    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - Prepare

- (void)pushRoomVC {
    //Webview 在视图栈中才能正确执行 js
    __unused UIView *view = [self.roomVC view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.roomVC animated:YES];
    }
}

- (void)popToRoot {
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
   if ([nav isKindOfClass:[UINavigationController class]]) {
       [nav popToRootViewControllerAnimated:YES];
   }
}

- (WhiteRoomConfig *)createNewNewConfig
{
    NSDictionary *payload = @{@"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg", @"userId": @1024};
    WhiteRoomConfig *config = [[WhiteRoomConfig alloc] initWithUUID:WhiteRoomUUID roomToken:WhiteRoomToken uid:@"1"];
    return config;
}

- (WhiteRoomViewController *)createNewRoomVC
{
    WhiteRoomViewController *vc = [[WhiteRoomViewController alloc] init];
    vc.roomCallbackDelegate = self;
    vc.commonDelegate = self;
    vc.roomConfig = self.roomConfig;
    return vc;
}

@end
