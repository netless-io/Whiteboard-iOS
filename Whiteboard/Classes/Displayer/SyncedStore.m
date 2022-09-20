//
//  SyncedStore.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/14.
//

#import "SyncedStore.h"
#import "WhiteConsts.h"
#import "WhiteBoardView.h"
#import "SyncedStore+Private.h"
#import "NSObject+YY.h"

@protocol SyncedStoreCallbackDelegate <NSObject>
- (void)fireSyncedStoreUpdate:(NSString *)jsonString;
@end
@interface SyncedStoreCallback : NSObject
@property (weak, nonatomic) id<SyncedStoreCallbackDelegate> delegate;
- (id)fireSyncedStoreUpdate:(NSString *)jsonString;
@end
@implementation SyncedStoreCallback
- (id)fireSyncedStoreUpdate:(NSString *)jsonString {
    [self.delegate fireSyncedStoreUpdate:jsonString];
    return nil;
}
@end

static NSString * const kSyncSyncedStoreNameSpace = @"store.%@";
static NSString * const kAsyncSyncedStoreNameSpace = @"store.%@";

@interface SyncedStore ()<SyncedStoreCallbackDelegate>

@property (nonatomic, strong) SyncedStoreCallback* callback;

@end

@implementation SyncedStore

- (instancetype)init {
    if (self = [super init]) {
        self.callback = [SyncedStoreCallback new];
        self.callback.delegate = self;
    }
    return self;
}

- (void)setBridge:(WhiteBoardView *)bridge {
    _bridge = bridge;
    [bridge addJavascriptObject:self.callback namespace:@"store"];
}

- (void)fireSyncedStoreUpdate:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *name = dict[@"name"];
    if (name) {
        [self.delegate syncedStoreDidUpdateStoreName:name partialValue:dict[@"data"]];
    }
}

// MARK: - Bridge
- (void)connectSyncedStoreStorage:(NSString *)name defaultValue:(NSDictionary *)defaultValue completionHandler:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionHandler {
    [self.bridge callHandler:[NSString stringWithFormat:kAsyncSyncedStoreNameSpace, @"connectStorage"] arguments:@[name, defaultValue] completionHandler:^(id  _Nullable value) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSDictionary *error = dict[@"__error"];
        if (error) {
            NSString *desc = error[@"message"] ? : @"";
            NSString *description = error[@"jsStack"] ? : @"";
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: desc, NSDebugDescriptionErrorKey: description};
            completionHandler(nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-1000 userInfo:userInfo]);
        } else {
            completionHandler(dict, nil);
        }
    }];
}

- (void)getStorageState:(NSString *)name completionHandler:(void (^)(NSDictionary * _Nullable))completionHandler {
    [self.bridge callHandler:[NSString stringWithFormat:kAsyncSyncedStoreNameSpace, @"getStorageState"] arguments:@[name] completionHandler:^(id  _Nullable value) {
        if ([value isKindOfClass:[NSString class]]) {
            NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            completionHandler(dict);
        } else {
            completionHandler(nil);
        }
    }];
}

- (void)disconnectStorage:(NSString *)name {
    [self.bridge callHandler:[NSString stringWithFormat:kSyncSyncedStoreNameSpace, @"disconnectStorage"] arguments:@[name]];
}

- (void)deleteStorage:(NSString *)name {
    [self.bridge callHandler:[NSString stringWithFormat:kSyncSyncedStoreNameSpace, @"deleteStorage"] arguments:@[name]];
}

- (void)resetState:(NSString *)name {
    [self.bridge callHandler:[NSString stringWithFormat:kSyncSyncedStoreNameSpace, @"resetState"] arguments:@[name]];
}

- (void)setStorageState:(NSString *)name partialState:(NSDictionary *)partialState {
    [self.bridge callHandler:[NSString stringWithFormat:kSyncSyncedStoreNameSpace, @"setStorageState"] arguments:@[name, partialState]];
}

@end
