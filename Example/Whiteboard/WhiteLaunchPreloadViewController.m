#import "WhiteLaunchPreloadViewController.h"
#if DEBUG
#import "Whiteboard.h"
#import "WhiteSDK+Room.h"
#import <unistd.h>
extern void WhiteLaunchDemoAttachReleaseProbe(WhiteBoardView *, WhiteSDK *, WhiteRoom *, NSString *);

@interface WhiteLaunchPreloadViewController () <WhiteCommonCallbackDelegate>
@property WhiteBoardView *board;
@property WhiteSDK *sdk;
@property WhiteRoom *room;
@property WhiteRoomConfig *roomConfig;
@property UIView *cover;
@property UILabel *status;
@property UIButton *preparedButton, *directButton, *leaveButton;
@property NSMutableArray *events;
@property NSMutableDictionary *result;
@property NSString *runID, *mode;
@property BOOL joining, finished, ready, sampling;
@property BOOL automated, baseReady, optionalReady;
@property NSTimer *commandTimer;
@end

@implementation WhiteLaunchPreloadViewController
- (NSString *)argument:(NSString *)name fallback:(NSString *)fallback {
    NSArray *args = NSProcessInfo.processInfo.arguments;
    NSUInteger i = [args indexOfObject:name];
    return i != NSNotFound && i + 1 < args.count ? args[i+1] : fallback;
}
- (NSString *)documents { return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject; }
- (void)setPhase:(NSString *)phase text:(NSString *)text {
    self.status.text = text;
    self.status.accessibilityIdentifier = [@"bench." stringByAppendingString:phase];
}
- (void)mark:(NSString *)stage payload:(NSDictionary *)payload {
    NSMutableDictionary *e = [@{@"stage":stage, @"deviceEpochMs":@(NSDate.date.timeIntervalSince1970*1000),
        @"uptimeMs":@(NSProcessInfo.processInfo.systemUptime*1000)} mutableCopy];
    [e addEntriesFromDictionary:payload ?: @{}];
    [self.events addObject:e];
}
- (void)save {
    self.result[@"events"] = self.events;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.result options:NSJSONWritingPrettyPrinted error:nil];
    NSString *folder = [[self documents] stringByAppendingPathComponent:@"launch-benchmark"];
    [NSFileManager.defaultManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    [data writeToFile:[folder stringByAppendingPathComponent:[self.runID stringByAppendingString:@".json"]] atomically:YES];
}
- (void)fail:(NSString *)message {
    if (self.finished) return;
    self.finished = YES;
    [self mark:@"ERROR" payload:@{@"message":message ?: @"UnknownError"}];
    self.result[@"status"] = @"failed";
    [self save];
    [self setPhase:@"failed" text:message];
    [self.commandTimer invalidate];
    [self.board evaluateJavaScript:@"({sdkVersion:window.sdk&&window.sdk.version,roomPhase:window.room&&window.room.phase})" completionHandler:^(id value, NSError *error) {
        if (value) self.result[@"failureDiagnostics"] = value;
        [self save];
        if (self.automated) { fprintf(stdout,"IOS_BENCH_ERROR\n"); fflush(stdout); }
    }];
}
- (UIButton *)button:(NSString *)title identifier:(NSString *)identifier action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityIdentifier = identifier;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"启动页预加载对照";
    self.view.backgroundColor = UIColor.whiteColor;
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    self.mode = [self argument:@"--bench-mode" fallback:@"preload"];
    self.automated = [NSProcessInfo.processInfo.arguments containsObject:@"--bench-auto"];
    self.runID = [self argument:@"--bench-run-id" fallback:[@"manual-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    self.events = [NSMutableArray array];
    self.result = [@{@"runId":self.runID, @"mode":self.mode, @"pid":@(getpid()), @"status":@"running"} mutableCopy];
    self.cover = [[UIView alloc] initWithFrame:self.view.bounds];
    self.cover.backgroundColor = UIColor.whiteColor;
    self.cover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.cover];
    self.status = [UILabel new]; self.status.numberOfLines = 0;
    [self setPhase:@"preparing" text:@"正在初始化测试入口…"];
    self.preparedButton = [self button:@"预加载入房" identifier:@"bench.preload.join" action:@selector(joinPrepared)];
    self.directButton = [self button:@"普通入房（点击后初始化）" identifier:@"bench.direct.join" action:@selector(joinDirect)];
    self.preparedButton.enabled = NO; self.directButton.enabled = NO;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.status,self.preparedButton,self.directButton]];
    stack.axis = UILayoutConstraintAxisVertical; stack.spacing = 20;
    [self.cover addSubview:stack]; stack.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[[stack.centerYAnchor constraintEqualToAnchor:self.cover.centerYAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.cover.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:self.cover.trailingAnchor constant:-24]]];
    [self mark:@"PAGE_READY" payload:@{@"sdkExists":@NO, @"webViewExists":@NO}];
    if ([self.mode isEqual:@"preload"]) [self initializeBoard:YES];
    else { self.directButton.enabled = YES; [self setPhase:@"ready" text:@"点击后创建 WebView / SDK 并入房"]; [self scheduleAutoTap]; }

}
- (void)initializeBoard:(BOOL)preparing {
    NSData *data = [NSData dataWithContentsOfFile:[[self documents] stringByAppendingPathComponent:@"launch-preload.private.json"]];
    NSDictionary *credentials = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![credentials[@"roomToken"] length] || ![credentials[@"appIdentifier"] length] || ![credentials[@"uuid"] length]) {
        [self fail:@"MissingPrivateRoomConfiguration"]; return;
    }
    // Use the current SDK bundle. The archived benchmark bundle is not a Demo dependency.
    self.board = [[WhiteBoardView alloc] initWithFrame:self.view.bounds];
    self.board.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.board atIndex:0];
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:credentials[@"appIdentifier"]];
    config.region = WhiteRegionCN; config.useMultiViews = YES; config.enableAppliancePlugin = YES;
    if ([credentials[@"apiHosts"] isKindOfClass:NSArray.class]) config.apiHosts = credentials[@"apiHosts"];
    if (preparing) {
        config.enablePreLoadAppliancePlugin = YES;
        config.preloadBuiltinApps = @[@"Slide", @"Presentation"];
        config.appliancePluginOptions = [WhiteAppliancePluginOptions new];
    }
    else config.preloadBuiltinApps = @[];
    // enableModelPreload is omitted and remains false. useWorker defaults to auto.
    config.preloadDynamicPPT = NO;
    config.whiteSlideAppParams.enableScale = YES;
    config.whiteSlideAppParams.enableGlobalClick = NO;
    config.whiteSlideAppParams.syncEventQueuePolicy = WhiteSlideSyncEventQueuePolicyLatestPendingRender;
    self.roomConfig = [[WhiteRoomConfig alloc] initWithUUID:credentials[@"uuid"] roomToken:credentials[@"roomToken"] uid:@"launch-aligned-config-benchmark"];
    self.roomConfig.region = WhiteRegionCN; self.roomConfig.isWritable = YES;
    if (!preparing) self.roomConfig.appliancePluginOptions = [WhiteAppliancePluginOptions new];
    WhiteWindowParams *window = [WhiteWindowParams new];
    window.forceMaximized = YES; window.lazySetupInMaximizedMode = YES;
    window.maxCachedAppsInMaximizedMode = @4; window.useBoxesStatus = NO;
    window.originSize = [[WhiteWindowOriginSize alloc] initWithWidth:1280 height:720];
    self.roomConfig.windowParams = window;
    [self mark:preparing ? @"T-1" : @"SDK_CONSTRUCT_BEGIN" payload:nil];
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config commonCallbackDelegate:self];
    if (preparing) {
        __weak typeof(self) weakSelf = self;
        // Optional base JS readiness; it does not wait for Apps or the appliance probe.
        [self.sdk prepareWithCompletionHandler:^(NSError *error) {
            if (error) { [weakSelf fail:error.localizedDescription]; return; }
            weakSelf.baseReady = YES;
            [weakSelf updatePreparedState];
        }];
    }
}
- (void)onPreloadStateChange:(WhitePreloadResult *)result {
    // Optional work has a separate once-only callback. Room/input readiness is checked after join.
    [self mark:@"OPTIONAL_PRELOAD" payload:@{@"state":result.state ?: @"", @"message":result.message ?: @""}];
    self.optionalReady = YES;
    [self updatePreparedState];
}
- (void)updatePreparedState {
    if (self.ready || self.finished || !self.baseReady || !self.optionalReady) return;
    self.ready = YES;
    [self mark:@"PRELOAD_READY" payload:nil];
    self.result[@"nativePrepared"] = self.sdk.preparationInfo;
    self.preparedButton.enabled = YES; self.directButton.enabled = YES;
    [self setPhase:@"ready" text:@"基础资源与可选预加载已完成，可入房"];
    [self scheduleAutoTap];
}
- (void)joinPrepared {
    if (!self.ready || self.joining || self.finished) return;
    [self mark:@"CLICK" payload:nil]; self.joining = YES;
    self.result[@"nativeBeforeJoin"] = self.sdk.preparationInfo;
    [self beginJoin];
}
- (void)joinDirect {
    if (self.joining || self.finished) return;
    [self mark:@"CLICK" payload:nil]; self.joining = YES;
    // Manual selection after warming is supported; formal direct launches start empty.
    if (self.board) {
        [self.sdk cancelPreparation];
        [self.board removeFromSuperview]; self.board = nil; self.sdk = nil;
    }
    self.mode = @"direct"; self.result[@"mode"] = self.mode;
    [self initializeBoard:NO];
    if (self.sdk && !self.finished) [self beginJoin];
}
- (void)beginJoin {
    self.preparedButton.enabled = NO; self.directButton.enabled = NO; self.cover.hidden = YES;
    [self mark:@"T0" payload:nil];
    __weak typeof(self) weakSelf = self;
    [self.sdk joinRoomWithConfig:self.roomConfig callbacks:nil completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
        if (!success) {
            weakSelf.result[@"failureStack"] = error.userInfo[NSDebugDescriptionErrorKey] ?: @"";
            [weakSelf fail:error.localizedDescription ?: @"JoinFailed"]; return;
        }
        weakSelf.room = room;
        [weakSelf mark:@"NATIVE_JOIN_SUCCESS" payload:nil];
        [weakSelf finishIfReady];
    }];
}
- (void)finishIfReady {
    if (self.finished || self.sampling) return;
    if (!self.room) return;
    self.sampling = YES;
    NSString *js = @"({sdkVersion:window.sdk.version,roomPhase:window.room.phase,writable:window.room.isWritable,managerVersion:window.manager&&window.manager.version,applianceVersion:window.appliancePlugin&&window.appliancePlugin.currentManager.version,configuration:{apps:window.sdk.__nativePreparation?\"explicit\":\"off\"}})";
    [self.board evaluateJavaScript:js completionHandler:^(id value, NSError *error) {
        if (error || ![value isKindOfClass:NSDictionary.class]) { [self fail:@"SnapshotFailed"]; return; }
        self.result[@"snapshot"] = value;
        self.result[@"nativeAfterJoin"] = self.sdk.preparationInfo;
        self.result[@"status"] = @"joined"; [self save];
        // Native join success includes the current Bridge initialization; no legacy timing hooks are used.
        self.status = [UILabel new]; self.status.backgroundColor = UIColor.whiteColor;
        self.status.frame = CGRectMake(12,100,330,36); [self.view addSubview:self.status];
        [self setPhase:@"completed" text:@"已入房，可使用白板"];
        self.leaveButton = [self button:@"退出测试房间" identifier:@"bench.leave" action:@selector(leave)];
        self.leaveButton.frame = CGRectMake(12,140,200,44); self.leaveButton.backgroundColor = UIColor.whiteColor;
        [self.view addSubview:self.leaveButton];
        if (self.automated) {
            if ([NSProcessInfo.processInfo.arguments containsObject:@"--bench-release-control"])
                WhiteLaunchDemoAttachReleaseProbe(self.board, self.sdk, self.room, self.runID);
            // Capture the actual WK content after Native join success.
            [self.board takeSnapshotWithConfiguration:nil completionHandler:^(UIImage *image, NSError *snapshotError) {
                if (!image) { [self fail:@"PostJoinScreenshotFailed"]; return; }
                NSString *name = [self.runID stringByAppendingString:@".png"];
                NSString *file = [[[self documents] stringByAppendingPathComponent:@"launch-benchmark"] stringByAppendingPathComponent:name];
                [UIImagePNGRepresentation(image) writeToFile:file atomically:YES];
                self.result[@"screenshot"] = name; [self save];
                self.commandTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(readCommand) userInfo:nil repeats:YES];
                fprintf(stdout,"IOS_BENCH_JOINED %s\n",self.runID.UTF8String); fflush(stdout);
            }];
        }
    }];
}
- (void)leave {
    self.leaveButton.enabled = NO;
    [self.sdk leaveRoomWithCompletionHandler:^(NSError *error) {
        if (error) { [self fail:error.localizedDescription]; return; }
        self.room = nil; [self mark:@"LEFT" payload:nil];
        self.result[@"status"] = @"passed"; [self save]; self.finished = YES;
        [self setPhase:@"left" text:@"已正常离房"];
        [self.commandTimer invalidate]; self.commandTimer = nil;
        if (self.automated) {
            fprintf(stdout,"IOS_BENCH_LEFT %s\n",self.runID.UTF8String); fflush(stdout);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/5), dispatch_get_main_queue(), ^{ exit(0); });
        }
    }];
}
- (void)sdkSetupFail:(NSError *)error { [self fail:error.localizedDescription ?: @"SDKSetupFailed"]; }
- (void)scheduleAutoTap {
    if (!self.automated) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*8/10), dispatch_get_main_queue(), ^{
        UIButton *button = [self.mode isEqual:@"preload"] ? self.preparedButton : self.directButton;
        if (button.enabled && !self.joining && !self.finished) [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
}
- (void)readCommand {
    NSData *data = [NSData dataWithContentsOfFile:[[self documents] stringByAppendingPathComponent:@"launch-benchmark-command.json"]];
    NSDictionary *command = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if ([command[@"runId"] isEqual:self.runID] && [command[@"action"] isEqual:@"leave"] && self.leaveButton.enabled)
        [self.leaveButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}
- (void)dealloc { UIApplication.sharedApplication.idleTimerDisabled = NO; }
@end
#else
@implementation WhiteLaunchPreloadViewController
@end
#endif
