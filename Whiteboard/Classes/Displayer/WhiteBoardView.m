//
//  WhiteBroadView.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteBoardView.h"
#import "WhiteBoardView+Private.h"
#import "WhiteObject.h"
#import "WhiteCommonCallbacks.h"
#import "WhiteCallBridgeCommand.h"
#import "BridgeCallRecorder.h"
#import "WhiteboardResourceLoader.h"

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

@interface WebConsoleInteruptScriptHandler: NSObject<WKScriptMessageHandler>
@property (nonatomic, copy) void (^handler)(WKScriptMessage *message);
@end

@implementation WebConsoleInteruptScriptHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.handler) {
        self.handler(message);
    }
}

@end

@interface WhiteBoardView ()

@property (nonatomic, strong) BridgeCallRecorder* recorder;
@property (nonatomic, copy) NSString* customResourceUrl;
@property (nonatomic, strong) WhiteboardLocalFileResourceLoader *resourceLoader;
@property (nonatomic, assign) BOOL enableHttpsScheme;
@property (nonatomic, assign) BOOL debugViewStateLoggingEnabled;
@property (nonatomic, copy) NSString *lastDebugViewStateSignature;
@property (nonatomic, strong) NSDate *lastDebugViewStateLogTime;
@property (nonatomic, strong) dispatch_source_t debugViewStateMonitorTimer;
@property (nonatomic, copy) NSString *lastDebugVisibilitySignature;

- (void)loadInitialResource;
- (void)installYouTubeIframeLayoutFixScript;
- (nullable NSString *)loadYouTubeIframeLayoutFixScriptTemplate;
- (instancetype)initWithFrame:(CGRect)frame
                 configuration:(WKWebViewConfiguration *)configuration
             customResourceUrl:(nullable NSString *)customResourceUrl
            enableHttpsScheme:(BOOL)enableHttpsScheme;

@end

@implementation WhiteBoardView

static const NSTimeInterval WhiteBoardViewDebugLogMinInterval = 1.5;
static const NSUInteger WhiteBoardViewDebugLogMaxTrackedSubviews = 8;
static const NSUInteger WhiteBoardViewDebugLogMaxSuperviewLevels = 4;
static const NSTimeInterval WhiteBoardViewDebugLogMonitorInterval = 4.0;
static const NSUInteger WhiteBoardViewDebugLogMaxLength = 2048;

- (instancetype)init {
    self = [self initWithEnableHttpsScheme:NO];
    return self;
}

- (instancetype)initCustomUrl:(nullable NSString *)customUrl {
    self = [self initCustomUrl:customUrl enableHttpsScheme:NO];
    return self;
}

- (instancetype)initWithEnableHttpsScheme:(BOOL)enableHttpsScheme {
    self = [self initCustomUrl:nil enableHttpsScheme:enableHttpsScheme];
    return self;
}

- (instancetype)initCustomUrl:(nullable NSString *)customUrl enableHttpsScheme:(BOOL)enableHttpsScheme {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self = [self initWithFrame:CGRectZero
                 configuration:configuration
             customResourceUrl:customUrl
            enableHttpsScheme:enableHttpsScheme];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    self = [self initWithFrame:frame
                 configuration:configuration
             customResourceUrl:nil
            enableHttpsScheme:NO];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                 configuration:(WKWebViewConfiguration *)configuration
             customResourceUrl:(nullable NSString *)customResourceUrl
            enableHttpsScheme:(BOOL)enableHttpsScheme
{
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    
    self = [super initWithFrame:frame configuration:configuration];
    if (!self) {
        return nil;
    }
    _customResourceUrl = [customResourceUrl copy];
    _enableHttpsScheme = enableHttpsScheme;
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    _commonCallbacks = [[WhiteCommonCallbacks alloc] init];
    [self addJavascriptObject:_commonCallbacks namespace:@"sdk"];
    [self installYouTubeIframeLayoutFixScript];
    
    self.scrollView.scrollEnabled = NO;
    
    self.recorder = [[BridgeCallRecorder alloc] initWithRecordKeys:@{
        @"sdk.newWhiteSdk": @(FALSE),
        @"sdk.updateNativeFontFaceCSS": @(FALSE),
        @"sdk.asyncInsertFontFaces": @(FALSE),
        @"sdk.updateNativeTextareaFont": @(FALSE),
        @"sdk.registerApp": @(TRUE),
        @"sdk.joinRoom": @(TRUE)
    }];
    if (self.enableHttpsScheme) {
        self.resourceLoader = [[WhiteboardLocalFileResourceLoader alloc] initWithWebView:self resourceBundle:[self whiteSDKBundle]];
    }
    [self loadInitialResource];
    
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

- (void)installYouTubeIframeLayoutFixScript {
#if DEBUG
    BOOL enableLogging = YES;
#else
    BOOL enableLogging = NO;
#endif
    NSString *scriptTemplate = [self loadYouTubeIframeLayoutFixScriptTemplate];
    if (scriptTemplate.length == 0) {
        return;
    }
    NSString *scriptSource = [scriptTemplate stringByReplacingOccurrencesOfString:@"__ENABLE_LOGGING__"
                                                                       withString:enableLogging ? @"true" : @"false"];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:scriptSource
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                               forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:script];
}

- (nullable NSString *)loadYouTubeIframeLayoutFixScriptTemplate {
    NSString *path = [[self whiteSDKBundle] pathForResource:@"youtube-iframe-layout-fix" ofType:@"js"];
    if (path.length == 0) {
        return nil;
    }
    NSError *error = nil;
    NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (script.length == 0 || error) {
        NSLog(@"load youtube-iframe-layout-fix.js failed: %@", error);
        return nil;
    }
    return script;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self white_stopDebugViewStateMonitor];
}

- (NSURL *)resourceURL {
    if (self.customResourceUrl) {
        return [NSURL URLWithString:self.customResourceUrl];
    }
    return [NSURL fileURLWithPath:[[self whiteSDKBundle] pathForResource:@"index" ofType:@"html"]];
}

- (void)reloadFromCrash:(void (^)(void))completionHandler {
    [self logDebugViewStateWithReason:@"reloadFromCrash.begin" force:YES];
    [self loadInitialResource];
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

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self logDebugViewStateWithReason:hidden ? @"setHidden:YES" : @"setHidden:NO" force:YES];
}

- (void)layoutSubviews {
    // workaround：WKWebView 空项目，不需要这么操作，只需要 opaque 设置后即可，不知道为何在当前项目，会有一个白色的 OverlayView 一瞬间出现在最前面。
    if (self.backgroundColor && self.subviews.count > 0) {
        self.subviews.lastObject.backgroundColor = self.backgroundColor;
    }
    [super layoutSubviews];
    [self logDebugViewStateWithReason:@"layoutSubviews" force:NO];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self logDebugViewStateWithReason:@"didMoveToSuperview" force:YES];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self logDebugViewStateWithReason:@"didMoveToWindow" force:YES];
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
    WebConsoleInteruptScriptHandler *handler = [[WebConsoleInteruptScriptHandler alloc] init];
    __weak typeof(self) weakSelf = self;
    handler.handler = ^(WKScriptMessage *message) {
        [weakSelf.commonCallbacks logger:@{
            @"[WhiteWKConsole]": message.body
        }];
    };
    [self.configuration.userContentController addScriptMessageHandler:handler name:@"_netless_web_console_log_"];
}

- (void)setDebugViewStateLoggingEnabled:(BOOL)enabled {
    _debugViewStateLoggingEnabled = enabled;
    [self white_updateDebugViewStateMonitor];
    if (enabled) {
        self.lastDebugViewStateSignature = nil;
        self.lastDebugViewStateLogTime = nil;
        self.lastDebugVisibilitySignature = nil;
        [self logDebugViewStateWithReason:@"debugLoggingEnabled" force:YES];
    }
}

- (void)logDebugViewStateWithReason:(NSString *)reason force:(BOOL)force {
    if (!self.debugViewStateLoggingEnabled) {
        return;
    }

    UIView *superview = self.superview;
    NSString *frameString = NSStringFromCGRect(self.frame);
    NSString *boundsString = NSStringFromCGRect(self.bounds);
    NSString *superviewBoundsString = superview ? NSStringFromCGRect(superview.bounds) : @"nil";
    NSString *superviewClassName = superview ? NSStringFromClass(superview.class) : @"nil";
    NSString *superviewAlphaSignature = superview ? [NSString stringWithFormat:@"%.3f", superview.alpha] : @"nil";
    NSString *superviewHiddenSignature = superview ? (superview.isHidden ? @"1" : @"0") : @"nil";
    NSString *superviewHierarchySignature = [self white_debugSuperviewSignature:superview];
    NSString *signature = [NSString stringWithFormat:@"%@|%.3f|%@|%@|%@|%@|%@|%@",
                           frameString,
                           self.alpha,
                           self.isHidden ? @"1" : @"0",
                           self.window ? @"1" : @"0",
                           superviewClassName,
                           superviewBoundsString,
                           superviewAlphaSignature,
                           superviewHiddenSignature,
                           superviewHierarchySignature];

    NSDate *now = [NSDate date];
    if (!force) {
        if ([signature isEqualToString:self.lastDebugViewStateSignature]) {
            return;
        }
        if (self.lastDebugViewStateLogTime && [now timeIntervalSinceDate:self.lastDebugViewStateLogTime] < WhiteBoardViewDebugLogMinInterval) {
            return;
        }
    }

    self.lastDebugViewStateSignature = signature;
    self.lastDebugViewStateLogTime = now;

    NSString *payload = [NSString stringWithFormat:@"VIEW_STATE: reason=%@, frame=%@, bounds=%@, alpha=%.3f, hidden=%@, opaque=%@, backgroundColor=%@, windowAttached=%@, superviewClass=%@, superviewBounds=%@, superviewAlpha=%@, superviewHidden=%@, superviewHierarchy=%@",
                         reason ?: @"unknown",
                         frameString,
                         boundsString,
                         self.alpha,
                         self.isHidden ? @"YES" : @"NO",
                         self.opaque ? @"YES" : @"NO",
                         self.backgroundColor.description ?: @"nil",
                         self.window ? @"YES" : @"NO",
                         superviewClassName,
                         superviewBoundsString,
                         superview ? [NSString stringWithFormat:@"%.3f", superview.alpha] : @"nil",
                         superview ? (superview.isHidden ? @"YES" : @"NO") : @"nil",
                         [self white_debugSuperviewSummary:superview]];
    payload = [self white_truncatedDebugLogString:payload];
    [self.commonCallbacks logger:@{
        @"[WhiteWKConsole]": payload
    }];
}

- (NSString *)white_truncatedDebugLogString:(NSString *)logString {
    if (!logString || logString.length <= WhiteBoardViewDebugLogMaxLength) {
        return logString ?: @"";
    }

    static NSString *suffix = @" ...(truncated)";
    NSUInteger maxContentLength = WhiteBoardViewDebugLogMaxLength > suffix.length ? (WhiteBoardViewDebugLogMaxLength - suffix.length) : 0;
    if (maxContentLength == 0) {
        return [suffix substringToIndex:MIN(suffix.length, WhiteBoardViewDebugLogMaxLength)];
    }
    return [[logString substringToIndex:maxContentLength] stringByAppendingString:suffix];
}

- (NSString *)white_debugSuperviewSummary:(UIView *)superview {
    if (!superview) {
        return @"level0:nil";
    }

    NSMutableArray<NSString *> *levels = [NSMutableArray array];
    UIView *currentSuperview = superview;
    NSUInteger level = 1;
    while (currentSuperview && level <= WhiteBoardViewDebugLogMaxSuperviewLevels) {
        NSString *className = NSStringFromClass(currentSuperview.class) ?: @"nil";
        NSString *boundsString = NSStringFromCGRect(currentSuperview.bounds);
        [levels addObject:[NSString stringWithFormat:@"level%lu:%@ bounds=%@ alpha=%.3f hidden=%@",
                           (unsigned long)level,
                           className,
                           boundsString,
                           currentSuperview.alpha,
                           currentSuperview.isHidden ? @"YES" : @"NO"]];
        currentSuperview = currentSuperview.superview;
        level += 1;
    }

    if (levels.count == 0) {
        return @"level0:nil";
    }
    if (currentSuperview) {
        [levels addObject:@"... more superviews"];
    }
    return [levels componentsJoinedByString:@" || "];
}

- (NSString *)white_debugSuperviewSignature:(UIView *)superview {
    if (!superview) {
        return @"level0:nil";
    }

    NSMutableArray<NSString *> *levels = [NSMutableArray array];
    UIView *currentSuperview = superview;
    NSUInteger level = 1;
    while (currentSuperview && level <= WhiteBoardViewDebugLogMaxSuperviewLevels) {
        [levels addObject:[NSString stringWithFormat:@"level%lu:%@:%@:%@:%@",
                           (unsigned long)level,
                           NSStringFromClass(currentSuperview.class) ?: @"nil",
                           currentSuperview.isHidden ? @"1" : @"0",
                           [NSString stringWithFormat:@"%.3f", currentSuperview.alpha],
                           NSStringFromCGRect(currentSuperview.bounds)]];
        currentSuperview = currentSuperview.superview;
        level += 1;
    }
    if (currentSuperview) {
        [levels addObject:@"more"];
    }
    return [levels componentsJoinedByString:@"|"];
}

- (void)white_updateDebugViewStateMonitor {
    if (!self.debugViewStateLoggingEnabled) {
        [self white_stopDebugViewStateMonitor];
        return;
    }

    if (self.debugViewStateMonitorTimer) {
        return;
    }

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (!timer) {
        return;
    }
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WhiteBoardViewDebugLogMonitorInterval * NSEC_PER_SEC)),
                              (uint64_t)(WhiteBoardViewDebugLogMonitorInterval * NSEC_PER_SEC),
                              (uint64_t)(0.1 * NSEC_PER_SEC));
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.debugViewStateLoggingEnabled) {
            return;
        }
        [strongSelf white_checkVisibilityChange];
    });
    dispatch_resume(timer);
    self.debugViewStateMonitorTimer = timer;
}

- (void)white_stopDebugViewStateMonitor {
    if (self.debugViewStateMonitorTimer) {
        dispatch_source_cancel(self.debugViewStateMonitorTimer);
        self.debugViewStateMonitorTimer = nil;
    }
}

- (NSString *)white_visibilitySignature {
    NSMutableString *sig = [NSMutableString stringWithFormat:@"%@|%.3f",
                            self.isHidden ? @"H" : @"V",
                            self.alpha];
    UIView *ancestor = self.superview;
    NSUInteger level = 0;
    while (ancestor && level < WhiteBoardViewDebugLogMaxSuperviewLevels) {
        [sig appendFormat:@"|%@:%.3f",
         ancestor.isHidden ? @"H" : @"V",
         ancestor.alpha];
        ancestor = ancestor.superview;
        level += 1;
    }
    return [sig copy];
}

- (void)white_checkVisibilityChange {
    NSString *currentSig = [self white_visibilitySignature];
    if ([currentSig isEqualToString:self.lastDebugVisibilitySignature]) {
        return;
    }
    self.lastDebugVisibilitySignature = currentSig;
    [self logDebugViewStateWithReason:@"visibilityChanged" force:YES];
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
    if (self.debugViewStateLoggingEnabled) {
        NSString *payload = [NSString stringWithFormat:@"VIEW_STATE: reason=setBackgroundColor, backgroundColor=%@",
                             self.backgroundColor.description ?: @"nil"];
        [self.commonCallbacks logger:@{
            @"[WhiteWKConsole]": payload
        }];
    }
    
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

-(void)loadInitialResource
{
    [self logDebugViewStateWithReason:@"loadInitialResource" force:YES];
    NSURL *url = [self resourceURL];
    if (self.enableHttpsScheme && self.resourceLoader) {
        NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"localhost";
        NSString *baseURLString = [NSString stringWithFormat:@"https://%@", bundleId];
        NSURL *baseURL = [NSURL URLWithString:baseURLString];
        [self.resourceLoader loadResourceURL:url baseURL:baseURL];
        return;
    }
    [self loadRequest:[NSURLRequest requestWithURL:url]];
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
