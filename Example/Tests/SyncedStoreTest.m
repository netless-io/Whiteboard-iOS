//
//  SyncedStoreTest
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/7/14.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "BaseRoomTest.h"

NS_ASSUME_NONNULL_BEGIN

@interface SyncedStoreTest: BaseRoomTest <SyncedStoreUpdateCallBackDelegate>
@property (nonatomic, copy, nullable) void(^updateBlock)(NSString* name, NSDictionary* dict);
@end

@implementation SyncedStoreTest

static NSString* storeName = @"test";

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig {
    sdkConfig.enableSyncedStore = YES;
}

- (void)setUp {
    [super setUp];
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [[self.room obtainSyncedStore] connectSyncedStoreStorage:storeName defaultValue:@{@"name": @"default"} completionHandler:^(NSDictionary * _Nullable dict, NSError * _Nullable error) {
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testGetStorage {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [[self.room obtainSyncedStore] getStorageState:storeName completionHandler:^(NSDictionary * _Nullable dict) {
        XCTAssertNotNil(dict);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testDisconnectStorage {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [[self.room obtainSyncedStore] disconnectStorage:storeName];
    [[self.room obtainSyncedStore] getStorageState:storeName completionHandler:^(NSDictionary * _Nullable dict) {
        XCTAssertTrue(dict.count <= 0);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testDeleteStorage {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [[self.room obtainSyncedStore] deleteStorage:storeName];
    [[self.room obtainSyncedStore] getStorageState:storeName completionHandler:^(NSDictionary * _Nullable dict) {
        XCTAssertTrue(dict.count <= 0);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testSetState {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSString* randomValue = [[NSUUID UUID] UUIDString];
    [[self.room obtainSyncedStore] setStorageState:storeName partialState:@{@"name": randomValue}];
    [[self.room obtainSyncedStore] getStorageState:storeName completionHandler:^(NSDictionary * _Nullable dict) {
        XCTAssertTrue([dict[@"name"] isEqualToString:randomValue]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testResetState {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [[self.room obtainSyncedStore] setStorageState:storeName partialState:@{@"name": @"aaa"}];
    [[self.room obtainSyncedStore] resetState:storeName];
    [[self.room obtainSyncedStore] getStorageState:storeName completionHandler:^(NSDictionary * _Nullable dict) {
        XCTAssertTrue([dict[@"name"] isEqualToString:@"default"]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testDelegateNew {
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.room obtainSyncedStore].delegate = self;
    NSString* random = [[NSUUID UUID] UUIDString];
    // set new
    self.updateBlock = ^(NSString * _Nonnull name, NSDictionary * _Nonnull dict) {
        XCTAssertTrue([name isEqualToString:storeName]);
        XCTAssertTrue([dict[@"name"][@"newValue"] isEqualToString:random]);
        
        [exp fulfill];
    };
    [[self.room obtainSyncedStore] setStorageState:storeName partialState:@{@"name": random}];
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)testDelegateNull {
    // set null
    XCTestExpectation *exp = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [[self.room obtainSyncedStore] resetState:storeName];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.room obtainSyncedStore].delegate = self;
        self.updateBlock = ^(NSString * _Nonnull name, NSDictionary * _Nonnull dict) {
            XCTAssertTrue([name isEqualToString:storeName]);
            XCTAssertTrue([dict[@"name"][@"newValue"] isEqual:[NSNull null]]);
            [exp fulfill];
        };
        [[self.room obtainSyncedStore] setStorageState:storeName partialState:@{@"name": [NSNull null]}];
    });
    [self waitForExpectationsWithTimeout:kTimeout handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s error: %@", __FUNCTION__, error);
        }
    }];
}

- (void)syncedStoreDidUpdateStoreName:(NSString *)name partialValue:(NSDictionary *)partialValue {
    if (self.updateBlock) {
        self.updateBlock(name, partialValue);
        self.updateBlock = nil;
    }
}

@end

NS_ASSUME_NONNULL_END
