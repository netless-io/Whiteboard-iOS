//
//  WhiteAppliancePluginOptions.h
//  Whiteboard
//
//  Created by vince on 2025/8/14.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteAppliancePluginOptions : WhiteObject

/// 注意如果有 boolean类型的参数，使用 NSNumber 包装
@property (nonatomic, copy) NSDictionary* extras;

@end

NS_ASSUME_NONNULL_END
