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
        _enableGlobalClick = YES;
        _minFPS = @25;
        _maxFPS = @30;
        _resolution = @1;
        _maxResolution = @2;
        _forceCanvas = FALSE;
        _bgColor = nil;
    }
    return self;
}

@end
