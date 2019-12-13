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

#pragma mark - Unit Testing
@property (nonatomic, copy, nullable) PlayBlock playBlock;

#pragma mark - CallbackDelegate
@property (nonatomic, weak, nullable) id<WhitePlayerEventDelegate> eventDelegate;

@end

NS_ASSUME_NONNULL_END
