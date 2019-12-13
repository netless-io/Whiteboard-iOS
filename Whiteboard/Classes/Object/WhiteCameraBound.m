//
//  CameraBound.m
//  WhiteSDK
//
//  Created by yleaf on 2019/9/5.
//

#import "WhiteCameraBound.h"

@interface WhiteContentModeConfig()

@property (nonatomic, assign, readwrite) WhiteContentMode contentMode;

@end

@implementation WhiteContentModeConfig


- (instancetype)initWithContentMode:(WhiteContentMode)scaleMode
{
    if (self = [super init]) {
        _scale = 1;
        _contentMode = scaleMode;
}
    return self;
}

//iOS 上用 UIKit 现有字段
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;
{
    return @{@"contentMode": @"mode"};
}

- (void)setScale:(CGFloat)scale
{
    NSAssert(_contentMode == WhiteContentModeScale || _contentMode == WhiteContentModeAspectFitScale || _contentMode == WhiteContentModeAspectFillScale, NSLocalizedString(@"该属性仅当 scaleMode 为 WhiteContentModeScale、WhiteContentModeAspectFitScale 时有效", nil));
    _scale = scale;
}

- (void)setSpace:(CGFloat)space
{
    NSAssert(_contentMode == WhiteContentModeAspectFitSpace, NSLocalizedString(@"该属性仅当 scaleMode 为 WhiteContentModeAspectFitSpace 时有效", nil));
    _space = space;
}

@end

@implementation WhiteCameraBound

@end
