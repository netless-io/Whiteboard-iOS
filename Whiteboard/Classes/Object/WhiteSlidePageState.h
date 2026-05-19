//
//  WhiteSlidePageState.h
//  Whiteboard
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/** 多窗口 SlideApp 页面状态。 */
@interface WhiteSlidePageState : WhiteObject

/** SlideApp 的窗口 ID。 */
@property (nonatomic, copy, readonly) NSString *appId;

/** 当前页码，从 1 开始。 */
@property (nonatomic, assign, readonly) NSInteger page;

/** 页面总数。 */
@property (nonatomic, assign, readonly) NSInteger pageCount;

@end

NS_ASSUME_NONNULL_END
