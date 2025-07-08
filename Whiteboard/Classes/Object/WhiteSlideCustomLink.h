#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 WhiteSlideCustomLink.
 */
@interface WhiteSlideCustomLink : NSObject

@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, copy) NSString *shapeId;
@property (nonatomic, copy) NSString *link;

- (instancetype)initWithPageIndex:(NSInteger)pageIndex shapeId:(NSString *)shapeId link:(NSString *)link;

@end

NS_ASSUME_NONNULL_END 