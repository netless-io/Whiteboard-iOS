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

@synthesize chessboard = _chessboard;
@synthesize fullscreen = _fullscreen;
@synthesize debug = _debug;
@synthesize polling = _polling;
@synthesize useBoxesStatus = _useBoxesStatus;
@synthesize forceMaximized = _forceMaximized;
@synthesize lazySetupInMaximizedMode = _lazySetupInMaximizedMode;
@synthesize overwriteStyles = _overwriteStyles;
@synthesize containerSizeRatio = _containerSizeRatio;
@synthesize prefersColorScheme = _prefersColorScheme;

- (instancetype)init {
    self = [super init];
    _chessboard = YES;
    _containerSizeRatio = @(9/16.0);
    _debug = YES;
    _fullscreen = NO;
    _prefersColorScheme = WhitePrefersColorSchemeLight;
    _polling = NO;
    _useBoxesStatus = NO;
    _forceMaximized = NO;
    _lazySetupInMaximizedMode = NO;
    _overwriteStyles = @"";
    return self;
}

- (void)setContainerSizeRatio:(NSNumber *)containerSizeRatio {
    if (isinf([containerSizeRatio doubleValue])) { return; }
    if (isnan([containerSizeRatio doubleValue])) { return; }
    _containerSizeRatio = containerSizeRatio;
    [self white_markExplicitConfigurationKey:@"containerSizeRatio"];
}

- (void)setPrefersColorScheme:(WhitePrefersColorScheme)prefersColorScheme {
    if (@available(iOS 13, *)) {
        _prefersColorScheme = prefersColorScheme;
        [self white_markExplicitConfigurationKey:@"prefersColorScheme"];
    } else if ([prefersColorScheme isEqualToString:WhitePrefersColorSchemeAuto]) {
        NSLog(@"WhitePrefersColorSchemeAuto is not available before iOS 13");
        return;
    } else {
        _prefersColorScheme = prefersColorScheme;
        [self white_markExplicitConfigurationKey:@"prefersColorScheme"];
    }
}


- (void)setChessboard:(BOOL)chessboard
{
    _chessboard = chessboard;
    [self white_markExplicitConfigurationKey:@"chessboard"];
}


- (void)setFullscreen:(BOOL)fullscreen
{
    _fullscreen = fullscreen;
    [self white_markExplicitConfigurationKey:@"fullscreen"];
}


- (void)setDebug:(BOOL)debug
{
    _debug = debug;
    [self white_markExplicitConfigurationKey:@"debug"];
}


- (void)setPolling:(BOOL)polling
{
    _polling = polling;
    [self white_markExplicitConfigurationKey:@"polling"];
}


- (void)setUseBoxesStatus:(BOOL)useBoxesStatus
{
    _useBoxesStatus = useBoxesStatus;
    [self white_markExplicitConfigurationKey:@"useBoxesStatus"];
}


- (void)setForceMaximized:(BOOL)forceMaximized
{
    _forceMaximized = forceMaximized;
    [self white_markExplicitConfigurationKey:@"forceMaximized"];
}


- (void)setLazySetupInMaximizedMode:(BOOL)lazySetupInMaximizedMode
{
    _lazySetupInMaximizedMode = lazySetupInMaximizedMode;
    [self white_markExplicitConfigurationKey:@"lazySetupInMaximizedMode"];
}


- (void)setOverwriteStyles:(NSString *)overwriteStyles
{
    _overwriteStyles = [overwriteStyles copy];
    [self white_markExplicitConfigurationKey:@"overwriteStyles"];
}

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic
{
    [self white_addDefaultConfigurationKeys:@[@"chessboard", @"fullscreen", @"debug", @"polling", @"useBoxesStatus", @"forceMaximized", @"lazySetupInMaximizedMode", @"overwriteStyles", @"containerSizeRatio", @"prefersColorScheme"] toDictionary:dic];
    return YES;
}

@end
