//
//  NSObject+YY.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/4/21.
//

#import "NSObject+YY.h"

@implementation NSObject (YY)

#if YYMODEL
+ (instancetype)modelWithJSON:(id)json
{
    return [self yy_modelWithJSON:json];
}
#else
- (NSString *)yy_modelDescription
{
    return [self modelDescription];
}

- (nullable NSString *)yy_modelToJSONString;
{
    return [self modelToJSONString];
}

- (nullable id)yy_modelToJSONObject
{
    return [self modelToJSONObject];
}

- (BOOL)yy_modelSetWithJSON:(id)json
{
    return [self modelSetWithJSON:json];
}
#endif

@end
