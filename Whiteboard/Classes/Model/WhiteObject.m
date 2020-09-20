//
//  WhiteModel.m
//  Whiteboard
//
//  Created by yleaf on 2020/9/19.
//

#import "WhiteObject.h"

#ifdef USE_YYKit
@implementation NSObject (YYModel)

+ (nullable instancetype)yy_modelWithJSON:(id)json {
    return [self modelWithJSON:json];
}

+ (nullable instancetype)yy_modelWithDictionary:(NSDictionary *)dictionary
{
    return [self modelWithDictionary:dictionary];
}

- (BOOL)yy_modelSetWithJSON:(id)json
{
    return [self modelSetWithJSON:json];
}

- (BOOL)yy_modelSetWithDictionary:(NSDictionary *)dic
{
    return [self modelSetWithDictionary:dic];
}

- (nullable id)yy_modelToJSONObject
{
    return [self modelToJSONObject];
}

- (nullable NSData *)yy_modelToJSONData
{
    return [self modelToJSONData];
}

- (nullable NSString *)yy_modelToJSONString
{
    return [self modelToJSONString];
}

- (nullable id)yy_modelCopy
{
    return [self modelCopy];
}

- (void)yy_modelEncodeWithCoder:(NSCoder *)aCoder
{
    return [self modelEncodeWithCoder:aCoder];
}

- (id)yy_modelInitWithCoder:(NSCoder *)aDecoder
{
    return [self modelInitWithCoder:aDecoder];
}

- (NSUInteger)yy_modelHash
{
    return [self modelHash];
}

- (BOOL)yy_modelIsEqual:(id)model
{
    return [self modelIsEqual:model];
}

- (NSString *)yy_modelDescription
{
    return [self modelDescription];
}

@end

#endif



@implementation WhiteObject


#ifdef USE_YYKit

+ (instancetype)modelWithJSON:(id)json
{
    return [self modelWithJSON:json];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", [super description], [self jsonDict]];
}

- (NSString *)jsonString
{
    return [self modelToJSONString];
}

- (NSDictionary *)jsonDict
{
    NSDictionary *dict = [self modelToJSONObject];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    return [self modelToJSONObject];
}

#else

+ (instancetype)modelWithJSON:(id)json
{
    return [self yy_modelWithJSON:json];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", [super description], [self jsonDict]];
}

- (NSString *)jsonString
{
    return [self yy_modelToJSONString];
}

- (NSDictionary *)jsonDict
{
    NSDictionary *dict = [self yy_modelToJSONObject];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    return [self yy_modelToJSONObject];
}


#endif

@end
