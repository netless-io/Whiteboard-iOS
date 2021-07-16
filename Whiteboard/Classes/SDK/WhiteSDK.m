//
//  WhiteSDK.m
//  Pods-white-ios-sdk_Example
//
//  Created by leavesster on 2018/8/11.
//

#import "WhiteSDK.h"
#import "WhiteSDK+Private.h"
#import "WhiteBoardView+Private.h"
#import "WhiteSdkConfiguration+Private.h"
#import "WhiteDisplayer+Private.h"
#import "WhiteConsts.h"

@interface WhiteSDK()

@property (nonatomic, strong, readwrite) WhiteSdkConfiguration *config;
@property (nonatomic, strong, readwrite) WhiteAudioMixerBridge *audioMixer;

@end

@implementation WhiteSDK

+ (NSString *)version
{
    return @"2.13.15";
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback audioMixerBridgeDelegate:( id<WhiteAudioMixerBridgeDelegate>)mixer
{
    self = [super init];
    if (self) {
        _bridge = boardView;
        _config = config;
        _bridge.commonCallbacks.delegate = callback;
        if ([mixer conformsToProtocol:@protocol(WhiteAudioMixerBridgeDelegate)]) {
            config.enableRtcIntercept = YES;
            _audioMixer = [[WhiteAudioMixerBridge alloc] initWithBridge:boardView delegate:mixer];
            [self.bridge addJavascriptObject:_audioMixer namespace:@"rtc"];
        }
        [self setupWebSdk];
    }
    return self;
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback
{
    self = [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:callback audioMixerBridgeDelegate:nil];
    return self;
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config
{
    return [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:nil];
}

#pragma mark - 字体

- (void)setupFontFaces:(NSArray <WhiteFontFace *>*)fontFaces
{
    [self.bridge callHandler:@"sdk.updateNativeFontFaceCSS" arguments:@[fontFaces]];
}

- (void)loadFontFaces:(NSArray <WhiteFontFace *>*)fontFaces completionHandler:(void (^)(BOOL success, WhiteFontFace *fontFace, NSError * _Nullable error))completionHandler;
{
    [self.bridge callHandler:@"sdk.asyncInsertFontFaces" arguments:@[fontFaces] completionHandler:^(NSDictionary * _Nullable value) {
        if (completionHandler) {
            NSDictionary *info = value;
            BOOL success = [info[@"success"] boolValue];
            WhiteFontFace *fontFace = [WhiteFontFace modelWithJSON:info[@"fontFace"]];
            if (success) {
                completionHandler(YES, fontFace, nil);
            } else {
                NSError *error = [NSError errorWithDomain:WhiteConstErrorDomain code:-400 userInfo:info[@"fontFace"]];
                completionHandler(NO, fontFace, error);
            }
        }
    }];
}

- (void)updateTextFont:(NSArray <NSString *>*)fonts;
{
    [self.bridge callHandler:@"sdk.updateNativeTextareaFont" arguments:@[fonts]];
}

#pragma mark - Private
- (void)setupWebSdk
{
    [self.bridge setupWebSDKWithConfig:self.config completion:nil];
}

#pragma mark - CommonCallback
- (void)setCommonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callbackDelegate
{
    self.bridge.commonCallbacks.delegate = callbackDelegate;
}

@end
