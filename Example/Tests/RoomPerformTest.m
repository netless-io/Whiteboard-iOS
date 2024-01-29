//
//  RoomPerformTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2024/1/26.
//  Copyright © 2024 leavesster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"
#import "TestUtility.h"
#import <mach/mach.h>

@interface RoomPerformTest: XCTestCase<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate>

@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoom *room;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;

@end

@interface TestVC : UIViewController
@end
@implementation TestVC

@end

@implementation RoomPerformTest

- (void)setUp {
    [super setUp];
    self.roomConfig = [self createNewNewConfig];
}

- (void)testJoinRoomConsuming {
    self.roomVC = [self createNewRoomVC];
    self.roomVC.delayJoinRoom = YES;
    [self pushVC: self.roomVC];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDate *beginTime = [NSDate new];
        [self.roomVC performSelector:NSSelectorFromString(@"joinExistRoom")];
        self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
            NSDate *endTime = [NSDate new];
            NSTimeInterval elapse = [endTime timeIntervalSinceDate:beginTime];
            NSLog(@"join room elapse %f", elapse);
            [exp fulfill];
        };
    });
    [self waitForExpectations:@[exp] timeout:999];
}

- (void)testWhiteboardViewMemoryConsuming {
    UIViewController *testVC = [TestVC new];
    [self pushVC:testVC];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        int64_t m1 = [self memoryUsage];
        WhiteBoardView *whiteboardView = [[WhiteBoardView alloc] init];
        [testVC.view addSubview:whiteboardView];
        whiteboardView.frame = CGRectMake(0, 0, 414, 414);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            int64_t m2 = [self memoryUsage];
            int64_t delta = m2 - m1;
            double deltaMb = (double)delta / 1024 / 1024;
            NSLog(@"memory delta is %f mb", deltaMb);
        });
    });
    
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self waitForExpectations:@[exp] timeout:999];
}

- (int64_t)memoryUsage {
    int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
        NSLog(@"Memory in use (in bytes): %lld", memoryUsageInByte);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kernelReturn));
    }
    return memoryUsageInByte;
}

- (void)pushVC:(UIViewController *)vc {
    //Webview 在视图栈中才能正确执行 js
    __unused UIView *view = [vc view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:vc animated:NO];
    }
}

- (WhiteRoomConfig *)createNewNewConfig
{
    NSDictionary *payload = @{@"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg", @"userId": @1024};
    WhiteRoomConfig *config = [[WhiteRoomConfig alloc] initWithUUID:WhiteRoomUUID roomToken:WhiteRoomToken uid:@"1"];
    config.userPayload = payload;
    config.windowParams = [[WhiteWindowParams alloc] init];
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
