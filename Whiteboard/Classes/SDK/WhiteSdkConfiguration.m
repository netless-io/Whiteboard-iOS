//
//  WhiteSdkConfiguration.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteSdkConfiguration.h"
#import "WhiteSdkConfiguration+Private.h"
#import "WhiteSDK.h"
#import <sys/utsname.h>

@implementation WhitePresentationViewport
@end

@implementation WhitePresentationAppOptions
@end

@implementation WhiteBackgroundImageLoadOptions
- (instancetype)init {
    self = [super init];
    if (self) {
        _maxRetries = 3;
        _timeoutMs = 15000;
        _retryIntervalMs = 1000;
    }
    return self;
}
- (void)setMaxRetries:(NSInteger)value {
    if (value < -1 || value > 10) {
        [NSException raise:NSInvalidArgumentException
                    format:@"maxRetries must be -1 or from 0 to 10"];
    }
    _maxRetries = value;
}
- (void)setTimeoutMs:(NSInteger)value {
    if (value < 1000 || value > 120000) {
        [NSException raise:NSInvalidArgumentException
                    format:@"timeoutMs must be from 1000 to 120000"];
    }
    _timeoutMs = value;
}
- (void)setRetryIntervalMs:(NSInteger)value {
    if (value < 0 || value > 30000) {
        [NSException raise:NSInvalidArgumentException
                    format:@"retryIntervalMs must be from 0 to 30000"];
    }
    _retryIntervalMs = value;
}
@end

@implementation WhiteLocalLogOptions
@end

@implementation WhitePptParams

- (instancetype)init {
    self = [super init];
    _useServerWrap = YES;
    return self;
}

@end

WhiteSdkRenderEngineKey const WhiteSdkRenderEngineSvg = @"svg";
WhiteSdkRenderEngineKey const WhiteSdkRenderEngineCanvas = @"canvas";

WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelDebug = @"debug";
WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelInfo = @"info";
WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelWarn = @"warn";
WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelError = @"error";

WhiteSDKLoggerReportModeKey const WhiteSDKLoggerReportAlways = @"alwaysReport";
WhiteSDKLoggerReportModeKey const WhiteSDKLoggerReportBan = @"banReport";

@interface WhiteSdkConfiguration ()

@property (nonatomic, copy, nonnull) NSDictionary *nativeTags;
@property (nonatomic, copy, nonnull) NSString *platform;

@end

@implementation WhiteSdkConfiguration

static NSString *const kJSDeviceType = @"deviceType";

static NSInteger WhiteIOSMajorVersionFromPlatformUA(NSString *platformUA)
{
    if (![platformUA isKindOfClass:NSString.class]) {
        return NSNotFound;
    }

    NSArray<NSString *> *rawComponents = [platformUA componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSMutableArray<NSString *> *components = [NSMutableArray arrayWithCapacity:rawComponents.count];
    for (NSString *component in rawComponents) {
        if (component.length > 0) {
            [components addObject:component];
        }
    }
    if (components.count < 3 || ![components.firstObject.lowercaseString isEqualToString:@"ios"]) {
        return NSNotFound;
    }

    NSInteger majorVersion = 0;
    NSScanner *scanner = [NSScanner scannerWithString:components.lastObject];
    if (![scanner scanInteger:&majorVersion] || majorVersion <= 0) {
        return NSNotFound;
    }
    return majorVersion;
}

static BOOL WhiteShouldDisableLocalLogForPlatformUA(NSString *platformUA)
{
    NSInteger majorVersion = WhiteIOSMajorVersionFromPlatformUA(platformUA);
    return majorVersion != NSNotFound && majorVersion <= 12;
}

static void WhiteApplyIOS12LocalLogCompatibility(NSMutableDictionary *loggerOptions, NSDictionary *nativeTags)
{
    @try {
        NSString *platformUA = [nativeTags[@"platform"] isKindOfClass:NSString.class] ? nativeTags[@"platform"] : nil;
        if (!WhiteShouldDisableLocalLogForPlatformUA(platformUA)) {
            return;
        }

        NSMutableDictionary *effectiveLocalLog = [loggerOptions[@"localLog"] isKindOfClass:NSDictionary.class] ?
            [loggerOptions[@"localLog"] mutableCopy] :
            [NSMutableDictionary dictionary];
        effectiveLocalLog[@"enabled"] = @NO;
        effectiveLocalLog[@"enabledUpload"] = @NO;
        loggerOptions[@"localLog"] = [effectiveLocalLog copy];
    } @catch (__unused NSException *exception) {
        // This compatibility guard must never block SDK initialization or whiteboard usage.
    }
}

+ (instancetype)defaultConfig
{
    NSAssert(NO, @"WhiteSdkConfiguration must have appIdentifier, please use initWithApp:");
    return nil;
}

- (instancetype)init
{
    NSAssert(NO, @"WhiteSdkConfiguration must have appIdentifier, please use initWithApp:");
    return nil;
}

- (instancetype)initWithApp:(NSString *)appIdentifier
{
    self = [super init];
    _deviceType = WhiteDeviceTypeTouch;
    NSOperatingSystemVersion iOS_10_0_0 = (NSOperatingSystemVersion){10, 0, 0};

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_10_0_0]) {
        _renderEngine = WhiteSdkRenderEngineCanvas;
    } else {
        _renderEngine = WhiteSdkRenderEngineSvg;
    }
    UIDevice *currentDevice = [UIDevice currentDevice];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    _platform = @"ios";
    _nativeTags = @{@"nativeVersion": [WhiteSDK version], @"platform": [NSString stringWithFormat:@"%@ %@ %@", _platform, deviceModel, currentDevice.systemVersion]};
    _appIdentifier = appIdentifier;
    _pptParams = [[WhitePptParams alloc] init];
    _disableNewPencilStroke = NO;
    _whiteSlideAppParams = [[WhiteSlideAppParams alloc] init];
    _enableSlideInterrupterAPI = NO;
    _useWebKeyboardInjection = YES;
    return self;
}

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper
{
    return @{@"nativeTags": @"__nativeTags",
             @"platform": @"__platform",
             @"netlessUA": @"__netlessUA",
             @"whiteSlideAppParams": @"slideAppOptions"
    };
}

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    if (_deviceType == WhiteDeviceTypeDesktop) {
        dic[kJSDeviceType] = @"desktop";
    } else {
        dic[kJSDeviceType] = @"touch";
    }
    NSMutableDictionary *loggerOptions = [dic[@"loggerOptions"] isKindOfClass:[NSDictionary class]] ?
        [dic[@"loggerOptions"] mutableCopy] :
        [NSMutableDictionary dictionary];
    NSDictionary *localLog = [_localLogOptions jsonDict];
    if (localLog.count > 0) {
        loggerOptions[@"localLog"] = localLog;
    }

    NSDictionary *serializedNativeTags = [dic[@"__nativeTags"] isKindOfClass:NSDictionary.class] ? dic[@"__nativeTags"] : _nativeTags;
    WhiteApplyIOS12LocalLogCompatibility(loggerOptions, serializedNativeTags);
    if (loggerOptions.count > 0) {
        dic[@"loggerOptions"] = [loggerOptions copy];
    }
    dic[@"localLogOptions"] = nil;
    return YES;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    if ([dic[kJSDeviceType] isEqualToString:@"desktop"]) {
        _deviceType = WhiteDeviceTypeDesktop;
    } else {
        _deviceType = WhiteDeviceTypeTouch;
    }
    return YES;
}

- (void)setPreloadDynamicPPT:(BOOL)preloadDynamicPPT
{
    _preloadDynamicPPT = preloadDynamicPPT;
}

static NSString *kLegacyReportLogKey = @"disableReportLog";
- (void)setLoggerOptions:(NSDictionary *)loggerOptions
{
    NSMutableDictionary *options = [loggerOptions mutableCopy];
    if (options[kLegacyReportLogKey] && [[options allKeys] count] == 1) {
        BOOL kSwitch = [loggerOptions[kLegacyReportLogKey] boolValue];
        if (!kSwitch) {
            options[@"reportDebugLogMode"] = WhiteSDKLoggerReportBan;
            options[@"reportQualityMode"] = WhiteSDKLoggerReportBan;
        }
    }
    options[kLegacyReportLogKey] = nil;
    _loggerOptions = [options copy];
}

@end
