//
//  WhiteBroadView.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteBoardView.h"
#import "WhiteBoardView+Private.h"
#import "WhiteWebViewInjection.h"
#import "WhiteObject.h"
#import "WhiteCommonCallbacks.h"
#import "WhiteCallBridgeCommand.h"
#import "BridgeCallRecorder.h"

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

@interface WhiteBoardView ()

@property (nonatomic, strong) BridgeCallRecorder* recorder;

@end

@implementation WhiteBoardView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)dealloc
{
    [WhiteWebViewInjection allowDisplayingKeyboardWithoutUserAction:FALSE];
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    
    self = [super initWithFrame:frame configuration:configuration];
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    _commonCallbacks = [[WhiteCommonCallbacks alloc] init];
    [self addJavascriptObject:_commonCallbacks namespace:@"sdk"];
    
    [WhiteWebViewInjection allowDisplayingKeyboardWithoutUserAction:TRUE];
    self.scrollView.scrollEnabled = NO;
    
    self.recorder = [[BridgeCallRecorder alloc] initWithRecordKeys:@{
        @"sdk.newWhiteSdk": @(FALSE),
        @"sdk.updateNativeFontFaceCSS": @(FALSE),
        @"sdk.asyncInsertFontFaces": @(FALSE),
        @"sdk.updateNativeTextareaFont": @(FALSE),
        @"sdk.registerApp": @(TRUE),
        @"sdk.joinRoom": @(TRUE)
    }];
    
    [self loadRequest:[NSURLRequest requestWithURL:[self resourceURL]]];
    
#if DEBUG
    if (@available(iOS 16.4, *)) {
        self.inspectable = YES;
    } else {
        // Fallback on earlier versions
    }
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHandler:) name:UIKeyboardWillChangeFrameNotification object:nil];
    return self;
}

- (NSURL *)resourceURL {
    return [NSURL fileURLWithPath:[[self whiteSDKBundle] pathForResource:@"index" ofType:@"html"]];
}

- (void)reloadFromCrash:(void (^)(void))completionHandler {
    [self loadUrl:[self.resourceURL absoluteString]];
    [self.recorder resumeCommandsFromBridgeView:self completionHandler:completionHandler];
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

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self autoRefresh];
}

- (void)layoutSubviews {
    // workaround：WKWebView 空项目，不需要这么操作，只需要 opaque 设置后即可，不知道为何在当前项目，会有一个白色的 OverlayView 一瞬间出现在最前面。
    if (self.backgroundColor && self.subviews.count > 0) {
        self.subviews.lastObject.backgroundColor = self.backgroundColor;
    }
    [super layoutSubviews];
}

- (void)autoRefresh
{
    if (self.room || self.player) {
        [self callHandler:@"displayer.refreshViewSize" arguments:nil];
    }
}

#pragma mark - Private.h Methods
- (void)setupWebSDKWithConfig:(WhiteSdkConfiguration *)config completion:(void (^) (id _Nullable value))completionHandler
{
    [self callHandler:@"sdk.newWhiteSdk" arguments:@[config] completionHandler:nil];
}

- (void)observeWKWebViewConsole {
    NSString *logCaptureJsScript = @"\
let oLog = console.log;\
let oWarn = console.warn;\
let oError = console.error;\
let oDebug = console.debug;\
function oneLevelObjectPrint(key, value) {\
  if (key.length === 0) { return value; }\
  if (typeof value === 'object') { return `[Object], ${key}`; }\
  return value;\
}\
function log(type, args) {\
      window.webkit.messageHandlers._netless_web_console_log_.postMessage(\
      `${type}: ${Object.values(args)\
      .map(v=> {\
          if (typeof(v) === 'undefined') {\
              return 'undefined';\
          };\
          if (typeof(v) === 'object') {\
              if (v instanceof Error) {\
                  return JSON.stringify(v, Object.getOwnPropertyNames(v));\
              }\
              return JSON.stringify(v, oneLevelObjectPrint);\
          }\
          return v.toString();\
      })\
      .map(v => v.substring(0, 3000))\
      .join(', ')}`\
  )\
}\
console.log = function() {\
    log('LOG', arguments);oLog.apply(null, arguments);\
};\
console.warn = function() {\
    log('WARN', arguments);oWarn.apply(null, arguments);\
};\
console.error = function() {\
    log('ERROR', arguments);oError.apply(null, arguments);\
};\
console.debug = function() {\
    log('DEBUG', arguments);oDebug.apply(null, arguments);\
};\
window.addEventListener('error', function(e) {\
    log('UNCAUGHT', [`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`]);\
    window.e = e;\
});\
    ";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:logCaptureJsScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:script];
    [self.configuration.userContentController addScriptMessageHandler:self name:@"_netless_web_console_log_"];
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    [self.commonCallbacks logger: @{
        @"[WhiteWKConsole]": message.body
    }];
}

#pragma mark - Override
-(void)callHandler:(NSString *)methodName arguments:(NSArray *)args completionHandler:(void (^)(id  _Nullable value))completionHandler
{
    WhiteCallBridgeCommand *command = [[WhiteCallBridgeCommand alloc] init];
    command.method = methodName;
    if (!args) {
        dispatch_main_async_safe(^ {
            [super callHandler:methodName arguments:args completionHandler:completionHandler];
        });
        command.args = @[];
        [self.recorder receiveCommand:command];
        return ;
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
            [arr addObject:([item _white_yy_modelToJSONObject] ? : @"")];
        }
    }
    dispatch_main_async_safe(^ {
        [super callHandler:methodName arguments:arr completionHandler:completionHandler];
    });
    
    command.args = arr;
    [self.recorder receiveCommand:command];
    return ;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    
    if (self.room || self.player) {
        CGFloat r;
        CGFloat g;
        CGFloat b;
        CGFloat a;
        
        [backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        
        //fix issue: iOS 10/11 rgb css don's support float
        NSUInteger R = floorf(r * 255.0);
        NSUInteger G = floorf(g * 255.0);
        NSUInteger B = floorf(b * 255.0);
        NSString *js = [NSString stringWithFormat:@"setBackgroundColor(%@, %@, %@)", @(R), @(G), @(B)];
        __weak typeof(self) weakSelf = self;
        [self evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (!error) {
                weakSelf.opaque = YES;
            }
        }];
    } else {
        self.opaque = NO;
    }
}


//#pragma mark - Private Methods
- (NSBundle *)whiteSDKBundle
{
    // 1. 脱离 Cocoapods 时，打包成同名 bundle 就可以保证读取一致性
    // 2. 使用字符串，是为了保证使用子类时，self calss 的路径不会变化
    NSBundle *podBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:NSClassFromString(@"WhiteBoardView")] pathForResource:@"Whiteboard" ofType:@"bundle"]];
    if (podBundle) {
        return podBundle;
    } else {
        // SPM bundle
        return [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Whiteboard_Whiteboard" ofType:@"bundle"]];
    }
}

@end
