//
//  CustomAppTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/28.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

@interface CustomAppTest : BaseRoomTest
@end

@implementation CustomAppTest

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
    [self.roomVC.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
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
    [self.roomVC.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
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
    [self.roomVC.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        XCTAssertTrue(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}
@end
