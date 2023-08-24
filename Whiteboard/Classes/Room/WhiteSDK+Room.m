//
//  WhiteSDK+Room.m
//  WhiteSDK
//
//  Created by yleaf on 2019/12/10.
//

#import "WhiteSDK+Room.h"
#import "WhiteSDK+Private.h"
#import "WhiteBoardView+Private.h"
#import "WhiteConsts.h"
#import "WhiteRoom+Private.h"
#import "WhiteRoomCallbacks+Private.h"
#import "WhiteRoom.h"
#import "WhiteSocket.h"
#import "WhiteSocket+Private.h"

#if DEBUG
#import "WritableDetectRoom.h"
#endif


@implementation WhiteSDK (Room)

#pragma mark - Room API

- (void)joinRoomWithConfig:(WhiteRoomConfig *)config callbacks:(nullable id<WhiteRoomCallbackDelegate>)callbacks completionHandler:(void (^) (BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error))completionHandler
{
    NSAssert([config.roomToken length] > 0 && [config.uuid length] > 0, NSLocalizedString(@"room uuid 和 token 不能为空", nil));
    
    //从 WhiteBoardView 父类中解耦
    if (!self.bridge.roomCallbacks) {
        WhiteRoomCallbacks *roomCallbacks = [[WhiteRoomCallbacks alloc] init];
        self.bridge.roomCallbacks = roomCallbacks;
        [self.bridge addJavascriptObject:roomCallbacks namespace:@"room"];
    }

    
    if (callbacks) {
        self.bridge.roomCallbacks.delegate = callbacks;
    }
    __weak typeof(self.bridge)weakBridge = self.bridge;
    WhiteRoom *room = [[WhiteRoom alloc] initWithUuid:config.uuid bridge:weakBridge];
    self.bridge.roomCallbacks.room = room;
#if DEBUG
    if (config.enableWritableAssert) {
        [WritableDetectRoom startObserveRoom:room];
    }
    
    room.shouldCheckingRepeatSetWritable = config.enableWritableAssert;
#else
    room.shouldCheckingRepeatSetWritable = false;
#endif
    
    [self.bridge callHandler:@"sdk.joinRoom" arguments:@[config] completionHandler:^(id _Nullable value) {
       
        if (completionHandler) {
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *error = dict[@"__error"];
            if (error) {
                NSString *desc = error[@"message"] ? : @"";
                NSString *description = error[@"jsStack"] ? : @"";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: desc, NSDebugDescriptionErrorKey: description};
                if ([desc containsString:@"Failed to OpenBackingStore"]) {
                    // 修复 indexDB 打开错误的问题。
                    // 这个问题可以通过往 indexDB 里不停塞入 100 kb的 item，在塞满后再刷新页面复现。
                    [self.bridge evaluateJavaScript:@"indexedDB.databases().then(ds => Promise.all(ds.map(d => indexedDB.deleteDatabase(d.name))))" completionHandler:nil];
                }
                completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-100 userInfo:userInfo]);
            } else {
                room.observerId = dict[@"observerId"];
                room.writable = [dict[@"isWritable"] boolValue];
                [room updateRoomState:[WhiteRoomState modelWithJSON:dict[@"state"]]];
                weakBridge.room = room;
                weakBridge.roomCallbacks.room = room;
                
                if (config.drawOnlyApplePencil && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                    [room prepareForApplePencilDrawOnly:TRUE];
                }
                
                completionHandler(YES, room, nil);
            }
        }
        if (weakBridge.backgroundColor) {
            weakBridge.backgroundColor = weakBridge.backgroundColor;
        }
    }];
}

@end
