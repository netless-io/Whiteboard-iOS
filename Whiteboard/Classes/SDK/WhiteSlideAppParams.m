//
//  WhiteSlideAppParams.m
//  Whiteboard
//
//  Created by xuyunshi on 2023/3/2.
//

#import "WhiteSlideAppParams.h"

PPTInvisibleBehaviorKey const PPTInvisibleBehaviorKeyFrozen = @"frozen";
PPTInvisibleBehaviorKey const PPTInvisibleBehaviorKeyPause = @"pause";

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
        _maxResolutionLevel = @2;
        _forceCanvas = FALSE;
        _bgColor = nil;
        _invisibleBehavior = nil;
    }
    return self;
}

@end
