//
//  WhiteWindowDocsEventOptions.h
//  Whiteboard
//
//  Created by xuyunshi on 2023/7/6.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/** Docs 事件类型 */
typedef NSString * WhiteWindowDocsEventKey NS_STRING_ENUM;

/// 上一页
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventPrevPage;
/// 下一页
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventNextPage;
/// 上一步
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventPrevStep;
/// 下一步
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventNextStep;
/// 跳转到某一页 ( 需要配合 `WhiteWindowDocsEventOptions` 使用 )
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventJumpToPage;
/// 缩放当前课件页，scale 取值范围为 1 到 4，可传入小数。
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventScalePage;

@interface WhiteWindowDocsEventOptions : WhiteObject
@property (nonatomic, strong, nullable) NSNumber *page;
@property (nonatomic, strong, nullable) NSNumber *scale;
@end

NS_ASSUME_NONNULL_END
