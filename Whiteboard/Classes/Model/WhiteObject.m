//
//  WhiteModel.m
//  Whiteboard
//
//  Created by yleaf on 2020/9/19.
//

#import "WhiteObject.h"
#import <objc/runtime.h>

@implementation WhiteObject

static char WhiteExplicitConfigurationKeys;

- (void)white_markExplicitConfigurationKey:(NSString *)key
{
    NSMutableSet *keys = objc_getAssociatedObject(self, &WhiteExplicitConfigurationKeys);
    if (!keys) {
        keys = [NSMutableSet set];
        objc_setAssociatedObject(self, &WhiteExplicitConfigurationKeys, keys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [keys addObject:key];
}

- (void)white_addDefaultConfigurationKeys:(NSArray<NSString *> *)keys toDictionary:(NSMutableDictionary *)dictionary
{
    NSSet *explicit = objc_getAssociatedObject(self, &WhiteExplicitConfigurationKeys);
    NSMutableArray *defaults = [NSMutableArray array];
    for (NSString *key in keys) {
        if (dictionary[key] && ![explicit containsObject:key]) [defaults addObject:key];
    }
    if (defaults.count) dictionary[@"__nativeConfigDefaults"] = defaults;
}

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
