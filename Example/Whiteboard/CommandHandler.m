//
//  CommandHandler.m
//  Whiteboard_Example
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "CommandHandler.h"

@implementation CommandHandler

+ (NSDictionary<NSString *,void (^)(WhiteCombinePlayer * _Nonnull)> *)generateCommandsForCombineReplay:(WhiteCombinePlayer *)player {
    return @{
        NSLocalizedString(@"播放", nil): ^(WhiteCombinePlayer* player) {
            [player play];
        },
        NSLocalizedString(@"暂停", nil): ^(WhiteCombinePlayer* player) {
            [player pause];
        },
        NSLocalizedString(@"加速", nil): ^(WhiteCombinePlayer* player) {
            player.playbackSpeed = 1.25;
        },
        NSLocalizedString(@"快进", nil): ^(WhiteCombinePlayer* player) {
            [player seekToTime:CMTimeMake(3000, 600) completionHandler:^(BOOL finished) {
                [player play];
            }];
        },
        NSLocalizedString(@"观察模式", nil): ^(WhiteCombinePlayer* player) {
            [player.whitePlayer setObserverMode:WhiteObserverModeFreedom];
        },
        NSLocalizedString(@"获取信息", nil): ^(WhiteCombinePlayer* player) {
            [player.whitePlayer getPlayerStateWithResult:^(WhitePlayerState * _Nullable state) {
                NSLog(@"%@", state);
            }];
            [player.whitePlayer getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
                NSLog(@"%@", info);
            }];
            [player.whitePlayer getPlaybackSpeed:^(CGFloat speed) {
                NSLog(@"%f", speed);
            }];
        }
    };
}

+ (NSDictionary<NSString *,void (^)(WhitePlayer * _Nonnull)> *)generateCommandsForReplay:(WhitePlayer *)player {
    return @{
        NSLocalizedString(@"播放", nil): ^(WhitePlayer* player) {
            [player play];
        },
        NSLocalizedString(@"暂停", nil): ^(WhitePlayer* player) {
            [player pause];
        },
        NSLocalizedString(@"加速", nil): ^(WhitePlayer* player) {
            player.playbackSpeed = 1.25;
        },
        NSLocalizedString(@"快进", nil): ^(WhitePlayer* player) {
            [player seekToScheduleTime:5];
        },
        NSLocalizedString(@"观察模式", nil): ^(WhitePlayer* player) {
            [player setObserverMode:WhiteObserverModeFreedom];
        },
        NSLocalizedString(@"获取信息", nil): ^(WhitePlayer* player) {
            [player getPlayerStateWithResult:^(WhitePlayerState * _Nullable state) {
                NSLog(@"%@", state);
            }];
            [player getPlayerTimeInfoWithResult:^(WhitePlayerTimeInfo * _Nonnull info) {
                NSLog(@"%@", info);
            }];
        }
    };
}

+ (NSDictionary<NSString*, void(^)(WhiteRoom* room)> *)generateCommandsForRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken {
    #pragma unused(roomToken)
    static __weak UIView *originalSuperview = nil;
    static CGRect originalFrame = {0};
    static CGRect originalBounds = {0};
    
    return @{
        NSLocalizedString(@"触发布局切换", nil): ^(WhiteRoom* room) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"changeframe" object:nil];
        },
        NSLocalizedString(@"切换 hidden", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            boardView.hidden = !boardView.hidden;
            NSLog(@"boardView.hidden -> %@", boardView.hidden ? @"YES" : @"NO");
        },
        NSLocalizedString(@"alpha 置 0", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            boardView.alpha = 0.0;
            NSLog(@"boardView.alpha -> %.2f", boardView.alpha);
        },
        NSLocalizedString(@"alpha 还原 1", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            boardView.alpha = 1.0;
            NSLog(@"boardView.alpha -> %.2f", boardView.alpha);
        },
        NSLocalizedString(@"bounds 置零", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            originalBounds = boardView.bounds;
            boardView.bounds = CGRectZero;
            NSLog(@"boardView.bounds -> %@", NSStringFromCGRect(boardView.bounds));
        },
        NSLocalizedString(@"bounds 还原", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            if (CGRectIsEmpty(originalBounds)) {
                return;
            }
            boardView.bounds = originalBounds;
            NSLog(@"boardView.bounds -> %@", NSStringFromCGRect(boardView.bounds));
        },
        NSLocalizedString(@"移出父视图", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            if (!boardView.superview) { return; }
            originalSuperview = boardView.superview;
            originalFrame = boardView.frame;
            originalBounds = boardView.bounds;
            [boardView removeFromSuperview];
            NSLog(@"boardView removed from superview");
        },
        NSLocalizedString(@"加回父视图", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            if (boardView.superview || !originalSuperview) { return; }
            [originalSuperview addSubview:boardView];
            if (!CGRectIsEmpty(originalFrame)) {
                boardView.frame = originalFrame;
            }
            if (!CGRectIsEmpty(originalBounds)) {
                boardView.bounds = originalBounds;
            }
            boardView.hidden = NO;
            if (boardView.alpha <= 0.01) {
                boardView.alpha = 1.0;
            }
            NSLog(@"boardView added back to superview");
        },
        NSLocalizedString(@"移动到屏幕外", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            if (!boardView.superview) { return; }
            originalFrame = boardView.frame;
            CGRect newFrame = boardView.frame;
            newFrame.origin.y = CGRectGetMaxY(boardView.superview.bounds) + 40.0;
            boardView.frame = newFrame;
            NSLog(@"boardView.frame -> %@", NSStringFromCGRect(boardView.frame));
        },
        NSLocalizedString(@"移动回屏幕内", nil): ^(WhiteRoom* room) {
            WhiteBoardView *boardView = [room valueForKey:@"bridge"];
            if (![boardView isKindOfClass:[WhiteBoardView class]]) { return; }
            if (!boardView.superview || CGRectIsEmpty(originalFrame)) { return; }
            boardView.frame = originalFrame;
            NSLog(@"boardView.frame -> %@", NSStringFromCGRect(boardView.frame));
        }
    };
}

@end
