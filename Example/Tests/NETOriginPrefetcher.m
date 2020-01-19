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
    
    [prefetcher fetchOriginConfigs];
    
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

    self.fetchSuccessBlock = ^(NSDictionary * _Nonnull dict) {
        [prefetcher prefetchOrigins];
    };
    
    __weak typeof(self)weakSelf = self;
    self.prefetchBlock = ^(NSDictionary * _Nonnull result) {
        NSLog(@"result: %@", [result description]);
        [weakSelf.exp fulfill];
    };
    
    [prefetcher fetchOriginConfigs];
    
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

    [prefetcher fetchOriginConfigs];
    
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
    prefetcher.fetchConfigSuccessBlock = ^(NSDictionary * _Nonnull dict) {
        [weakPrefetcher prefetchOrigins];
    };
    
    weakPrefetcher.prefetchFinishBlock = ^(NSDictionary * _Nonnull result) {
        NSLog(@"result: %@", [result description]);
        [exp fulfill];
    };
    
    prefetcher.fetchConfigFailBlock = ^(NSError * _Nonnull err) {
        XCTFail(@"fetchConfigFail: %@", [err description]);
    };

    [prefetcher fetchOriginConfigs];
    
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)testSort {
    NSMutableArray *array = [@[@"2", @"1", @"0", @"6", @"5", @"4", @"3"] mutableCopy];
    
    NSDictionary *dict = @{@"4": @1, @"3": @0.6, @"2": @0.58, @"1": @0.2, @"0": @0.05};

    NSSet *keySet = [NSSet setWithArray:dict.allKeys];
    
    NSMutableSet *insertSet = [NSMutableSet setWithArray:array];
    [insertSet intersectSet:keySet];
        
    NSArray *sortedArray = [insertSet.allObjects sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSNumber *speed1 = dict[obj1];
        NSNumber *speed2 = dict[obj2];
        return [speed1 compare:speed2];
    }];
    
    NSMutableSet *minusSet = [NSMutableSet setWithArray:array];
    [minusSet minusSet:keySet];
    NSArray *result = [sortedArray arrayByAddingObjectsFromArray:minusSet.allObjects];
    
    [result enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XCTAssertEqual([obj integerValue], idx);
    }];
}

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

@end
