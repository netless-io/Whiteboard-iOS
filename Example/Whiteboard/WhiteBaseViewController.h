//
//  WhiteBaseViewController.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/4.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Whiteboard_Example-swift.h"
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface WhiteBaseViewController : UIViewController

/** for Unit Testing */
- (instancetype)initWithSdkConfig:(WhiteSdkConfiguration *)sdkConfig;

@property (nonatomic, copy, nullable) NSString *roomUuid;
@property (nonatomic, strong) WhiteBoardView *boardView;
@property (nonatomic, strong) WhiteSDK *sdk;
@property (nonatomic, assign) BOOL useMultiViews;
@property (nonatomic, strong) ExampleControlView *controlView;

@property (nonatomic, strong, nonnull) WhiteSdkConfiguration *sdkConfig;

#pragma mark - CallbackDelegate
@property (nonatomic, weak, nullable) id<WhiteCommonCallbackDelegate> commonDelegate;

- (void)showPopoverViewController:(UIViewController *)vc sourceView:(id)sourceView;

@end

NS_ASSUME_NONNULL_END
