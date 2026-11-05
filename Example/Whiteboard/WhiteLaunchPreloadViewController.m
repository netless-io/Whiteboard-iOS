#import "WhiteLaunchPreloadViewController.h"
#if DEBUG
#import "Whiteboard.h"
#import "WhiteSDK+Room.h"
#import <unistd.h>

@interface WhiteLaunchBenchView : WhiteBoardView
@end
@implementation WhiteLaunchBenchView
- (NSBundle *)whiteSDKBundle {
    return [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"LaunchBenchWhiteboard" ofType:@"bundle"]];
}
@end

@interface WhiteLaunchPreloadViewController () <WhiteCommonCallbackDelegate, WKScriptMessageHandler>
@property WhiteLaunchBenchView *board;
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
@property BOOL automated;
@property NSTimer *commandTimer;
@end

@implementation WhiteLaunchPreloadViewController
- (NSString *)argument:(NSString *)name fallback:(NSString *)fallback {
    NSArray *args = NSProcessInfo.processInfo.arguments;
    NSUInteger i = [args indexOfObject:name];
    return i != NSNotFound && i + 1 < args.count ? args[i+1] : fallback;
}
- (NSString *)documents { return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject; }
- (NSString *)benchResource:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"LaunchBenchWhiteboard" ofType:@"bundle"]];
    return [NSString stringWithContentsOfFile:[bundle pathForResource:name ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
}
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
    [self.board evaluateJavaScript:@"({requests:window.__iosBenchTransportNetwork,preparation:window.__whitePreparation,config:window.__launchBenchConfig})" completionHandler:^(id value, NSError *error) {
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
    [self setPhase:@"preparing" text:@"正在清空本测试 App 的 IndexedDB…"];
    self.preparedButton = [self button:@"预加载入房" identifier:@"bench.preload.join" action:@selector(joinPrepared)];
    self.directButton = [self button:@"普通入房（点击后初始化）" identifier:@"bench.direct.join" action:@selector(joinDirect)];
    self.preparedButton.enabled = NO; self.directButton.enabled = NO;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.status,self.preparedButton,self.directButton]];
    stack.axis = UILayoutConstraintAxisVertical; stack.spacing = 20;
    [self.cover addSubview:stack]; stack.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[[stack.centerYAnchor constraintEqualToAnchor:self.cover.centerYAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.cover.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:self.cover.trailingAnchor constant:-24]]];
    // Same cold-IDB/warm-HTTP policy as Android; do not clear unrelated Safari/app data.
    WKWebsiteDataStore *store = WKWebsiteDataStore.defaultDataStore;
    [store removeDataOfTypes:[NSSet setWithObject:WKWebsiteDataTypeIndexedDBDatabases] modifiedSince:NSDate.distantPast completionHandler:^{
        [store fetchDataRecordsOfTypes:[NSSet setWithObject:WKWebsiteDataTypeIndexedDBDatabases] completionHandler:^(NSArray<WKWebsiteDataRecord *> *records) {
            if (records.count) { [self fail:@"IndexedDBCleanupFailed"]; return; }
            self.result[@"indexedDBBeforeLaunch"] = @"verified no IndexedDB records; HTTP cache retained";
            [self mark:@"PAGE_READY" payload:@{@"sdkExists":@NO, @"webViewExists":@NO}];
            if ([self.mode isEqual:@"preload"]) [self initializeBoard:YES];
            else { self.directButton.enabled = YES; [self setPhase:@"ready" text:@"点击后创建 WebView / SDK 并入房"]; [self scheduleAutoTap]; }
        }];
    }];
}
- (void)initializeBoard:(BOOL)preparing {
    NSData *data = [NSData dataWithContentsOfFile:[[self documents] stringByAppendingPathComponent:@"launch-preload.private.json"]];
    NSDictionary *credentials = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![credentials[@"roomToken"] length] || ![credentials[@"appIdentifier"] length] || ![credentials[@"uuid"] length]) {
        [self fail:@"MissingPrivateRoomConfiguration"]; return;
    }
    WKWebViewConfiguration *web = [WKWebViewConfiguration new];
    [web.userContentController addScriptMessageHandler:self name:@"launchBench"];
    NSString *shim = [NSString stringWithFormat:@"window.__iosBenchDeferAppliance=%@;\n%@", preparing ? @"false" : @"true",
        [self benchResource:@"ios-transport"]];
    [web.userContentController addUserScript:[[WKUserScript alloc] initWithSource:shim injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    self.board = [[WhiteLaunchBenchView alloc] initWithFrame:self.view.bounds configuration:web];
    self.board.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.board atIndex:0];
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:credentials[@"appIdentifier"]];
    config.region = WhiteRegionCN; config.useMultiViews = YES; config.enableAppliancePlugin = YES;
    if (preparing) config.appliancePluginOptions = [WhiteAppliancePluginOptions new];
    else config.preloadBuiltinApps = @[];
    // enableModelPreload is omitted and remains false. useWorker defaults to auto.
    config.preloadDynamicPPT = NO;
    config.whiteSlideAppParams.enableScale = YES;
    config.whiteSlideAppParams.enableGlobalClick = NO;
    config.whiteSlideAppParams.syncEventQueuePolicy = WhiteSlideSyncEventQueuePolicyLatestPendingRender;
    self.roomConfig = [[WhiteRoomConfig alloc] initWithUUID:credentials[@"uuid"] roomToken:credentials[@"roomToken"] uid:@"launch-aligned-config-benchmark"];
    self.roomConfig.region = WhiteRegionCN; self.roomConfig.isWritable = NO;
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
        [self.sdk prepareWithCompletionHandler:^(NSError *error) {
            if (error) { [weakSelf fail:error.localizedDescription]; return; }
            [weakSelf.board evaluateJavaScript:@"window.__launchPrepare()" completionHandler:^(id value, NSError *error) {
                if (error) [weakSelf fail:@"PrepareProbeFailed"];
            }];
        }];
    }
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
        [self.board.configuration.userContentController removeScriptMessageHandlerForName:@"launchBench"];
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
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    if (self.finished || ![message.body isKindOfClass:NSDictionary.class]) return;
    NSDictionary *body = message.body;
    if ([body[@"method"] isEqual:@"prepared"]) {
        if (self.ready || ![self.mode isEqual:@"preload"]) return;
        self.ready = YES;
        [self mark:@"PRELOAD_READY" payload:@{@"deviceEpochMs":body[@"payload"][@"readyAt"], @"evidence":body[@"payload"]}];
        self.result[@"nativePrepared"] = self.sdk.preparationInfo;
        self.preparedButton.enabled = YES; self.directButton.enabled = YES;
        [self setPhase:@"ready" text:@"白板已准备，可直接入房"];
        [self scheduleAutoTap];
    } else if ([body[@"method"] isEqual:@"record"]) {
        NSDictionary *event = body[@"payload"];
        if (![@[@"T1",@"T2",@"T3",@"T4",@"T5_SETUP",@"T5_READY"] containsObject:event[@"stage"]]) return;
        [self.events addObject:event];
        [self finishIfReady];
    }
}
- (void)finishIfReady {
    if (self.finished || self.sampling) return;
    NSSet *stages = [NSSet setWithArray:[self.events valueForKey:@"stage"]];
    if (![[NSSet setWithArray:@[@"T0",@"T1",@"T2",@"T3",@"T4",@"T5_READY",@"NATIVE_JOIN_SUCCESS"]] isSubsetOfSet:stages]) return;
    self.sampling = YES;
    NSString *js = [self benchResource:@"snapshot"];
    [self.board evaluateJavaScript:js completionHandler:^(id value, NSError *error) {
        if (error || ![value isKindOfClass:NSDictionary.class]) { [self fail:@"SnapshotFailed"]; return; }
        self.result[@"snapshot"] = value;
        self.result[@"nativeAfterJoin"] = self.sdk.preparationInfo;
        self.result[@"status"] = @"joined"; [self save];
        // Accessible controls and screenshots are collected only after all measured stages.
        self.status = [UILabel new]; self.status.backgroundColor = UIColor.whiteColor;
        self.status.frame = CGRectMake(12,100,330,36); [self.view addSubview:self.status];
        [self setPhase:@"completed" text:@"初始化完成"];
        self.leaveButton = [self button:@"退出测试房间" identifier:@"bench.leave" action:@selector(leave)];
        self.leaveButton.frame = CGRectMake(12,140,200,44); self.leaveButton.backgroundColor = UIColor.whiteColor;
        [self.view addSubview:self.leaveButton];
        if (self.automated) {
            // iOS 17 has no legacy screenshotr service. Capture WK content after T5.
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
        [self.board.configuration.userContentController removeScriptMessageHandlerForName:@"launchBench"];
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
