//
//  WhiteSdkConfiguration.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteSdkConfiguration.h"

static NSString *const kJSDeviceType = @"deviceType";

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
    return self;
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

@end
