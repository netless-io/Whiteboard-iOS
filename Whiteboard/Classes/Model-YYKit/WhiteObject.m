//
//  WhiteObject.m
//  Whiteboard
//
//  Created by yleaf on 2020/9/23.
//

#import "WhiteObject.h"

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

@implementation NSArray (YYModel)


+ (nullable NSArray *)yy_modelArrayWithClass:(Class _Nullable)cls json:(id _Nullable)json
{
    return [self modelArrayWithClass:cls json:json];
}

@end




@implementation NSDictionary (YYModel)


+ (nullable NSDictionary *)yy_modelDictionaryWithClass:(Class _Nullable )cls json:(id  _Nullable)json
{
    return [self modelDictionaryWithClass:cls json:json];
}

@end


@implementation WhiteObject

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


@end
