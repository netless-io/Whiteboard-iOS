//
//  SlideResourceMaxRetriesTests.m
//  Whiteboard_Tests
//
//  Created by Codex on 2026/3/24.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>

@interface SlideResourceMaxRetriesMockDelegate : NSObject<WhiteSlideDelegate>
@property (nonatomic, assign) BOOL didCallSlideResourceMaxRetries;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSError *error;
@end

@implementation SlideResourceMaxRetriesMockDelegate

- (void)onSlideResourceMaxRetries:(NSString *)url error:(NSError *)error
{
    self.didCallSlideResourceMaxRetries = YES;
    self.url = url;
    self.error = error;
}

@end

@interface SlideResourceMaxRetriesTests : XCTestCase
@end

@implementation SlideResourceMaxRetriesTests

- (void)testSlideAppParamsDefaultResourceMaxRetries
{
    WhiteSlideAppParams *params = [[WhiteSlideAppParams alloc] init];
    XCTAssertEqual(params.resourceMaxRetries.integerValue, 3);
}

- (void)testSdkConfigSlideAppOptionsDefaultResourceMaxRetries
{
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:@"test-app-id"];
    NSDictionary *dict = [config jsonDict];
    NSDictionary *slideAppOptions = dict[@"slideAppOptions"];

    XCTAssertNotNil(slideAppOptions);
    XCTAssertEqual([slideAppOptions[@"resourceMaxRetries"] integerValue], 3);
}

- (void)testSdkConfigSlideAppOptionsCustomResourceMaxRetries
{
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:@"test-app-id"];
    config.whiteSlideAppParams.resourceMaxRetries = @6;
    NSDictionary *dict = [config jsonDict];
    NSDictionary *slideAppOptions = dict[@"slideAppOptions"];

    XCTAssertNotNil(slideAppOptions);
    XCTAssertEqual([slideAppOptions[@"resourceMaxRetries"] integerValue], 6);
}

- (void)testSlideResourceMaxRetriesCallback
{
    WhiteCommonCallbacks *callbacks = [[WhiteCommonCallbacks alloc] init];
    SlideResourceMaxRetriesMockDelegate *slideDelegate = [[SlideResourceMaxRetriesMockDelegate alloc] init];
    callbacks.slideDelegate = slideDelegate;

    NSString *url = @"https://example.com/1.png";
    NSString *message = @"network failed";
    NSString *jsStack = @"Error: network failed\\n at load()";
    NSDictionary *payload = @{@"url": url, @"message": message, @"jsStack": jsStack};

    SEL selector = NSSelectorFromString(@"slideResourceMaxRetries:");
    XCTAssertTrue([callbacks respondsToSelector:selector]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [callbacks performSelector:selector withObject:payload];
#pragma clang diagnostic pop

    XCTAssertTrue(slideDelegate.didCallSlideResourceMaxRetries);
    XCTAssertEqualObjects(slideDelegate.url, url);
    XCTAssertNotNil(slideDelegate.error);
    XCTAssertEqualObjects(slideDelegate.error.localizedDescription, message);
    XCTAssertEqualObjects(slideDelegate.error.userInfo[NSDebugDescriptionErrorKey], jsStack);
}

@end
