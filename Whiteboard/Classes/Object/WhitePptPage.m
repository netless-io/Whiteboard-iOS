//
//  WhitePptPage.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhitePptPage.h"

@implementation WhitePptPage

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"src" : @[@"src", @"conversionFileUrl"]};
}

@end
