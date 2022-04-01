//
//  ConverterV5Test.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/2/23.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "Tests-Prefix.pch"

static NSString * const exampleTaskUUID = @"fddaeb908e0b11ecb94f39bd66b92986";
static NSString * const exampleTaskToken = @"NETLESSTASK_YWs9NWJod2NUeXk2MmRZWC11WiZub25jZT1mZTFlZjk3MC04ZTBiLTExZWMtYTMzNS01MWEyMGJkNzRiZjYmcm9sZT0yJnNpZz1jZGQwMzMyZTFlZTkwNGEyNjhlMjQ0NDc0NWQ4MTY0ZTAzNzNiOTIxZmI4ZDY0YTE0MTJiZTU5MmUwMjM3MzM4JnV1aWQ9ZmRkYWViOTA4ZTBiMTFlY2I5NGYzOWJkNjZiOTI5ODY";

static NSString * const pdfFileURL = @"https://flat-storage.oss-accelerate.aliyuncs.com/cloud-storage/2022-02/15/09faea1a-42f2-4ef6-a40d-7866cc5e1104/09faea1a-42f2-4ef6-a40d-7866cc5e1104.pdf";


@interface Foo : NSObject
@property (nonatomic, strong) WhiteConverterV5 *converter;
@end
@implementation Foo
- (instancetype)init {
    self = [super init];
    self.converter = [[WhiteConverterV5 alloc] init];
    return self;
}
@end

@interface ConverterV5Test : XCTestCase
@property (nonatomic, strong) Foo *foo;
@end

@implementation ConverterV5Test

- (void)setUp
{
    [super setUp];
    _foo = [[Foo alloc] init];
}
- (void)tearDown
{
    [super tearDown];
    [self.foo.converter endPolling];
    self.foo = nil;
}

#pragma mark - Test LifeCycle
- (void)testConverterDealloc
{
    __weak WhiteConverterV5 *obj = self.foo.converter;
    [self.foo.converter startPolling];
    [self.foo.converter endPolling];
    self.foo = nil;
    XCTAssertNil(obj);
}

#pragma mark - Test Task
- (void)testConvertFile
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self createTaskWithToken:WhiteSDKToken
                       region:WhiteRegionCN
                     resource:pdfFileURL
                         type:WhiteConvertTypeStatic
            completionHandler:^(NSString *taskUUID, NSString *taskToken, NSError *error) {
        [self.foo.converter insertPollingTaskWithTaskUUID:taskUUID
                                                    token:taskToken
                                                   region:WhiteRegionCN
                                                 taskType:WhiteConvertTypeStatic
                                                 progress:^(CGFloat progress, WhiteConversionInfoV5 * _Nullable info) {
            NSLog(@"progress, %f", progress);
        } result:^(BOOL success, WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
            NSLog(@"convert %d", success);
            if (success) {
                [exp fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:120 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testCancelTask
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self createTaskWithToken:WhiteSDKToken
                       region:WhiteRegionCN
                     resource:pdfFileURL
                         type:WhiteConvertTypeStatic
            completionHandler:^(NSString *taskUUID, NSString *taskToken, NSError *error) {
        if (error) {
            XCTAssertNil(error);
            [exp fulfill];
            return;
        }
        [self.foo.converter insertPollingTaskWithTaskUUID:taskUUID
                                                    token:taskToken
                                                   region:WhiteRegionCN
                                                 taskType:WhiteConvertTypeStatic
                                                 progress:^(CGFloat progress, WhiteConversionInfoV5 * _Nullable info) {
            XCTAssertNil(@"Should not progress");
        } result:^(BOOL success, WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
            XCTAssertNil(@"Should not success");
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.foo.converter cancelPollingTaskWithTaskUUID:taskUUID];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [exp fulfill];
        });
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testErrorUUIDTask
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.foo.converter insertPollingTaskWithTaskUUID:@"xxxxxx"
                                                token:exampleTaskToken
                                               region:WhiteRegionCN
                                             taskType:WhiteConvertTypeStatic
                                             progress:^(CGFloat progress, WhiteConversionInfoV5 * _Nullable info) {
        XCTAssert(@"Should not progress");
    } result:^(BOOL success, WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
        if (error) {
            [exp fulfill];
        } else {
            XCTAssert(@"Should not success");
        }
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)testPausePolling
{
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    self.foo.converter = [[WhiteConverterV5 alloc] initWithPollingTimeinterval:1];
    [self.foo.converter insertPollingTaskWithTaskUUID:exampleTaskUUID
                                                token:exampleTaskToken
                                               region:WhiteRegionCN
                                             taskType:WhiteConvertTypeStatic
                                             progress:^(CGFloat progress, WhiteConversionInfoV5 * _Nullable info) {
        XCTAssert(@"Should not progress");
    } result:^(BOOL success, WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
        XCTAssert(@"Should not result");
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.foo.converter pausePolling];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

#pragma mark - CreateTask
- (void)createTaskWithToken:(NSString *)token
                     region:(WhiteRegionKey)region
                   resource:(NSString *)resource
                       type:(WhiteConvertTypeV5)type
          completionHandler: (void(^)(NSString * taskUUID, NSString * taskToken , NSError * error))completionHandler
{
    NSString *questUrl = @"https://api.netless.link/v5/services/conversion/tasks";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:questUrl]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:region forHTTPHeaderField:@"region"];
    [request addValue:token forHTTPHeaderField:@"token"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"resource": resource, @"type": type} options:0 error:nil];
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 5;

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, nil, error);
            return;
        }
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *uuid = responseObject[@"uuid"];
        if (uuid) {
            [self createTaskTokenWithToken:token region:region uuid:uuid completionHandler:^(NSString *taskToken, NSError *taskTokenError) {
                if (taskTokenError) {
                    completionHandler(nil, nil, taskTokenError);
                    return;
                }
                NSLog(@"Create task success, id %@, token %@", uuid, token);
                completionHandler(uuid, taskToken, nil);
                return;
            }];
        } else {
            completionHandler(nil, nil, [NSError new]);
        }
    }];
    [task resume];
}
- (void)createTaskTokenWithToken:(NSString *)token
                          region:(WhiteRegionKey)region
                            uuid:(NSString *)uuid
               completionHandler:(void(^)(NSString * taskToken, NSError * error))completionHandler
{
    NSString *questUrl = [NSString stringWithFormat:@"https://api.netless.link/v5/tokens/tasks/%@", uuid];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:questUrl]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:region forHTTPHeaderField:@"region"];
    [request addValue:token forHTTPHeaderField:@"token"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"lifespan": @600000, @"role": @"reader"} options:0 error:nil];
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }
        NSString *taskToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (taskToken) {
            taskToken = [taskToken stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            completionHandler(taskToken, nil);
        }
    }];
    [task resume];
}
@end
