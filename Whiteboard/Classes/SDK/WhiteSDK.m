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
#import "WhiteWebViewInjection.h"

@interface WhiteSDK()

@property (nonatomic, strong, readwrite) WhiteSdkConfiguration *config;
@property (nonatomic, strong, readwrite) WhiteAudioMixerBridge *audioMixer;
@property (nonatomic, strong, readwrite) WhiteAudioEffectMixerBridge *effectMixer;

@property (nonatomic, copy) NSString *requestingSlideLogSessionId;
@property (nonatomic, copy) NSString *slideLogPath;
@property (nonatomic, copy) NSFileHandle *slideLogFileHandler;
@property (nonatomic, copy) void(^requestLogHandler)(BOOL success, NSError *error);
@property (nonatomic, copy) void(^requestSlideVolumeHandler)(CGFloat volume, NSError *error);

@end

@implementation WhiteSDK

+ (NSString *)version
{
    return @"2.16.104";
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback audioMixerBridgeDelegate:(nullable id<WhiteAudioMixerBridgeDelegate>)mixer effectMixerBridgeDelegate:(nullable id<WhiteAudioEffectMixerBridgeDelegate>)effectMixer {
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
        if ([effectMixer conformsToProtocol:@protocol(WhiteAudioEffectMixerBridgeDelegate)]) {
            config.enableRtcAudioEffectIntercept = YES;
            _effectMixer = [[WhiteAudioEffectMixerBridge alloc] initWithBridge:boardView delegate:effectMixer];
            [self.bridge addJavascriptObject:_effectMixer namespace:@"rtc"];
        }
        [self setupWebSdk];
    }
    return self;
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback effectMixerBridgeDelegate:(nullable id<WhiteAudioEffectMixerBridgeDelegate>)effectMixer {
    return [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:callback audioMixerBridgeDelegate:nil effectMixerBridgeDelegate:effectMixer];
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback audioMixerBridgeDelegate:(nullable id<WhiteAudioMixerBridgeDelegate>)mixer
{
    return [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:callback audioMixerBridgeDelegate:mixer effectMixerBridgeDelegate:nil];
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback
{
    self = [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:callback audioMixerBridgeDelegate:nil effectMixerBridgeDelegate:nil];
    return self;
}

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config
{
    return [self initWithWhiteBoardView:boardView config:config commonCallbackDelegate:nil];
}

+ (void)prepareWhiteConnectionForAppId:(NSString *)appId region:(WhiteRegionKey)region expireSeconds:(NSNumber * _Nullable)expireSeconds attachingSuperView:(UIView * _Nullable)superView
{
    expireSeconds = expireSeconds ? expireSeconds : @(3600 * 12); // Default is 12 hours.
    float expire = [expireSeconds floatValue] * 1000;
    WhiteBoardView *foo = [[WhiteBoardView alloc] init];
    foo.alpha = 0;
    [foo setHidden:YES];
    superView = superView ? superView : UIApplication.sharedApplication.keyWindow;
    [superView addSubview:foo];
    NSDictionary *params = @{@"appId": appId, @"region": region, @"expire": @(expire)};
    [foo callHandler:@"sdk.prepareWhiteConnection" arguments:@[params] completionHandler:^(id  _Nullable value) {
        [foo removeFromSuperview];
    }];
}

- (void)dealloc
{
    if (self.config.useWebKeyboardInjection) {
        [WhiteWebViewInjection allowDisplayingKeyboardWithoutUserAction:FALSE];
    }
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
            WhiteFontFace *fontFace = [WhiteFontFace _white_yy_modelWithJSON:info[@"fontFace"]];
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

#pragma mark - 自定义App

- (void)registerAppWithParams:(WhiteRegisterAppParams *)params completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
    [self.bridge callHandler:@"sdk.registerApp" arguments:@[params] completionHandler:^(id  _Nullable value) {
        if (completionHandler) {
            if (!value) {
                completionHandler(nil);
                return;
            }
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSDictionary *error = dict[@"__error"];
            if (error) {
                NSString *desc = error[@"message"] ? : @"";
                NSString *description = error[@"jsStack"] ? : @"";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: desc, NSDebugDescriptionErrorKey: description};
                completionHandler([NSError errorWithDomain:WhiteConstErrorDomain code:-101 userInfo:userInfo]);
            } else {
                completionHandler(nil);
            }
        }
    }];
}

#pragma mark - Private
- (void)setupWebSdk
{
    if (self.config.useWebKeyboardInjection) {
        [WhiteWebViewInjection allowDisplayingKeyboardWithoutUserAction:TRUE];
    }
    if ([self.config.loggerOptions[@"printLevelMask"] isEqualToString:WhiteSDKLoggerOptionLevelDebug]) {
        [self.bridge observeWKWebViewConsole];
    }
    [self.bridge setupWebSDKWithConfig:self.config completion:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSlideLogNotification:) name:@"Slide-Log" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSlideVolumeNotification:) name:@"Slide-Volume" object:nil];
}

#pragma mark - PPT Volume
- (void)getSlideVolumeWithCompletionHandler:(void (^)(CGFloat, NSError * _Nonnull))completionHandler
{
    self.requestSlideVolumeHandler = completionHandler;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.bridge evaluateJavaScript:@"window.postMessage({type: \"@slide/_get_volume_\"}, '*');" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                completionHandler(0, error);
                weakSelf.requestSlideVolumeHandler = nil;
                return;
            }
        }];
    });
}

- (void)updateSlideVolume:(CGFloat)volume
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.bridge evaluateJavaScript:[NSString stringWithFormat:@"window.postMessage ({'type': \"@slide/_update_volume_\", 'volume': %f}, '*')", volume] completionHandler:nil];
    });
}

#pragma mark - CommonCallback
- (void)setCommonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callbackDelegate
{
    self.bridge.commonCallbacks.delegate = callbackDelegate;
}

#pragma mark - SlideCallback
- (void)setSlideDelegate:(nullable id<WhiteSlideDelegate>)slideDelegate
{
    self.bridge.commonCallbacks.slideDelegate = slideDelegate;
}

#pragma mark - Slide 日志
- (void)requestSlideLogToFilePath:(NSString *)path result:(void(^)(BOOL success, NSError *error))result
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL fileExist = [manager fileExistsAtPath:path];
    if (!fileExist) {
        [manager createFileAtPath:path contents:nil attributes:nil];
    }
    NSString *sessionId = [NSString stringWithFormat:@"%d", [self.requestingSlideLogSessionId intValue] + 1];
    self.requestingSlideLogSessionId = sessionId;
    self.requestLogHandler = result;
    self.slideLogPath = path;
    self.slideLogFileHandler = [NSFileHandle fileHandleForWritingAtPath:path];
    NSString *logJs = [NSString stringWithFormat:@"window.postMessage({type: '@slide/_request_log_', sessionId: '%@'}, '*')", sessionId];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.bridge evaluateJavaScript:logJs completionHandler:^(id _Nullable value, NSError * _Nullable error) {
            if (error) {
                result(NO, error);
                [weakSelf cleanSlideLogResource];
            }
        }];
    });
}

- (void)cleanSlideLogResource
{
    [self.slideLogFileHandler closeFile];
    self.slideLogPath = @"";
    self.requestingSlideLogSessionId = @"";
    self.requestLogHandler = nil;
    self.slideLogFileHandler = nil;
}

- (void)onSlideVolumeNotification:(NSNotification *)notification
{
    if (!self.requestSlideVolumeHandler) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[@"volume"]) {
        CGFloat volume = [userInfo[@"volume"] floatValue];
        self.requestSlideVolumeHandler(volume, nil);
        return;
    }
    NSError *error = [NSError errorWithDomain:WhiteConstErrorDomain code:-70000 userInfo:userInfo];
    self.requestSlideVolumeHandler(0, error);
}

- (void)onSlideLogNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) { return; }
    if (![userInfo[@"sessionId"] isEqualToString:self.requestingSlideLogSessionId]) { return; }
    NSString *log = userInfo[@"log"];
    [self.slideLogFileHandler seekToEndOfFile];
    NSData *data = [log dataUsingEncoding:NSUTF8StringEncoding];
    [self.slideLogFileHandler writeData:data];
    
    int index = [userInfo[@"index"] intValue];
    int total = [userInfo[@"total"] intValue];
    if (total == index) {
        self.requestLogHandler(YES, nil);
        [self cleanSlideLogResource];
    }
}

- (void)setParameters:(NSDictionary *)parameters
{
    [self.bridge callHandler:@"sdk.setParameters" arguments:@[parameters]];
}

@end
