//
//  WhiteSDK+Room.m
//  WhiteSDK
//
//  Created by yleaf on 2019/12/10.
//

#import "WhiteSDK+Room.h"
#import "WhiteSDK+Private.h"
#import "WhiteSdkConfiguration.h"
#import "WhiteBoardView+Private.h"
#import "WhiteConsts.h"
#import "WhiteRoom+Private.h"
#import "WhiteRoomCallbacks+Private.h"
#import "WhiteRoom.h"

#if DEBUG
#import "WritableDetectRoom.h"
#endif


@implementation WhiteSDK (Room)

#pragma mark - Room API

- (void)joinRoomWithConfig:(WhiteRoomConfig *)config callbacks:(nullable id<WhiteRoomCallbackDelegate>)callbacks completionHandler:(void (^) (BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error))completionHandler
{
    NSAssert([config.roomToken length] > 0 && [config.uuid length] > 0, NSLocalizedString(@"room uuid 和 token 不能为空", nil));
    
    if (!config.uuid.length || !config.roomToken.length || !config.uid.length) {
        if (completionHandler) completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-1100 userInfo:@{NSLocalizedDescriptionKey: @"InvalidJoinParameters"}]); return;
    }
    NSDictionary *sdkParameters = [NSJSONSerialization JSONObjectWithData:[self.config.jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:[config.jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSString *identity = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[sdkParameters[@"appIdentifier"] ?: @"", parameters[@"uuid"], parameters[@"uid"]] options:0 error:nil] encoding:NSUTF8StringEncoding];
    [self.bridge whiteReplaceRoom:identity configuration:sdkParameters timeout:[parameters[@"timeout"] doubleValue] / 1000.0 bind:^{
        [self whiteBindCommonCallback];
    } start:^(NSNumber *generation) {
        [self whiteJoinRoomAfterReplacement:parameters generation:generation callbacks:callbacks completionHandler:completionHandler];
    } failure:^(NSError *error) { if (completionHandler) completionHandler(NO, nil, error); }];
}

- (void)whiteJoinRoomAfterReplacement:(NSDictionary *)parameters generation:(NSNumber *)generation callbacks:(id<WhiteRoomCallbackDelegate>)callbacks completionHandler:(void (^)(BOOL, WhiteRoom *, NSError *))completionHandler {
    if (![self.bridge whiteContinueJoin:generation cancellation:^(NSError *error) { if (completionHandler) completionHandler(NO, nil, error); }]) return;
    WhiteBoardView *scopedBridge = [self.bridge whiteScopedBridge:generation];
    //从 WhiteBoardView 父类中解耦
    if (!self.bridge.roomCallbacks) {
        WhiteRoomCallbacks *roomCallbacks = [[WhiteRoomCallbacks alloc] init];
        self.bridge.roomCallbacks = roomCallbacks;
        [self.bridge addJavascriptObject:roomCallbacks namespace:@"room"];
    }

    
    self.bridge.roomCallbacks.delegate = callbacks;
    self.bridge.commonCallbacks.roomDelegate = callbacks;
    __weak typeof(self.bridge)weakBridge = self.bridge;
    WhiteRoom *room = [[WhiteRoom alloc] initWithUuid:parameters[@"uuid"] bridge:scopedBridge];
    self.bridge.roomCallbacks.room = room;
#if DEBUG
    if ([parameters[@"enableWritableAssert"] boolValue]) {
        [WritableDetectRoom startObserveRoom:room];
    }
    
    room.shouldCheckingRepeatSetWritable = [parameters[@"enableWritableAssert"] boolValue];
#else
    room.shouldCheckingRepeatSetWritable = false;
#endif

    // Match Android: capture T0 after SDK readiness, just before dispatching this join.
    // Only enrich this attempt's JSON snapshot; never mutate the caller's config.
    NSMutableDictionary *joinParameters = [parameters mutableCopy];
    NSMutableDictionary *nativeTags = [parameters[@"__nativeTags"] isKindOfClass:NSDictionary.class]
        ? [parameters[@"__nativeTags"] mutableCopy] : [NSMutableDictionary dictionary];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = NSTimeZone.localTimeZone;
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    nativeTags[@"traceId"] = NSUUID.UUID.UUIDString;
    nativeTags[@"time"] = [formatter stringFromDate:NSDate.date];
    joinParameters[@"__nativeTags"] = nativeTags;

    [scopedBridge callHandler:@"sdk.joinRoom" arguments:@[joinParameters] completionHandler:^(id _Nullable value) {
       
        {
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *error = dict[@"__error"];
            if (![weakBridge whiteComplete:generation success:error == nil]) return;
            if (error) {
                NSString *desc = error[@"message"] ? : @"";
                NSString *description = error[@"jsStack"] ? : @"";
                [weakBridge.commonCallbacks logger:@{
                    @"[WhiteSDK]": [NSString stringWithFormat:@"joinRoom bridge error: %@, jsStack: %@", desc, description]
                }];
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: desc, NSDebugDescriptionErrorKey: description};
                if ([desc containsString:@"Failed to OpenBackingStore"]) {
                    // 修复 indexDB 打开错误的问题。
                    // 这个问题可以通过往 indexDB 里不停塞入 100 kb的 item，在塞满后再刷新页面复现。
                    [self.bridge evaluateJavaScript:@"indexedDB.databases().then(ds => Promise.all(ds.map(d => indexedDB.deleteDatabase(d.name))))" completionHandler:nil];
                }
                if (completionHandler) completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-100 userInfo:userInfo]);
            } else {
                room.observerId = dict[@"observerId"];
                room.writable = [dict[@"isWritable"] boolValue];
                [room updateRoomState:[WhiteRoomState _white_yy_modelWithJSON:dict[@"state"]]];
                weakBridge.room = room;
                weakBridge.roomCallbacks.room = room;
                
                if ([parameters[@"drawOnlyApplePencil"] boolValue] && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                    [room prepareForApplePencilDrawOnly:TRUE];
                }
                
                if (completionHandler) completionHandler(YES, room, nil);
            }
        }
        if (weakBridge.backgroundColor) {
            weakBridge.backgroundColor = weakBridge.backgroundColor;
        }
    }];
}

@end
