//
//  WhiteConsts.m
//  WhiteSDK
//
//  Created by yleaf on 2019/3/4.
//

#import "WhiteConsts.h"

NSString * const WhiteConstsErrorDomain = @"com.herewhite.white";
NSString * const WhiteConstsConvertDomain = @"convert.com.herewhite.white";

//javascript 端，使用的是毫秒；iOS 端，习惯使用秒，使用 NSTimeInterval
NSTimeInterval const WhiteConstsTimeUnitRatio = 1000.0;

WhiteRegionKey const WhiteRegionDefault = @"cn-hz";
WhiteRegionKey const WhiteRegionCN = @"cn-hz";
WhiteRegionKey const WhiteRegionUS = @"us-sv";
