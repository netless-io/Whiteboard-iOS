//
//  WhiteSDK+Replayer.h
//  WhiteSDK
//
//  Created by yleaf on 2019/12/10.
//

#import "WhiteSDK.h"
#import "WhitePlayerEvent.h"
#import "WhitePlayerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class WhitePlayer;

@interface WhiteSDK (Replayer)
#pragma mark - Player
- (void)createReplayerWithConfig:(WhitePlayerConfig *)config callbacks:(nullable id<WhitePlayerEventDelegate>)eventCallbacks completionHandler:(void (^) (BOOL success, WhitePlayer * _Nullable player, NSError * _Nullable error))completionHandler;



///  检查回放房间内数据，判断，对应时间段，对应 uuid，是否有回放数据，避免直接 replay 时，报找不到房间的错误
/// @param config 回放房间时的配置内容
/// @param result 该房间在特定时间段，是否能够进行回放
/// @since 2.11.0
- (void)isPlayable:(WhitePlayerConfig *)config result:(void (^)(BOOL isPlayable))result;

@end

NS_ASSUME_NONNULL_END
