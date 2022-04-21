//
//  NSObject+YY.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/4/21.
//

#import <Foundation/Foundation.h>

#define YYMODEL __has_include(<YYModel/YYModel.h>) || __has_include("YYModel.h")
#define YYKIT __has_include(<YYKit/YYKit.h>) __has_include("NSObject+YYModel.h")

#if __has_include(<YYModel/YYModel.h>)
#import <YYModel/YYModel.h>
#elif __has_include("YYModel.h")
#import "YYModel.h"
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/NSObject+YYModel.h>
#elif __has_include("NSObject+YYModel.h")
#import "NSObject+YYModel.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (YY)

#if YYMODEL
+ (nullable instancetype)modelWithJSON:(id)json;
#else
- (NSString *)yy_modelDescription;
- (nullable NSString *)yy_modelToJSONString;
- (nullable id)yy_modelToJSONObject;
- (BOOL)yy_modelSetWithJSON:(id)json;
#endif

@end

NS_ASSUME_NONNULL_END
