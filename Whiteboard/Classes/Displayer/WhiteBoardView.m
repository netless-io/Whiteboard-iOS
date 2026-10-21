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

@interface NTLDWKWebView (WhiteLifecycleIncoming)
- (NSString *)call:(NSString *)method :(NSString *)arguments;
- (void)resetCallInfoList;
@end

@interface WhiteScopedBridge : NSProxy
@property (nonatomic, weak) WhiteBoardView *target;
@property (nonatomic, strong) NSNumber *generation;
@end

@interface WhiteReplacement : NSObject
@property (nonatomic, strong) WhiteBoardView *host;
@property (nonatomic, copy) NSString *identity;
@property (nonatomic, copy) void (^start)(NSNumber *);
@property (nonatomic, strong) NSNumber *generation;
@property (nonatomic, copy) void (^failure)(NSError *);
@property (nonatomic) BOOL waiting;
@end
@implementation WhiteReplacement
@end

static NSMutableDictionary<NSString *, WhiteBoardView *> *WhiteOwners(void) {
    static NSMutableDictionary *owners; static dispatch_once_t once;
    dispatch_once(&once, ^{ owners = [NSMutableDictionary dictionary]; }); return owners;
}
static NSMutableDictionary<NSString *, WhiteReplacement *> *WhiteReplacements(void) {
    static NSMutableDictionary *requests; static dispatch_once_t once;
    dispatch_once(&once, ^{ requests = [NSMutableDictionary dictionary]; }); return requests;
}

@interface WhiteBoardView ()

@property (nonatomic, strong) BridgeCallRecorder* recorder;
@property (nonatomic) BOOL whiteSdkClaimed;
@property (nonatomic) BOOL whiteInvalid;
@property (nonatomic, copy) NSString *whiteDocument;
@property (nonatomic, copy) NSString *whiteState;
@property (nonatomic, strong) NSNumber *whiteGeneration;
@property (nonatomic, copy) void (^whitePending)(NSError *);
@property (nonatomic, strong) NSMutableArray *whiteReady;
@property (nonatomic, strong) NSMutableArray *whiteCloseCallbacks;
@property (nonatomic, strong) NSError *whiteCloseError;
@property (nonatomic) BOOL whiteCloseCompleted;
@property (nonatomic, copy) NSArray *whiteSdkInitArgs;
@property (nonatomic, strong) WhiteReplacement *whiteReplacement;
@property (nonatomic, copy) NSString *whiteIdentity;
- (void)whiteCall:(NSString *)method arguments:(NSArray *)args generation:(NSNumber *)generation completion:(void (^)(id))completion;

@property (nonatomic, copy) NSString* customResourceUrl;
@property (nonatomic, strong) WhiteboardLocalFileResourceLoader *resourceLoader;
@property (nonatomic, assign) BOOL enableHttpsScheme;
@property (nonatomic, assign) BOOL debugViewStateLoggingEnabled;
@property (nonatomic, copy) NSString *lastDebugViewStateSignature;
@property (nonatomic, strong) NSDate *lastDebugViewStateLogTime;
@property (nonatomic, strong) dispatch_source_t debugViewStateMonitorTimer;
@property (nonatomic, copy) NSString *lastDebugVisibilitySignature;

- (void)loadInitialResource;
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
    _whiteState = @"idle";
    _whiteGeneration = @0;
    _whiteReady = [NSMutableArray array];
    _customResourceUrl = [customResourceUrl copy];
    _enableHttpsScheme = enableHttpsScheme;
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    _commonCallbacks = [[WhiteCommonCallbacks alloc] init];
    [self addJavascriptObject:_commonCallbacks namespace:@"sdk"];
    
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
    // The old transport cannot be certified closed after a renderer exit. Never replay join implicitly.
    [self whiteInvalidate];
    if (completionHandler) completionHandler();
}

static NSError *WhiteLifecycleError(NSString *message) {
    return [NSError errorWithDomain:@"WhiteLifecycle" code:-1100 userInfo:@{NSLocalizedDescriptionKey: message ?: @"LifecycleError"}];
}
static id WhiteLifecycleFailure(NSString *message) {
    NSDictionary *value = @{@"__error": @{@"message": message ?: @"LifecycleError"}};
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:value options:0 error:nil] encoding:NSUTF8StringEncoding];
}
- (BOOL)whiteClaimSdk {
    @synchronized (self) {
        if (self.whiteInvalid) return NO;
        if (self.whiteSdkClaimed) return YES;
        self.whiteSdkClaimed = YES;
    }
    [self whiteHandshake:NO];
    return YES;
}
- (BOOL)whiteReplacementIsCurrent:(WhiteReplacement *)request {
    return request.waiting && self.whiteReplacement == request && WhiteReplacements()[request.identity] == request;
}
- (void)whiteCancelReplacement:(WhiteReplacement *)request {
    if (!request.waiting) return;
    request.waiting = NO;
    if (WhiteReplacements()[request.identity] == request) [WhiteReplacements() removeObjectForKey:request.identity];
    if (request.host.whiteReplacement == request) request.host.whiteReplacement = nil;
    request.failure(WhiteLifecycleError(@"Cancelled"));
}
- (void)whiteFinishReplacement:(WhiteReplacement *)request error:(NSError *)error {
    if (![self whiteReplacementIsCurrent:request]) return;
    request.waiting = NO; [WhiteReplacements() removeObjectForKey:request.identity]; self.whiteReplacement = nil;
    if (error) request.failure(error);
    else { WhiteOwners()[request.identity] = self; self.whiteIdentity = request.identity; request.start(request.generation); }
}
- (BOOL)whiteCanConfigureCallbacks {
    return [self.whiteState isEqualToString:@"idle"] && !self.whiteReplacement;
}
- (void)whiteReplaceRoom:(NSString *)identity configuration:(NSDictionary *)configuration timeout:(NSTimeInterval)timeout bind:(void (^)(void))bind start:(void (^)(NSNumber *))start failure:(void (^)(NSError *))failure {
    dispatch_async(dispatch_get_main_queue(), ^{
        WhiteReplacement *request = [WhiteReplacement new]; request.host = self; request.identity = identity;
        request.start = start; request.failure = failure; request.waiting = YES;
        WhiteReplacement *previous = WhiteReplacements()[identity]; WhiteReplacement *local = self.whiteReplacement;
        WhiteReplacements()[identity] = request; self.whiteReplacement = request;
        if (previous) [previous.host whiteCancelReplacement:previous];
        if (local && local != previous) [self whiteCancelReplacement:local];
        if (![self whiteReplacementIsCurrent:request]) return;
        [self whiteLeave:nil completion:^(NSError *error) {
            if (![self whiteReplacementIsCurrent:request]) return;
            if (error) { [self whiteFinishReplacement:request error:error]; return; }
            void (^closed)(NSError *) = ^(NSError *closeError) {
                if (![self whiteReplacementIsCurrent:request]) return;
                if (closeError) { [self whiteFinishReplacement:request error:closeError]; return; }
                request.generation = [self whiteBeginCreation:@(timeout) cancellation:^(NSError *error) { [self whiteFinishReplacement:request error:error]; }];
                if (!request.generation) { [self whiteFinishReplacement:request error:WhiteLifecycleError(@"Busy")]; return; }
                WhiteOwners()[identity] = self; self.whiteIdentity = identity;
                bind();
                self.whiteSdkInitArgs = @[configuration];
                [self whiteCall:@"sdk.newWhiteSdk" arguments:@[configuration] generation:request.generation completion:^(id value) {
                    if (![self whiteReplacementIsCurrent:request] || ![self whiteCurrent:request.generation]) return;
                    NSDictionary *result = [value isKindOfClass:NSString.class] ? [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] : nil;
                    NSError *setupError = !result ? WhiteLifecycleError(@"InvalidSetupResult") : result[@"__error"] ? WhiteLifecycleError(result[@"__error"][@"message"]) : nil;
                    if (setupError) [self whiteComplete:request.generation success:NO];
                    [self whiteFinishReplacement:request error:setupError];
                }];
            };
            // The target owner may have switched identity while this host was closing.
            WhiteBoardView *old = WhiteOwners()[identity];
            if (old && old != self) [old whiteLeave:nil completion:closed]; else closed(nil);
        }];
    });
}
- (void)whiteHandshake:(BOOL)restoreSdk {
    [self callHandler:@"sdk.getLifecycle" arguments:nil completionHandler:^(id envelope) {
        @synchronized (self) {
            if (self.whiteInvalid) return;
            NSString *json = [envelope isKindOfClass:NSDictionary.class] ? envelope[@"value"] : nil;
            NSDictionary *value = json ? [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] : nil;
            if (![value[@"documentId"] isKindOfClass:NSString.class]) { [self whiteInvalidate]; return; }
            self.whiteDocument = value[@"documentId"];
            NSArray *work = self.whiteReady.copy; [self.whiteReady removeAllObjects];
            if (restoreSdk && self.whiteSdkInitArgs) [self whiteCall:@"sdk.newWhiteSdk" arguments:self.whiteSdkInitArgs generation:@0 completion:nil];
            for (void (^block)(void) in work) block();
        }
    }];
}
- (NSNumber *)whiteBeginWithCancellation:(void (^)(NSError *))cancel {
    if (self.whiteReplacement) return nil;
    // Player creation is cancelled explicitly by the host, without a fixed deadline.
    return [self whiteBeginCreation:nil cancellation:cancel];
}
- (NSNumber *)whiteBeginCreation:(NSNumber * _Nullable)timeout cancellation:(void (^)(NSError *))cancel {
    @synchronized (self) {
        if (self.whiteInvalid || ![self.whiteState isEqualToString:@"idle"]) return nil;
        self.whiteState = @"joining";
        self.whiteGeneration = @(self.whiteGeneration.unsignedLongLongValue + 1);
        self.whitePending = cancel; self.whiteCloseCallbacks = nil; self.whiteCloseCompleted = NO; self.whiteCloseError = nil;
        NSNumber *generation = self.whiteGeneration;
        if (timeout) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @synchronized (self) {
                if (![self.whiteGeneration isEqual:generation] || !self.whitePending || ![self.whiteState isEqualToString:@"joining"]) return;
                self.whiteState = @"closing";
                void (^pending)(NSError *) = self.whitePending; self.whitePending = nil;
                pending(WhiteLifecycleError(@"JoinTimeout"));
                [self whiteLeave:generation completion:nil];
            }
        });
        return generation;
    }
}
- (BOOL)whiteContinueJoin:(NSNumber *)generation cancellation:(void (^)(NSError *))cancel {
    if (![self whiteCurrent:generation] || !self.whitePending) return NO;
    self.whitePending = cancel;
    return YES;
}
- (BOOL)whiteComplete:(NSNumber *)generation success:(BOOL)success {
    @synchronized (self) {
        if (self.whiteInvalid || ![generation isEqual:self.whiteGeneration] || !self.whitePending) return NO;
        self.whitePending = nil;
        if (success) self.whiteState = @"active";
        else if (![self.whiteState isEqualToString:@"idle"] && ![self.whiteState isEqualToString:@"closing"]) self.whiteState = @"blocked";
        return YES;
    }
}
- (BOOL)whiteCurrent:(NSNumber *)generation {
    return !self.whiteInvalid && [generation isEqual:self.whiteGeneration] &&
        ([self.whiteState isEqualToString:@"joining"] || [self.whiteState isEqualToString:@"active"]);
}
- (WhiteBoardView *)whiteScopedBridge:(NSNumber *)generation {
    WhiteScopedBridge *bridge = [WhiteScopedBridge alloc]; bridge.target = self; bridge.generation = generation;
    return (WhiteBoardView *)bridge;
}
- (NSDictionary *)whiteScope:(NSNumber *)generation {
    return @{@"documentId": self.whiteDocument ?: @"", @"generation": generation ?: self.whiteGeneration};
}
- (void)whiteCall:(NSString *)method arguments:(NSArray *)args generation:(NSNumber *)generation completion:(void (^)(id))completion {
    dispatch_main_async_safe(^{
        if (self.whiteInvalid) { if (completion) completion(WhiteLifecycleFailure(@"HostInvalid")); return; }
        if (!self.whiteDocument) {
            __weak typeof(self) weakSelf = self;
            [self.whiteReady addObject:^{ [weakSelf whiteCall:method arguments:args generation:generation completion:completion]; }];
            return;
        }
        if ([method isEqualToString:@"sdk.newWhiteSdk"] && generation.unsignedLongLongValue > 0 &&
            ![self whiteCurrent:generation]) return;
        if ([method isEqualToString:@"sdk.newWhiteSdk"]) self.whiteSdkInitArgs = args;
        NSMutableArray *values = [NSMutableArray arrayWithObject:@{@"__whiteScope": [self whiteScope:generation]}];
        [values addObjectsFromArray:args ?: @[]];
        void (^response)(id) = completion ? ^(id envelope) {
            if (![envelope isKindOfClass:NSDictionary.class] || ![envelope[@"scope"] isEqual:[self whiteScope:generation]] || self.whiteInvalid) {
                if (completion) completion(WhiteLifecycleFailure(@"StaleScope")); return;
            }
            completion(envelope[@"value"] == NSNull.null ? nil : envelope[@"value"]);
        } : nil;
        [self callHandler:method arguments:values completionHandler:response];
    });
}
- (void)whiteFinishLeave:(NSNumber *)generation value:(id)value {
    @synchronized (self) {
        if (![generation isEqual:self.whiteGeneration] || self.whiteCloseCompleted) return;
        NSDictionary *dict = [value isKindOfClass:NSString.class] ? [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] : nil;
        self.whiteCloseError = dict[@"__error"] ? WhiteLifecycleError(dict[@"__error"][@"message"]) : nil;
        if (!dict) self.whiteCloseError = WhiteLifecycleError(@"InvalidCloseResult");
        self.whiteCloseCompleted = YES; self.whiteState = self.whiteCloseError ? @"blocked" : @"idle";
        if (!self.whiteCloseError && self.whiteIdentity && WhiteOwners()[self.whiteIdentity] == self) [WhiteOwners() removeObjectForKey:self.whiteIdentity];
        NSArray *callbacks = self.whiteCloseCallbacks.copy; self.whiteCloseCallbacks = nil;
        for (void (^callback)(NSError *) in callbacks) callback(self.whiteCloseError);
    }
}
- (void)whiteLeaveRoom:(void (^)(NSError *))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.whiteReplacement) [self whiteCancelReplacement:self.whiteReplacement];
        [self whiteLeave:nil completion:completion];
    });
}
- (void)whiteLeave:(NSNumber *)generation completion:(void (^)(NSError *))completion {
    @synchronized (self) {
        generation = generation ?: self.whiteGeneration;
        if (self.whiteInvalid || ![generation isEqual:self.whiteGeneration]) { if (completion) completion(WhiteLifecycleError(@"StaleScope")); return; }
        if (self.whiteCloseCompleted) { if (completion) completion(self.whiteCloseError); return; }
        if (self.whiteCloseCallbacks) { if (completion) [self.whiteCloseCallbacks addObject:completion]; return; }
        if ([self.whiteState isEqualToString:@"idle"]) { if (completion) completion(nil); return; }
        self.whiteState = @"closing"; self.whiteCloseCallbacks = [NSMutableArray array];
        if (completion) [self.whiteCloseCallbacks addObject:completion];
        void (^pending)(NSError *) = self.whitePending; self.whitePending = nil;
        if (pending) pending(WhiteLifecycleError(@"Cancelled"));
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self whiteFinishLeave:generation value:WhiteLifecycleFailure(@"LeaveTimeout")];
        });
        [self whiteCall:@"sdk.leaveRoom" arguments:nil generation:generation completion:^(id value) {
            [self whiteFinishLeave:generation value:value];
        }];
    }
}
- (void)whiteInvalidate {
    @synchronized (self) {
        if (self.whiteInvalid) return;
        self.whiteInvalid = YES; self.whiteState = @"blocked"; [self.whiteReady removeAllObjects];
        if (self.whiteReplacement) [self whiteFinishReplacement:self.whiteReplacement error:WhiteLifecycleError(@"HostInvalid")];
        void (^pending)(NSError *) = self.whitePending; self.whitePending = nil;
        if (pending) pending(WhiteLifecycleError(@"HostInvalid"));
        NSArray *callbacks = self.whiteCloseCallbacks.copy; self.whiteCloseCallbacks = nil;
        for (void (^callback)(NSError *) in callbacks) callback(WhiteLifecycleError(@"HostInvalid"));
    }
}
// Keep original sync/async event signatures and URL conversion; only validate and remove the envelope.
- (NSString *)call:(NSString *)method :(NSString *)arguments {
    if ([method hasPrefix:@"_dsb."]) return [super call:method :arguments];
    NSMutableDictionary *args = [[NSJSONSerialization JSONObjectWithData:[arguments dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil] mutableCopy];
    NSDictionary *envelope = args[@"data"]; NSDictionary *scope = [envelope isKindOfClass:NSDictionary.class] ? envelope[@"scope"] : nil;
    if (self.whiteInvalid || ![scope[@"documentId"] isEqual:self.whiteDocument] ||
        ([scope[@"generation"] unsignedLongLongValue] && ![scope[@"generation"] isEqual:self.whiteGeneration])) return @"{\"code\":0}";
    if ([method isEqualToString:@"sdk.lifecycleState"]) {
        NSString *next = envelope[@"value"][@"state"];
        if ([next isEqualToString:@"blocked"] || ([next isEqualToString:@"idle"] && self.whiteCloseCompleted && !self.whiteCloseError)) self.whiteState = next;
        return @"{\"code\":0}";
    }
    args[@"data"] = envelope[@"value"] ?: NSNull.null;
    NSString *unwrapped = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:args options:0 error:nil] encoding:NSUTF8StringEncoding];
    return [super call:method :unwrapped];
}
- (WKNavigation *)loadRequest:(NSURLRequest *)request {
    if (self.whiteDocument) [self whiteInvalidate];
    return [super loadRequest:request];
}
- (WKNavigation *)reload {
    if (!self.whiteDocument || self.whiteInvalid) return [super reload];
    BOOL closed = [self.whiteState isEqualToString:@"idle"] &&
        (self.whiteGeneration.unsignedLongLongValue == 0 || (self.whiteCloseCompleted && !self.whiteCloseError));
    if (!closed) { [self whiteInvalidate]; return [super reload]; }
    self.whiteDocument = nil; self.whiteGeneration = @(self.whiteGeneration.unsignedLongLongValue + 1);
    [self.whiteReady removeAllObjects]; self.whiteCloseCallbacks = nil; self.whiteCloseCompleted = NO; self.whiteCloseError = nil;
    [self resetCallInfoList];
    WKNavigation *navigation = [super reload];
    [self whiteHandshake:YES];
    return navigation;
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
    self.whiteSdkInitArgs = @[config];
    if ([self.whiteState isEqualToString:@"idle"]) [self callHandler:@"sdk.newWhiteSdk" arguments:@[config] completionHandler:completionHandler];
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
    BOOL scoped = [args.firstObject isKindOfClass:NSDictionary.class] && args.firstObject[@"__whiteScope"] != nil;
    if (!scoped && ![methodName isEqualToString:@"sdk.getLifecycle"] && ![methodName hasPrefix:@"_dsb."]) {
        if ([methodName isEqualToString:@"sdk.newWhiteSdk"]) self.whiteSdkInitArgs = args;
        NSNumber *generation = [methodName hasPrefix:@"sdk."] && ![methodName isEqualToString:@"sdk.hasBackgroundImage"] && ![methodName isEqualToString:@"sdk.reloadBackgroundImage"] ? @0 : self.whiteGeneration;
        [self whiteCall:methodName arguments:args generation:generation completion:completionHandler];
        return;
    }
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
#if SWIFT_PACKAGE
    return SWIFTPM_MODULE_BUNDLE;
#else
    // 1. 脱离 Cocoapods 时，打包成同名 bundle 就可以保证读取一致性
    // 2. 使用字符串，是为了保证使用子类时，self calss 的路径不会变化
    NSBundle *podBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:NSClassFromString(@"WhiteBoardView")] pathForResource:@"Whiteboard" ofType:@"bundle"]];
    if (podBundle) {
        return podBundle;
    } else {
        // SPM bundle
        return [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Whiteboard_Whiteboard" ofType:@"bundle"]];
    }
#endif
}

@end

@implementation WhiteScopedBridge
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector { return [WhiteBoardView instanceMethodSignatureForSelector:selector]; }
- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.target whiteCurrent:self.generation]) [invocation invokeWithTarget:self.target];
    else if (invocation.methodSignature.methodReturnLength) { void *zero = calloc(1, invocation.methodSignature.methodReturnLength); [invocation setReturnValue:zero]; free(zero); }
}
- (void)callHandler:(NSString *)method arguments:(NSArray *)args completionHandler:(void (^)(id))completion {
    if (!self.target) { if (completion) completion(WhiteLifecycleFailure(@"HostInvalid")); return; }
    if ([method isEqualToString:@"room.disconnect"] || [method isEqualToString:@"player.stop"]) {
        [self.target whiteLeave:self.generation completion:^(NSError *error) { if (completion) completion(error ? WhiteLifecycleFailure(error.localizedDescription) : @"{\"closed\":true}"); }];
        return;
    }
    if (![self.target whiteCurrent:self.generation]) { if (completion) completion(WhiteLifecycleFailure(@"StaleScope")); return; }
    [self.target whiteCall:method arguments:args generation:self.generation completion:completion];
}
- (void)callHandler:(NSString *)method arguments:(NSArray *)args { [self callHandler:method arguments:args completionHandler:nil]; }
- (void)callHandler:(NSString *)method completionHandler:(void (^)(id))completion { [self callHandler:method arguments:nil completionHandler:completion]; }
- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^)(id, NSError *))completion {
    if (![self.target whiteCurrent:self.generation]) { if (completion) completion(nil, WhiteLifecycleError(@"StaleScope")); return; }
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self.target whiteScope:self.generation] options:0 error:nil];
    NSString *scope = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.target evaluateJavaScript:[NSString stringWithFormat:@"window.__whiteRunScoped(%@,function(){%@})", scope, script] completionHandler:completion];
}
@end
