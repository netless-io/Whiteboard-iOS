//
//  WhiteDisplayer.m
//  WhiteSDK
//
//  Created by yleaf on 2019/7/1.
//

#import "WhiteDisplayer.h"
#import "WhiteDisplayer+Private.h"

@interface WhiteDisplayer ()
@end

@implementation WhiteDisplayer

- (instancetype)initWithUuid:(NSString *)uuid bridge:(WhiteBoardView *)bridge
{
    self = [super init];
    if (self) {
        _bridge = bridge;
        _backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor ? : [UIColor whiteColor];
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;
    
    [backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    
    NSUInteger R = floorf(r * 255.0);
    NSUInteger G = floorf(g * 255.0);
    NSUInteger B = floorf(b * 255.0);
    //fix issue: iOS 10/11 rgb css don's support float
    [self.bridge callHandler:@"displayer.setBackgroundColor" arguments:@[@(R), @(G), @(B), @(a * 255.0)]];
}

#pragma mark - 视角
- (void)setCameraBound:(WhiteCameraBound *)cameraBound
{
    [self.bridge callHandler:@"displayer.setCameraBound" arguments:@[cameraBound]];
}

- (void)moveCamera:(WhiteCameraConfig *)camera
{
    [self.bridge callHandler:@"displayer.moveCamera" arguments:@[camera]];
}

- (void)moveCameraToContainer:(WhiteRectangleConfig *)rectange
{
    [self.bridge callHandler:@"displayer.moveCameraToContain" arguments:@[rectange]];
}

# pragma mark - Common

- (void)refreshViewSize
{
    [self.bridge callHandler:@"displayer.refreshViewSize" completionHandler:nil];
}

- (void)convertToPointInWorld:(WhitePanEvent *)point result:(void (^) (WhitePanEvent *convertPoint))result;
{
    [self.bridge callHandler:@"displayer.convertToPointInWorld" arguments:@[@(point.x), @(point.y)] completionHandler:^(id  _Nullable value) {
        if (result) {
            WhitePanEvent *convertP = [WhitePanEvent modelWithJSON:value];
            result(convertP);
        }
    }];
}

#pragma mark - 自定义事件

- (void)addMagixEventListener:(NSString *)eventName
{
    [self.bridge callHandler:@"displayer.addMagixEventListener" arguments:@[eventName]];
}

- (void)addHighFrequencyEventListener:(NSString *)eventName fireInterval:(NSUInteger)millseconds
{
    NSAssert(millseconds >= 500, @"millsecond should not less than 500");
    [self.bridge callHandler:@"displayer.addHighFrequencyEventListener" arguments:@[eventName, @(millseconds)]];
}

- (void)removeMagixEventListener:(NSString *)eventName
{
    [self.bridge callHandler:@"displayer.removeMagixEventListener" arguments:@[eventName]];
}

#pragma mark - 截图图片 API
- (void)getScenePreviewImage:(NSString *)scenePath completion:(void (^)(UIImage * _Nullable image))completionHandler
{
    [self.bridge callHandler:@"displayerAsync.scenePreview" arguments:@[scenePath] completionHandler:^(NSString * _Nullable value) {
        NSString *imageData = [value stringByReplacingOccurrencesOfString:@"data:image/png;base64," withString:@""];
        NSData *data = [[NSData alloc] initWithBase64EncodedString:imageData options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
        if (completionHandler) {
            completionHandler(image);
        }
    }];
}

- (void)getSceneSnapshotImage:(NSString *)scenePath completion:(void (^)(UIImage * _Nullable image))completionHandler
{
    [self.bridge callHandler:@"displayerAsync.sceneSnapshot" arguments:@[scenePath] completionHandler:^(NSString * _Nullable value) {
        NSString *imageData = [value stringByReplacingOccurrencesOfString:@"data:image/png;base64," withString:@""];
        NSData *data = [[NSData alloc] initWithBase64EncodedString:imageData options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
        if (completionHandler) {
            completionHandler(image);
        }
    }];
}

@end
