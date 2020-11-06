//
//  WhiteConsts.h
//  WhiteSDK
//
//  Created by yleaf on 2019/3/4.
//

#import <Foundation/Foundation.h>

#pragma mark - Domain

extern NSString * const WhiteConstsErrorDomain;
extern NSString * const WhiteConstsConvertDomain;

#pragma mark - Ratio
extern NSTimeInterval const WhiteConstsTimeUnitRatio;

#pragma mark - Region
typedef NSString * WhiteRegionKey NS_STRING_ENUM;

extern WhiteRegionKey const WhiteRegionDefault;
extern WhiteRegionKey const WhiteRegionCN;
extern WhiteRegionKey const WhiteRegionUS;
