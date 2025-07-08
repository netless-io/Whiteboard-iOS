#import "WhiteSlideCustomLink.h"

@implementation WhiteSlideCustomLink

- (instancetype)initWithPageIndex:(NSInteger)pageIndex shapeId:(NSString *)shapeId link:(NSString *)link {
    self = [super init];
    if (self) {
        _pageIndex = pageIndex;
        _shapeId = shapeId;
        _link = link;
    }
    return self;
}

@end 