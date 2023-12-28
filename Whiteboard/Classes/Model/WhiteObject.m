//
//  WhiteModel.m
//  Whiteboard
//
//  Created by yleaf on 2020/9/19.
//

#import "WhiteObject.h"

@implementation WhiteObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", [super description], [self jsonDict]];
}

- (NSString *)jsonString
{
    return [self _white_yy_modelToJSONString];
}

- (NSDictionary *)jsonDict
{
    NSDictionary *dict = [self _white_yy_modelToJSONObject];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    return dict;
}

@end
