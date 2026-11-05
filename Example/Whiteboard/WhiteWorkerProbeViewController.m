#import "WhiteWorkerProbeViewController.h"
#if DEBUG
#import "Whiteboard.h"
#import "WhiteSDK+Room.h"
#import "WhiteUtils.h"
#if __has_include("WhitePreloadDemo.local.h")
#import "WhitePreloadDemo.local.h"
#else
#define WhitePreloadRoomUUID @""
#define WhitePreloadRoomToken @""
#endif

@interface WhiteWorkerProbeViewController ()
@property WhiteBoardView *board;
@property WhiteSDK *sdk;
@property WhiteRoom *room;
@property NSString *mode;
@property NSMutableDictionary *evidence;
@end

@implementation WhiteWorkerProbeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    NSArray *args = NSProcessInfo.processInfo.arguments;
    self.mode = [args containsObject:@"--worker-main-thread"] ? @"mainThread" :
        ([args containsObject:@"--worker-dual"] ? @"dual" : @"simple");
    self.title = [@"Worker probe: " stringByAppendingString:self.mode];
    self.evidence = [NSMutableDictionary dictionaryWithDictionary:@{@"mode":self.mode}];
    WKWebViewConfiguration *web = [WKWebViewConfiguration new];
    // Observe loading and messaging without replacing the Worker implementation.
    NSString *probe = @"(function(){"
        "var p=window.__workerProbe={scripts:[],blobs:[],workers:[],errors:[]};"
        "var append=Node.prototype.appendChild;Node.prototype.appendChild=function(n){"
        "if(n.tagName==='SCRIPT'&&/appliance-worker-/.test(n.src))p.scripts.push(n.src);"
        "return append.call(this,n)};"
        "var create=URL.createObjectURL;URL.createObjectURL=function(b){var u=create.call(URL,b);"
        "p.blobs.push({url:u,size:b.size,type:b.type});return u};"
        "if(window.Worker){var Original=window.Worker;var Wrapped=function(u,o){"
        "var w=new Original(u,o),r={url:String(u),messages:0,errors:0,terminated:false};p.workers.push(r);"
        "w.addEventListener('message',function(){r.messages++});"
        "w.addEventListener('error',function(e){r.errors++;r.lastError=e.message});"
        "var stop=w.terminate;w.terminate=function(){r.terminated=true;return stop.call(w)};return w};"
        "Wrapped.prototype=Original.prototype;window.Worker=Wrapped;}"
        "window.addEventListener('error',function(e){p.errors.push(String(e.message||e.type))});"
        "})();";
    [web.userContentController addUserScript:[[WKUserScript alloc] initWithSource:probe injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    self.board = [[WhiteBoardView alloc] initWithFrame:self.view.bounds configuration:web];
    self.board.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.board];
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:[WhiteUtils appIdentifier]];
    config.useMultiViews = YES;
    config.enableAppliancePlugin = YES;
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config commonCallbackDelegate:nil];
    __weak typeof(self) weakSelf = self;
    [self.sdk prepareWithCompletionHandler:^(NSError *error) {
        if (error) { [weakSelf record:@"prepare_error" completion:nil]; return; }
        [weakSelf record:@"prepared" completion:^{
            [weakSelf resetRenderCache];
        }];
    }];
}

- (void)resetRenderCache {
    // The plugin caches decisions per UA. A prior auto fallback can otherwise
    // mask the runtime path being tested. Clear only this derived probe cache.
    NSString *script = @"(function(){var p=window.__workerProbe;p.cacheReset='pending';"
        "try{var r=indexedDB.deleteDatabase('__APPLIANCE_PLUGIN_RENDER_MODE_DB');"
        "r.onsuccess=function(){p.cacheReset='success'};"
        "r.onerror=r.onblocked=function(){p.cacheReset='failed'};"
        "}catch(e){p.cacheReset='failed'};return true})()";
    [self.board evaluateJavaScript:script completionHandler:^(id value, NSError *error) {
        [self waitForRenderCacheReset:0];
    }];
}

- (void)waitForRenderCacheReset:(NSUInteger)attempt {
    [self.board evaluateJavaScript:@"window.__workerProbe.cacheReset" completionHandler:^(id value, NSError *error) {
        if ([value isEqual:@"success"]) { [self join]; return; }
        if ([value isEqual:@"pending"] && attempt < 30) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/10), dispatch_get_main_queue(), ^{
                [self waitForRenderCacheReset:attempt+1];
            });
        } else [self record:@"cache_reset_error" completion:nil];
    }];
}

- (void)join {
    if (!WhitePreloadRoomUUID.length || !WhitePreloadRoomToken.length) {
        self.evidence[@"configurationError"] = @"Configure ignored WhitePreloadDemo.local.h";
        [self record:@"configuration_error" completion:nil]; return;
    }
    WhiteRoomConfig *config = [[WhiteRoomConfig alloc] initWithUUID:WhitePreloadRoomUUID roomToken:WhitePreloadRoomToken uid:[@"ios-worker-probe-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    config.region = WhiteRegionCN;
    config.isWritable = NO;
    config.windowParams = [WhiteWindowParams new];
    WhiteAppliancePluginOptions *plugin = [WhiteAppliancePluginOptions new];
    plugin.extras = @{@"useWorker":[self.mode isEqualToString:@"mainThread"] ? @"mainThread" : @"auto",
                      @"useSimple":@(![self.mode isEqualToString:@"dual"]),
                      @"allowImageBitmapFallback":@YES};
    config.appliancePluginOptions = plugin;
    __weak typeof(self) weakSelf = self;
    [self.sdk joinRoomWithConfig:config callbacks:nil completionHandler:^(BOOL success, WhiteRoom *room, NSError *error) {
        WhiteWorkerProbeViewController *host = weakSelf;
        if (!host) return;
        host.room = room;
        host.evidence[@"joinSuccess"] = @(success);
        if (!success) { [host record:@"join_error" completion:nil]; return; }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [host record:@"ready" completion:^{
                [host.board takeSnapshotWithConfiguration:nil completionHandler:^(UIImage *image, NSError *snapshotError) {
                    if (image) [UIImagePNGRepresentation(image) writeToFile:[host evidencePath:@"png"] atomically:YES];
                    [host.sdk leaveRoomWithCompletionHandler:^(NSError *leaveError) {
                        [host record:leaveError ? @"leave_error" : @"left" completion:nil];
                    }];
                }];
            }];
        });
    }];
}

- (NSString *)evidencePath:(NSString *)extension {
    NSString *name = [NSString stringWithFormat:@"white-worker-%@.%@", self.mode, extension];
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:name];
}

- (void)record:(NSString *)event completion:(void (^)(void))completion {
    NSString *script = @"(function(){var p=window.__workerProbe||{},r=window.room,m=window.manager,"
        "a=window.appliancePlugin,pm=a&&a.currentManager,o=pm&&pm.pluginOptions,e=o&&o.extras;"
        "return {protocol:location.protocol,probe:p,phase:r&&r.phase,roomPresent:!!r,managerPresent:!!m,"
        "plugin:{attached:!!a,renderMode:pm&&pm.renderMode,decision:pm&&pm.renderingCompatibilityDecision,"
        "cdn:o&&o.cdn,extras:e&&{useWorker:e.useWorker,useSimple:e.useSimple,allowImageBitmapFallback:e.allowImageBitmapFallback}},"
        "canvases:Array.prototype.map.call(document.querySelectorAll('canvas'),function(c){"
        "var b=c.getBoundingClientRect();return {width:c.width,height:c.height,visibleWidth:b.width,visibleHeight:b.height}})}})()";
    [self.board evaluateJavaScript:script completionHandler:^(id value, NSError *error) {
        self.evidence[event] = value ?: @{@"evaluationFailed":@YES};
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.evidence options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:[self evidencePath:@"json"] atomically:YES];
        NSLog(@"WHITE_WORKER_PROBE mode=%@ event=%@", self.mode, event);
        if (completion) completion();
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController || self.navigationController.isBeingDismissed) {
        [self.sdk cancelPreparation];
        [self.sdk leaveRoomWithCompletionHandler:^(NSError *error) {}];
    }
}
@end
#endif
