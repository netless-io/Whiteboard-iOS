//
//  WhiteBroadView.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteBoardView.h"
#import "WhiteBoardView+Private.h"
#import "WhiteWebViewInjection.h"
#import <YYModel/YYModel.h>
#import "WhiteObject.h"
#import "WhiteCommonCallbacks.h"

@implementation WhiteBoardView

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (void)dealloc
{
    [WhiteWebViewInjection allowDisplayingKeyboardWithoutUserAction:FALSE];
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    configuration.allowsInlineMediaPlayback = YES;
    NSOperatingSystemVersion iOS_10_0_0 = (NSOperatingSystemVersion){10, 0, 0};
    NSOperatingSystemVersion iOS_11_0_0 = (NSOperatingSystemVersion){11, 0, 0};

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_10_0_0] && [configuration respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]) {
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
#if defined(__LP64__) && __LP64__
        [configuration setValue:@"TRUE" forKey:@"allowUniversalAccessFromFileURLs"];
#else
        //32位 CPU 支持：https://www.jianshu.com/p/fe876b9d1f7c
        [configuration setValue:@(1) forKey:@"allowUniversalAccessFromFileURLs"];
#endif
    } else {
        // Fallback on earlier versions
    }

    self = [super initWithFrame:frame configuration:configuration];

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_11_0_0] && [self.scrollView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    _commonCallbacks = [[WhiteCommonCallbacks alloc] init];
    [self addJavascriptObject:_commonCallbacks namespace:@"sdk"];
    
    [WhiteWebViewInjection allowDisplayingKeyboardWithoutUserAction:TRUE];
    self.scrollView.scrollEnabled = NO;
    
    NSURL *html = [NSURL fileURLWithPath:[[self whiteSDKBundle] pathForResource:@"index" ofType:@"html"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:html];
    [self loadRequest:request];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHandler:) name:UIKeyboardWillChangeFrameNotification object:nil];
    return self;
}

#pragma mark - Keyboard Notification
- (void)keyboardHandler:(NSNotification *)notification
{
    if (self.disableKeyboardHandler) {
        return;
    }
    
    CGPoint offset = self.scrollView.contentOffset;
    if (offset.y != 0) {
        NSDictionary *userInfo = notification.userInfo;
        NSTimeInterval interval = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        //适配第三方输入法主动修改自身大小的行为
        if (CGRectGetMaxY(beginFrame) == CGRectGetMinY(endFrame)) {
            [UIView animateWithDuration:interval animations:^{
                self.scrollView.contentOffset = CGPointMake(offset.x, 0);
            }];
        }
    }
}

#pragma mark - Private.h Methods
- (void)setupWebSDKWithConfig:(WhiteSdkConfiguration *)config completion:(void (^) (id _Nullable value))completionHandler
{
    [self callHandler:@"sdk.newWhiteSdk" arguments:@[config] completionHandler:nil];
}

#pragma mark - Override
-(void)callHandler:(NSString *)methodName arguments:(NSArray *)args completionHandler:(void (^)(id  _Nullable value))completionHandler
{
    if (!args) {
        [super callHandler:methodName arguments:args completionHandler:completionHandler];
        return;
    }
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[args count]];
    for (NSObject *item in args) {
        if ([item isKindOfClass:[NSString class]]) {
            [arr addObject:item];
        } else if ([item isKindOfClass:[NSNumber class]]) {
            [arr addObject:item];
        } else if ([item isKindOfClass:[WhiteObject class]]) {
            [arr addObject:[(WhiteObject *)item jsonDict]];
        } else {
            [arr addObject:([item yy_modelToJSONObject] ? : @"")];
        }
    }
    [super callHandler:methodName arguments:arr completionHandler:completionHandler];
}

#pragma mark - Private Methods
- (NSBundle *)whiteSDKBundle
{
    // 脱离 Cocoapods 时，打包成同名 bundle 就可以保证读取一致性
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"Whiteboard" ofType:@"bundle"]];
}

@end
