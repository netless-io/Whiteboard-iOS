//
//  WhiteSDK+Replayer.m
//  WhiteSDK
//
//  Created by yleaf on 2019/12/10.
//

#import "WhiteSDK+Replayer.h"
#import "WhiteSDK+Private.h"
#import "WhiteBoardView+Private.h"
#import "WhitePlayer+Private.h"
#import "WhiteDisplayer+Private.h"
#import "WhiteConsts.h"
#import "WhitePlayerEvent+Private.h"
#import "WhitePlayer.h"

@implementation WhiteSDK (Replayer)

#pragma mark - Replayer

- (void)createReplayerWithConfig:(WhitePlayerConfig *)config callbacks:(nullable id<WhitePlayerEventDelegate>)eventCallbacks completionHandler:(nonnull void (^)(BOOL, WhitePlayer * _Nullable, NSError * _Nullable))completionHandler
{
    NSAssert([config.room length] > 0, NSLocalizedString(@"需要一个房间 UUID", nil));
    
    if (!config.room.length || !config.roomToken.length) {
        if (completionHandler) completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-1100 userInfo:@{NSLocalizedDescriptionKey: @"InvalidReplayParameters"}]); return;
    }
    NSDictionary *sdkParameters = [NSJSONSerialization JSONObjectWithData:[self.config.jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:[config.jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSNumber *generation = [self.bridge whiteBeginWithCancellation:^(NSError *error) { if (completionHandler) completionHandler(NO, nil, error); }];
    if (!generation) { if (completionHandler) completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-1100 userInfo:@{NSLocalizedDescriptionKey: @"Busy/AlreadyJoined"}]); return; }
    [self whiteBindCommonCallback];
    WhiteBoardView *scopedBridge = [self.bridge whiteScopedBridge:generation];
    //从 WhiteBoardView 父类中解耦
    if (!self.bridge.playerEvent) {
        WhitePlayerEvent *playerEvent = [[WhitePlayerEvent alloc] init];
        self.bridge.playerEvent = playerEvent;
        [self.bridge addJavascriptObject:playerEvent namespace:@"player"];
    }
    
    self.bridge.playerEvent.delegate = eventCallbacks;

    __weak typeof(self.bridge)weakBridge = self.bridge;
    void (^replayResult)(id) = ^(id value) {
        {
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *error = dict[@"__error"];
            if (![weakBridge whiteComplete:generation success:error == nil]) return;
            if (error) {
                NSString *desc = error[@"message"] ? : @"";
                NSString *description = error[@"jsStack"] ? : @"";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: desc, NSDebugDescriptionErrorKey: description};
                if (completionHandler) completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-101 userInfo:userInfo]);
            } else {
                WhitePlayer *player = [[WhitePlayer alloc] initWithUuid:parameters[@"room"] bridge:scopedBridge];
                weakBridge.playerEvent.player = player;
                [player updateTimeInfo:[WhitePlayerTimeInfo _white_yy_modelWithJSON:dict[@"timeInfo"]]];
                if (completionHandler) completionHandler(YES, player, nil);
            }
        }
        if (weakBridge.backgroundColor) {
            weakBridge.backgroundColor = weakBridge.backgroundColor;
        }
    };
    [scopedBridge callHandler:@"sdk.newWhiteSdk" arguments:@[sdkParameters] completionHandler:^(id value) {
        if (![weakBridge whiteCurrent:generation]) return;
        NSDictionary *result = [value isKindOfClass:NSString.class] ? [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] : nil;
        NSDictionary *setupError = result[@"__error"];
        if (!result || setupError) {
            if (![weakBridge whiteComplete:generation success:NO]) return;
            NSString *message = !result ? @"InvalidSetupResult" : setupError[@"message"] ?: @"CreateFailed";
            if (completionHandler) completionHandler(NO, nil, [NSError errorWithDomain:WhiteConstErrorDomain code:-101 userInfo:@{NSLocalizedDescriptionKey: message}]);
            return;
        }
        [scopedBridge callHandler:@"sdk.replayRoom" arguments:@[parameters] completionHandler:replayResult];
    }];
}

- (void)isPlayable:(WhitePlayerConfig *)config result:(void (^)(BOOL isPlayable))result
{
    [self.bridge callHandler:@"sdk.isPlayable" arguments:@[config] completionHandler:^(id  _Nullable value) {
        if (result) {
            BOOL isPlayable = [value boolValue];
            result(isPlayable);
        }
    }];
}

@end
