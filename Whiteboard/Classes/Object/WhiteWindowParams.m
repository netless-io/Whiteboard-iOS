//
//  WhiteWindowParams.m
//  Whiteboard
//
//  Created by yleaf on 2022/2/9.
//

#import "WhiteWindowParams.h"

WhitePrefersColorScheme const WhitePrefersColorSchemeAuto = @"auto";
WhitePrefersColorScheme const WhitePrefersColorSchemeLight = @"light";
WhitePrefersColorScheme const WhitePrefersColorSchemeDark = @"dark";

@interface WhiteWindowOriginSize ()
@property (nonatomic, assign, readwrite) CGFloat width;
@property (nonatomic, assign, readwrite) CGFloat height;
@end

@implementation WhiteWindowOriginSize

- (instancetype)initWithWidth:(CGFloat)width height:(CGFloat)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
    }
    return self;
}

@end

@implementation WhiteWindowPageScaleRange
@end

@implementation WhiteWindowParams

- (instancetype)init {
    self = [super init];
    _chessboard = YES;
    _containerSizeRatio = @(9/16.0);
    _debug = YES;
    _fullscreen = NO;
    _prefersColorScheme = WhitePrefersColorSchemeLight;
    _polling = NO;
    _useBoxesStatus = NO;
    _overwriteStyles = @"";
    return self;
}

- (void)setContainerSizeRatio:(NSNumber *)containerSizeRatio {
    if (isinf([containerSizeRatio doubleValue])) { return; }
    if (isnan([containerSizeRatio doubleValue])) { return; }
    _containerSizeRatio = containerSizeRatio;
}

- (void)setPrefersColorScheme:(WhitePrefersColorScheme)prefersColorScheme {
    if (@available(iOS 13, *)) {
        _prefersColorScheme = prefersColorScheme;
    } else if ([prefersColorScheme isEqualToString:WhitePrefersColorSchemeAuto]) {
        NSLog(@"WhitePrefersColorSchemeAuto is not available before iOS 13");
        return;
    } else {
        _prefersColorScheme = prefersColorScheme;
    }
}

@end
