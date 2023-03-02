//
//  WhiteSlideAppParams.m
//  Whiteboard
//
//  Created by xuyunshi on 2023/3/2.
//

#import "WhiteSlideAppParams.h"

@implementation WhiteSlideAppParams

- (instancetype)init
{
    self = [super init];
    if (self) {
        _showRenderError = NO;
        _debug = NO;
    }
    return self;
}

@end
