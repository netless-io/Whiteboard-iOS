//
//  CommandHandler.h
//  Whiteboard_Example
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <Foundation/Foundation.h>
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

NS_ASSUME_NONNULL_BEGIN

static NSString *WhiteCommandCustomEvent = @"WhiteCommandCustomEvent";

@interface CommandHandler : NSObject

+ (NSDictionary<NSString*, void(^)(WhiteCombinePlayer* player)> *)generateCommandsForCombineReplay:(WhiteCombinePlayer *)player;

+ (NSDictionary<NSString*, void(^)(WhitePlayer* player)> *)generateCommandsForReplay:(WhitePlayer *)player;

+ (NSDictionary<NSString*, void(^)(WhiteRoom* room)> *)generateCommandsForRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken;

@end

NS_ASSUME_NONNULL_END
