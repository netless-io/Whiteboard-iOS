//
//  WhitePureReplayViewController.h
//  Whiteboard_Example
//
//  Created by yleaf on 2020/3/22.
//  Copyright © 2020 leavesster. All rights reserved.
//

#import "WhiteBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^PlayBlock)(WhitePlayer * _Nullable player, NSError * _Nullable eroror);

@interface WhitePureReplayViewController : WhiteBaseViewController

#pragma mark - CallbackDelegate
@property (nonatomic, weak, nullable) id<WhitePlayerEventDelegate> eventDelegate;

#pragma mark - UnitTest

@property (nonatomic, copy, nullable) PlayBlock playBlock;
@property (nonatomic, strong) WhitePlayerConfig *playerConfig;

@end

NS_ASSUME_NONNULL_END
