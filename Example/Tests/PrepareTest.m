//
//  PrepareTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2024/4/18.
//  Copyright © 2024 leavesster. All rights reserved.
//

#import "XCTest/XCTest.h"
#import "Whiteboard.h"
#import "TestUtility.h"

@interface PrepareTest : XCTestCase

@end

@implementation PrepareTest

- (void)setUp {
    [super setUp];
    @autoreleasepool {
        WhiteBoardView *wb = [WhiteBoardView new];
        [UIApplication.sharedApplication.keyWindow addSubview:wb];
        WKUserScript *s = [[WKUserScript alloc] initWithSource:@"localStorage.removeItem('white-prefer-gateway')" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [wb.configuration.userContentController addUserScript:s];
        XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [wb removeFromSuperview];
            [exp fulfill];
        });
    }
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
    }];
}

- (void)testPrepare {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    @autoreleasepool {
        WhiteBoardView *wb = [WhiteBoardView new];
        [UIApplication.sharedApplication.keyWindow addSubview:wb];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [wb evaluateJavaScript:@"localStorage.getItem('white-prefer-gateway')" completionHandler:^(id _Nullable v, NSError * _Nullable error) {
                BOOL isNull = [v isKindOfClass:[NSNull class]];
                XCTAssertTrue(isNull);
                
                [WhiteSDK prepareForAppId:@"asdf/sdf" region:WhiteRegionCN expireSeconds:nil attachingSuperView:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [wb evaluateJavaScript:@"localStorage.getItem('white-prefer-gateway')" completionHandler:^(id _Nullable v, NSError * _Nullable error) {
                        BOOL isNull = [v isKindOfClass:[NSNull class]];
                        XCTAssertTrue(!isNull);
                        
                        [exp fulfill];
                    }];
                });
            }];
        });
    }
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
    }];
}

@end
