#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteWindowPageStateOptions : WhiteObject
/** `mainView` or a concrete DocsViewer/Slide/Presentation appId. */
@property (nonatomic, copy, nullable) NSString *target;
@end

@interface WhiteUnifiedPageState : WhiteObject
@property (nonatomic, copy, readonly) NSString *target;
@property (nonatomic, copy, readonly, nullable) NSString *appId;
@property (nonatomic, assign, readonly) NSInteger page;
@property (nonatomic, assign, readonly) NSInteger pageCount;
@property (nonatomic, strong, readonly, nullable) NSNumber *scale;
@end

@interface WhiteUnifiedPageStateChange : WhiteUnifiedPageState
@property (nonatomic, copy, readonly) NSString *status;
@property (nonatomic, copy, readonly, nullable) NSString *changeType;
@property (nonatomic, strong, readonly, nullable) NSNumber *mainView;
@property (nonatomic, strong, readonly, nullable) NSNumber *presentation;
@property (nonatomic, strong, readonly, nullable) NSNumber *view;
@property (nonatomic, strong, readonly, nullable) NSNumber *slide;
@property (nonatomic, copy, readonly, nullable) NSString *event;
@property (nonatomic, copy, readonly, nullable) NSString *reason;
@property (nonatomic, copy, readonly, nullable) NSString *message;
@end

NS_ASSUME_NONNULL_END
