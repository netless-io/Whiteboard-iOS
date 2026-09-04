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
/// 缩放当前课件页，scale 是相对于适配尺寸的倍率。
FOUNDATION_EXPORT WhiteWindowDocsEventKey const WhiteWindowDocsEventScalePage;

@interface WhiteWindowDocsEventOptions : WhiteObject
/** `mainView` 或具体的 DocsViewer/Slide/Presentation appId。 */
@property (nonatomic, copy, nullable) NSString *target;
@property (nonatomic, strong, nullable) NSNumber *page;
@property (nonatomic, strong, nullable) NSNumber *scale;
@end

typedef NSString * WhiteDispatchDocsEventFailureReason NS_STRING_ENUM;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonInvalidEvent;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonInvalidOptions;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonTargetNotFound;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonTargetNotSupported;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonEventNotSupported;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonNotWritable;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonStateUnavailable;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonOutOfRange;
FOUNDATION_EXPORT WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonCommandFailed;

@interface WhiteDispatchDocsEventResult : WhiteObject
@property (nonatomic, assign, readonly) BOOL accepted;
@property (nonatomic, copy, readonly, nullable) WhiteDispatchDocsEventFailureReason reason;
@property (nonatomic, copy, readonly, nullable) NSString *message;
@end

NS_ASSUME_NONNULL_END
