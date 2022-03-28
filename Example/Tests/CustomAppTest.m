//
//  CustomAppTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/28.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"
#import <YYModel/YYModel.h>

static NSTimeInterval kTimeout = 300;
//static NSTimeInterval kTimeout = 30;

@interface CustomAppTest : XCTestCase
@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;
@end

@implementation CustomAppTest

- (void)setUp
{
    [super setUp];
    [self refreshRoomVC];
}

- (void)testRegisterLocalApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    NSString* kind = @"Monaco";
    NSString* jsPath = [[NSBundle mainBundle] pathForResource:@"monaco.iife" ofType:@"js"];
    NSString* jsString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:nil];
    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithJavascriptString:jsString
                                                  kind:kind
                                            appOptions:@{}
                                              variable:@"NetlessAppMonaco.default"];
    
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
       [weakSelf.roomVC.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
           XCTAssertNil(error);
           [exp fulfill];
       }];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testRegisterRemoteApp
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    NSString* kind = @"Monaco";
    WhiteRegisterAppParams* params = [WhiteRegisterAppParams
                                      paramsWithUrl:@"https://cdn.jsdelivr.net/npm/@netless/app-monaco@0.1.13-beta.0/dist/main.iife.js"
                                      kind:kind
                                      appOptions:@{}];
    
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
       [weakSelf.roomVC.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
           XCTAssertNil(error);
           [exp fulfill];
       }];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testRegisterFail
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    
    NSString* kind = @"Monaco";
    NSString* jsPath = [[NSBundle mainBundle] pathForResource:@"monaco.iife" ofType:@"js"];
    NSString* jsString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:nil];
    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithJavascriptString:jsString
                                                  kind:kind
                                            appOptions:@{}
                                              variable:@"bad_variable"];
    
    __weak typeof(self) weakSelf = self;
    self.roomVC.roomBlock = ^(WhiteRoom * _Nullable room, NSError * _Nullable eroror) {
       [weakSelf.roomVC.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
           XCTAssertTrue(error);
           [exp fulfill];
       }];
    };
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)refreshRoomVC
{
    _roomVC = [[WhiteRoomViewController alloc] init];
    _roomVC.useMultiViews = YES;
    _roomVC.roomConfig = self.roomConfig;
    //Webview 在视图栈中才能正确执行 js
    __unused UIView *view = [self.roomVC view];
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    [nav popToRootViewControllerAnimated:NO];
    if ([nav isKindOfClass:[UINavigationController class]]) {
        [nav pushViewController:self.roomVC animated:YES];
    }
}

- (WhiteRoomConfig *)roomConfig
{
    if (!_roomConfig) {
        _roomConfig = [[WhiteRoomConfig alloc] initWithUUID:WhiteRoomUUID roomToken:WhiteRoomToken uid:@"1"];
    }
    return _roomConfig;
}
@end
