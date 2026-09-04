#import "WhiteUnifiedPageState.h"

@interface WhiteUnifiedPageState ()
@property (nonatomic, copy, readwrite) NSString *target;
@property (nonatomic, copy, readwrite, nullable) NSString *appId;
@property (nonatomic, assign, readwrite) NSInteger page;
@property (nonatomic, assign, readwrite) NSInteger pageCount;
@property (nonatomic, strong, readwrite, nullable) NSNumber *scale;
@end

@interface WhiteUnifiedPageStateChange ()
@property (nonatomic, copy, readwrite) NSString *status;
@property (nonatomic, copy, readwrite, nullable) NSString *changeType;
@property (nonatomic, strong, readwrite, nullable) NSNumber *mainView;
@property (nonatomic, strong, readwrite, nullable) NSNumber *presentation;
@property (nonatomic, strong, readwrite, nullable) NSNumber *view;
@property (nonatomic, strong, readwrite, nullable) NSNumber *slide;
@property (nonatomic, copy, readwrite, nullable) NSString *event;
@property (nonatomic, copy, readwrite, nullable) NSString *reason;
@property (nonatomic, copy, readwrite, nullable) NSString *message;
@end

@implementation WhiteWindowPageStateOptions
@end

@implementation WhiteUnifiedPageState
@end

@implementation WhiteUnifiedPageStateChange
@end
