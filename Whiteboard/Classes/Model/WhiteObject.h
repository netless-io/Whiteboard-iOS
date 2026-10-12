//
//  WhiteModel.h
//  Whiteboard
//
//  Created by yleaf on 2020/9/19.
//

#import <Foundation/Foundation.h>

#if __has_include(<White_YYModel/White_YYModel.h>)
#import <White_YYModel/White_YYModel.h>
#elif __has_include("White_YYModel.h")
#import "White_YYModel.h"
#elif __has_include("NSObject+White_YYModel.h")
#import "NSObject+White_YYModel.h"
#endif


NS_ASSUME_NONNULL_BEGIN

@interface WhiteObject : NSObject

- (NSString *)jsonString;
- (NSDictionary *)jsonDict;

// Internal Native -> Bridge parameter provenance. These methods do not change API defaults.
- (void)white_markExplicitConfigurationKey:(NSString *)key;
- (void)white_addDefaultConfigurationKeys:(NSArray<NSString *> *)keys toDictionary:(NSMutableDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
