//
//  WhitePlayerViewController.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/2.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhiteBaseViewController.h"
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif
//#import ""

NS_ASSUME_NONNULL_BEGIN
typedef void(^CombinePlayBlock)(WhiteCombinePlayer * _Nullable player, NSError * _Nullable eroror);

@interface WhitePlayerViewController : WhiteBaseViewController

#pragma mark - CallbackDelegate
@property (nonatomic, weak, nullable) id<WhitePlayerEventDelegate> eventDelegate;

#pragma mark - UnitTest

@property (nonatomic, copy, nullable) CombinePlayBlock playBlock;
@property (nonatomic, strong) WhitePlayerConfig *playerConfig;
@property (nonatomic, assign) BOOL ignoreWhitePlayer;

- (instancetype)initWithNativeURL:(nullable NSURL *)nativeURL;

@end

NS_ASSUME_NONNULL_END
