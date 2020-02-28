//
//  WhitePptPage.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhitePptPage.h"

@implementation WhitePptPage

- (instancetype)initWithSrc:(NSString *)src size:(CGSize)size
{
    self = [super init];
    _src = src;
    _width = size.width;
    _height = size.height;
    return self;
}

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"src" : @[@"src", @"conversionFileUrl"]};
}

@end
