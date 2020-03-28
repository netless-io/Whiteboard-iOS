//
//  WhiteSDK.m
//  Pods-white-ios-sdk_Example
//
//  Created by leavesster on 2018/8/11.
//

#import "WhiteSDK.h"
#import "WhiteSDK+Private.h"
#import "WhiteBoardView+Private.h"
#import "WhiteDisplayer+Private.h"
#import "WhiteConsts.h"

@interface WhiteSDK()

@property (nonatomic, strong, readwrite) WhiteSdkConfiguration *config;
@property (nonatomic, assign, getter=hasCreateWebSdk) BOOL createWebSdk;

@end

@implementation WhiteSDK

+ (NSString *)version
{
    return @"2.7.3";
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback
{
    self = [super init];
    if (self) {
        _bridge = boardView;
        _config = config;
        _bridge.commonCallbacks.delegate = callback;
        [self setupWebSdkInNeeded];
    }
    return self;
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config
{
    return [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:nil];
}

#pragma mark - Private
- (void)setupWebSdkInNeeded
{
    if (self.hasCreateWebSdk) {
        return;
    }

    [self.bridge setupWebSDKWithConfig:self.config completion:nil];
    self.createWebSdk = YES;
}

#pragma mark - CommonCallback
/**
 为空，则移除原来的 CommonCallback
 */
- (void)setCommonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callbackDelegate
{
    self.bridge.commonCallbacks.delegate = callbackDelegate;
}

@end
