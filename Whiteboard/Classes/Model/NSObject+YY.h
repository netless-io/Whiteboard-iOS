//
//  NSObject+YY.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/4/21.
//

#import <Foundation/Foundation.h>

#define YYMODEL __has_include(<YYModel/YYModel.h>) || __has_include("YYModel.h")

#if __has_include(<YYModel/YYModel.h>)
#import <YYModel/YYModel.h>
#elif __has_include("YYModel.h")
#import "YYModel.h"
#elif __has_include("NSObject+YYModel.h")
#import "NSObject+YYModel.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (YY)

+ (nullable instancetype)modelWithJSON:(id)json;

@end

NS_ASSUME_NONNULL_END
