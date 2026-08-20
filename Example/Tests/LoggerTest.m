//
//  LoggerTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2023/11/6.
//  Copyright © 2023 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"
#import "Whiteboard.h"

@interface LocalLogCompatibilityTests : XCTestCase
@end

@implementation LocalLogCompatibilityTests

- (WhiteSdkConfiguration *)configurationWithPlatformUA:(NSString *)platformUA
{
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:@"test-app-id"];
    [config setValue:@{
        @"nativeVersion": @"test",
        @"platform": platformUA,
    } forKey:@"nativeTags"];
    return config;
}

- (void)testIOS12ForcesLocalLogOptionsDisabled
{
    WhiteSdkConfiguration *config = [self configurationWithPlatformUA:@"ios iPhone10,4 12.5.7"];
    WhiteLocalLogOptions *localLogOptions = [[WhiteLocalLogOptions alloc] init];
    localLogOptions.enabled = @YES;
    localLogOptions.enabledUpload = @YES;
    config.localLogOptions = localLogOptions;

    NSDictionary *localLog = [config jsonDict][@"loggerOptions"][@"localLog"];
    XCTAssertEqualObjects(localLog[@"enabled"], @NO);
    XCTAssertEqualObjects(localLog[@"enabledUpload"], @NO);
}

- (void)testIOS12ForcesLoggerOptionsLocalLogDisabled
{
    WhiteSdkConfiguration *config = [self configurationWithPlatformUA:@"ios iPad7,5 12.0"];
    config.loggerOptions = @{
        @"printLevelMask": WhiteSDKLoggerOptionLevelDebug,
        @"localLog": @{
            @"enabled": @YES,
            @"enabledUpload": @YES,
            @"customValue": @"preserved",
        },
    };

    NSDictionary *loggerOptions = [config jsonDict][@"loggerOptions"];
    NSDictionary *localLog = loggerOptions[@"localLog"];
    XCTAssertEqualObjects(localLog[@"enabled"], @NO);
    XCTAssertEqualObjects(localLog[@"enabledUpload"], @NO);
    XCTAssertEqualObjects(localLog[@"customValue"], @"preserved");
    XCTAssertEqualObjects(loggerOptions[@"printLevelMask"], WhiteSDKLoggerOptionLevelDebug);
}

- (void)testIOS13KeepsExplicitLocalLogConfiguration
{
    WhiteSdkConfiguration *config = [self configurationWithPlatformUA:@"ios iPhone12,1 13.0"];
    WhiteLocalLogOptions *localLogOptions = [[WhiteLocalLogOptions alloc] init];
    localLogOptions.enabled = @YES;
    localLogOptions.enabledUpload = @YES;
    config.localLogOptions = localLogOptions;

    NSDictionary *localLog = [config jsonDict][@"loggerOptions"][@"localLog"];
    XCTAssertEqualObjects(localLog[@"enabled"], @YES);
    XCTAssertEqualObjects(localLog[@"enabledUpload"], @YES);
}

- (void)testMalformedPlatformUAKeepsExplicitLocalLogConfiguration
{
    WhiteSdkConfiguration *config = [self configurationWithPlatformUA:@"unexpected-platform-value"];
    WhiteLocalLogOptions *localLogOptions = [[WhiteLocalLogOptions alloc] init];
    localLogOptions.enabled = @YES;
    localLogOptions.enabledUpload = @YES;
    config.localLogOptions = localLogOptions;

    NSDictionary *localLog = [config jsonDict][@"loggerOptions"][@"localLog"];
    XCTAssertEqualObjects(localLog[@"enabled"], @YES);
    XCTAssertEqualObjects(localLog[@"enabledUpload"], @YES);
}

- (void)testNativePlatformUAFollowsDeviceSystemVersion
{
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:@"test-app-id"];
    WhiteLocalLogOptions *localLogOptions = [[WhiteLocalLogOptions alloc] init];
    localLogOptions.enabled = @YES;
    localLogOptions.enabledUpload = @YES;
    config.localLogOptions = localLogOptions;

    BOOL expectedEnabled = UIDevice.currentDevice.systemVersion.integerValue > 12;
    NSDictionary *localLog = [config jsonDict][@"loggerOptions"][@"localLog"];
    XCTAssertEqualObjects(localLog[@"enabled"], @(expectedEnabled));
    XCTAssertEqualObjects(localLog[@"enabledUpload"], @(expectedEnabled));
}

@end

@interface RoomLoggerTest : BaseRoomTest<WhiteCommonCallbackDelegate>
@end

@implementation RoomLoggerTest
{
    XCTestExpectation* _currentExpectation;
}

- (void)roomVCDidSetup:(WhiteRoomViewController *)roomVC {
    [roomVC.sdk setCommonCallbackDelegate:self];
}

- (void)testConsoleLog {
    _currentExpectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

// MARK: - Delegate
- (void)logger:(NSDictionary *)dict {
    if ([self.name containsString:@"testConsoleLog"]) {
        if ([dict[@"[WhiteWKConsole]"] length] > 0) {
            [_currentExpectation fulfill];
            _currentExpectation = nil;
        }
    }
}

@end
