//
//  NETOriginPrefetcher.m
//  Whiteboard_Tests
//
//  Created by yleaf on 2020/1/26.
//  Copyright © 2020 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/WhiteOriginPrefetcher.h>


@interface NETOriginPrefetcher : XCTestCase<WhiteOriginPrefetcherDelegate>

@property (nonatomic, nullable, strong) XCTestExpectation *exp;

@property (nonatomic, nullable, copy) FetchConfigSuccessBlock fetchSuccessBlock;
@property (nonatomic, nullable, copy) PrefetchFinishBlock prefetchBlock;

@end

@implementation NETOriginPrefetcher

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    // 一个 XCTestCase 只会启动一次设备，使用单例对测试有影响，需要全部移除掉。
    [WhiteOriginPrefetcher shareInstance].prefetchDelgate = nil;
    
    [WhiteOriginPrefetcher shareInstance].fetchConfigSuccessBlock = nil;
    [WhiteOriginPrefetcher shareInstance].fetchConfigFailBlock = nil;
    [WhiteOriginPrefetcher shareInstance].prefetchFinishBlock = nil;
    
    self.fetchSuccessBlock = nil;
    self.prefetchBlock = nil;
}

static CGFloat kTimeout = 30;

#pragma mark - Delgate Tests
- (void)testFetchConfigDelegate {
    self.exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    WhiteOriginPrefetcher *prefetcher = [WhiteOriginPrefetcher shareInstance];
    prefetcher.prefetchDelgate = self;

    __weak typeof(self)weakSelf = self;
    self.fetchSuccessBlock = ^(NSDictionary * _Nonnull dict) {
        [weakSelf.exp fulfill];
    };
    
    [prefetcher fetchConfigAndPrefetchDomains];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testFetchFinishDelegate {
    self.exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    WhiteOriginPrefetcher *prefetcher = [WhiteOriginPrefetcher shareInstance];
    prefetcher.prefetchDelgate = self;
    
    __weak typeof(self)weakSelf = self;
    self.prefetchBlock = ^(NSDictionary * _Nonnull result) {
        
        if ([weakSelf diffDict:result source:prefetcher.sdkStructConfig]) {
            id self = weakSelf;
            XCTFail(@"config fail");
        }
        
        [weakSelf.exp fulfill];
    };
    
    [prefetcher fetchConfigAndPrefetchDomains];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}


#pragma mark - Callback Tests
- (void)testFetchCallback {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    WhiteOriginPrefetcher *prefetcher = [WhiteOriginPrefetcher shareInstance];
    
    prefetcher.fetchConfigSuccessBlock = ^(NSDictionary * _Nonnull dict) {
        [exp fulfill];
    };
    
    prefetcher.fetchConfigFailBlock = ^(NSError * _Nonnull err) {
        XCTFail(@"fetchConfigFail: %@", [err description]);
    };

    [prefetcher fetchConfigAndPrefetchDomains];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testPrefetchCallback {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    WhiteOriginPrefetcher *prefetcher = [WhiteOriginPrefetcher shareInstance];
    
    __weak typeof(prefetcher)weakPrefetcher = prefetcher;
    __weak typeof(self)weakSelf = self;
    weakPrefetcher.prefetchFinishBlock = ^(NSDictionary * _Nonnull result) {
        
        if ([weakSelf diffDict:result source:prefetcher.sdkStructConfig]) {
            XCTFail(@"config fail");
        }
        
        [exp fulfill];
    };
    
    prefetcher.fetchConfigFailBlock = ^(NSError * _Nonnull err) {
        XCTFail(@"fetchConfigFail: %@", [err description]);
    };

    [prefetcher fetchConfigAndPrefetchDomains];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

#pragma mark - Hook test

#pragma mark - WhiteOriginPrefetcherDelegate

- (void)originPrefetcherFetchOriginConfigsFail:(NSError *)error {
    if (self.exp) {
        XCTFail(@"originPrefetcherFetchOriginConfigsFail: %@", [error localizedDescription]);
    }
}

- (void)originPrefetcherFetchOriginConfigsSuccess:(NSDictionary *)dict {
    if (self.fetchSuccessBlock) {
        self.fetchSuccessBlock(dict);
    }
}

- (void)originPrefetcherFinishPrefetch:(NSDictionary *)result
{
    if (self.prefetchBlock) {
        self.prefetchBlock(result);
    }
}

#pragma mark - Private
- (BOOL)diffDict:(NSDictionary *)target source:(NSDictionary *)source
{
    __block BOOL diff = NO;
    [target enumerateKeysAndObjectsUsingBlock:^(NSString *key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"origins"]) {
            id comparison = source[key];
            if (![comparison isKindOfClass:[NSDictionary class]] || [self diffOrigins:obj source:comparison]) {
                diff = YES;
                *stop = YES;
            }
        } else if ([obj isKindOfClass:[NSString class]]) {
            id comparison = source[key];
            if (![comparison isKindOfClass:[NSString class]] || ![obj isEqualToString:comparison]) {
                diff = YES;
                *stop = YES;
            }
        } else if ([obj isKindOfClass:[NSArray class]]) {
            id comparison = source[key];
            if (![comparison isKindOfClass:[NSArray class]] || [self diffArray:obj source:comparison]) {
                diff = YES;
                *stop = YES;
            }
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            id comparison = source[key];
            if (![comparison isKindOfClass:[NSDictionary class]] || [self diffDict:obj source:comparison]) {
                diff = YES;
                *stop = YES;
            }
        }
    }];
    
    return diff;
}

- (BOOL)diffOrigins:(NSDictionary<NSString *, NSArray *> *)target source:(NSDictionary<NSString *, NSArray *> *)source
{
    __block BOOL diff = NO;
    
    [target enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray *diffArray = source[key];
        if ([obj count] != [diffArray count]) {
            diff = YES;
            *stop = YES;
        }
        [obj enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *host = diffArray[idx];
            if (![obj[@"origin"] isEqualToString:host]) {
                diff = YES;
                *stop = YES;
            }
        }];
    }];
    
    return diff;
}

- (BOOL)diffArray:(NSArray *)target source:(NSArray *)source
{
    if ([target count] != [source count]) {
        return YES;
    }
    __block BOOL diff = NO;
    [target enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger result = [source indexOfObject:obj];
        if (result == NSNotFound) {
            diff = YES;
            *stop = YES;
        }
    }];
    return diff;
}

@end
