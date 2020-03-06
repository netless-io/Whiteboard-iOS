//
//  WhiteSdkConfiguration.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteSdkConfiguration.h"
#import "WhiteSDK.h"
#import <sys/utsname.h>

static NSString *const kJSDeviceType = @"deviceType";

@interface WhiteSdkConfiguration ()

@property (nonatomic, copy, nonnull) NSDictionary *nativeTags;

@end

@implementation WhiteSdkConfiguration

+ (instancetype)defaultConfig
{
    return [[WhiteSdkConfiguration alloc] init];
}

- (instancetype)init
{
    self = [super init];
    _deviceType = WhiteDeviceTypeTouch;
    _zoomMinScale = 0.1;
    _zoomMaxScale = 10;
    UIDevice *currentDevice = [UIDevice currentDevice];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    _nativeTags = @{@"nativeVersion": [WhiteSDK version], @"platform": [NSString stringWithFormat:@"%@ %@", deviceModel, currentDevice.systemVersion]};

    return self;
}

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper
{
    return @{@"sdkStrategyConfig": @"initializeOriginsStates", @"nativeTags": @"__nativeTags"};
}

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    if (_deviceType == WhiteDeviceTypeDesktop) {
        dic[kJSDeviceType] = @"desktop";
    } else {
        dic[kJSDeviceType] = @"touch";
    }
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
    // 动态ppt的预加载在低版本iOS存在兼容性问题
    if (@available(iOS 13, *)) {
        _preloadDynamicPPT = preloadDynamicPPT;
    } else {
        
    }
}

@end
