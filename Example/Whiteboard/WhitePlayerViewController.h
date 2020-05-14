//
//  WhitePlayerViewController.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/2.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhiteBaseViewController.h"
#import <Whiteboard/Whiteboard.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^PlayBlock)(WhitePlayer * _Nullable player, NSError * _Nullable eroror);

@interface WhitePlayerViewController : WhiteBaseViewController

#pragma mark - CallbackDelegate
@property (nonatomic, weak, nullable) id<WhitePlayerEventDelegate> eventDelegate;

#pragma mark - UnitTest

@property (nonatomic, copy, nullable) PlayBlock playBlock;
@property (nonatomic, strong) WhitePlayerConfig *playerConfig;

@end

NS_ASSUME_NONNULL_END
