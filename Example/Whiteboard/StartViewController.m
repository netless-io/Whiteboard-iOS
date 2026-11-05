//
//  StartController.m
//  white-demo-ios
//
//  Created by leavesster on 2018/8/19.
//  Copyright © 2018年 yleaf. All rights reserved.
//

#import "StartViewController.h"
#import "WhiteAppliancePluginViewController.h"
#import "WhiteWorkerProbeViewController.h"
#import "WhiteLaunchPreloadViewController.h"
#import "WhiteReleaseE2EController.h"

#import "Whiteboard.h"
#import "WhiteSDK+Room.h"
#import "WhiteUtils.h"
#if __has_include("WhitePreloadDemo.local.h")
#import "WhitePreloadDemo.local.h"
#else
#define WhitePreloadRoomUUID @""
#define WhitePreloadRoomToken @""
#endif

// Keep this controller (and its actual WebView) alive throughout waiting and class.
@interface WhitePreloadDemoController : UIViewController <WhiteCommonCallbackDelegate>
@property WhiteBoardView *board;
@property WhiteSDK *sdk;
@property WhiteRoom *room;
@property UIButton *enterButton;
@property UILabel *status;
@property NSMutableDictionary *evidence;
@property BOOL joining;
#if DEBUG
@property NSTimer *networkTimer;
@property NSString *networkCommandID;
#endif
@end
@implementation WhitePreloadDemoController
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"预加载候课";self.view.backgroundColor=UIColor.whiteColor;
    self.evidence=[NSMutableDictionary dictionary];
    WKWebViewConfiguration *web=[WKWebViewConfiguration new];
    NSString *probe=@"(function(){var sdk;window.__preloadProbe={constructors:0,joins:0};Object.defineProperty(window,'sdk',{configurable:true,get:function(){return sdk},set:function(v){sdk=v;var p=window.__preloadProbe;p.constructors++;p.firstSdk=p.firstSdk||v;var join=v.joinRoom.bind(v);v.joinRoom=function(){p.joins++;p.sameSdk=p.firstSdk===v;return join.apply(v,arguments)}}})})();";
    [web.userContentController addUserScript:[[WKUserScript alloc] initWithSource:probe injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    self.board=[[WhiteBoardView alloc] initWithFrame:self.view.bounds configuration:web];
    self.board.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.board];
    UIStackView *overlay=[UIStackView new];overlay.axis=UILayoutConstraintAxisVertical;overlay.backgroundColor=UIColor.secondarySystemBackgroundColor;
    self.status=[UILabel new];self.status.text=@"正在准备白板…";self.status.numberOfLines=0;
    self.enterButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.enterButton setTitle:@"进入测试课堂" forState:UIControlStateNormal];self.enterButton.enabled=NO;self.enterButton.accessibilityIdentifier=@"preload.join";
    [self.enterButton addTarget:self action:@selector(enterClass) forControlEvents:UIControlEventTouchUpInside];
    [overlay addArrangedSubview:self.status];[overlay addArrangedSubview:self.enterButton];
#if DEBUG
    if([NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-network"]) {
        UIButton *leave=[UIButton buttonWithType:UIButtonTypeSystem];[leave setTitle:@"退出测试课堂" forState:UIControlStateNormal];leave.accessibilityIdentifier=@"preload.leave";
        [leave addTarget:self action:@selector(leaveTestClass) forControlEvents:UIControlEventTouchUpInside];[overlay addArrangedSubview:leave];
    }
#endif
    [self.view addSubview:overlay];overlay.translatesAutoresizingMaskIntoConstraints=NO;
    [NSLayoutConstraint activateConstraints:@[[overlay.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],[overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]]];
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:[WhiteUtils appIdentifier]];config.useMultiViews=YES;config.enableAppliancePlugin=YES;
    WhiteAppliancePluginOptions *appliance=[WhiteAppliancePluginOptions new];
    appliance.extras=@{@"useWorker":@"auto",@"useSimple":@YES,@"allowImageBitmapFallback":@YES};
    config.appliancePluginOptions=appliance;
    self.sdk=[[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config commonCallbackDelegate:self];
    __weak typeof(self) weakSelf=self;
    [self.sdk prepareWithCompletionHandler:^(NSError *error){
        WhitePreloadDemoController *host=weakSelf;if(!host)return;
        host.status.text=error ? error.localizedDescription : @"白板已准备，等待进入课堂";
        if(error){[host record:@"prepare_error" completion:nil];return;}
        host.enterButton.enabled=YES;
        [host record:@"prepared" completion:^{
            if([NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-probe"] && ![NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-network"])
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{[weakSelf enterClass];});
        }];
    }];
#if DEBUG
    if([NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-network"]) {
        self.networkTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(networkTick) userInfo:nil repeats:YES];
    }
#endif
}
#if DEBUG
// USB file commands drive the real Native SDK while data traffic is unavailable.
- (void)leaveTestClass {
    [self.sdk leaveRoomWithCompletionHandler:^(NSError *error){
        self.joining=NO;self.room=nil;self.enterButton.enabled=YES;self.status.text=@"白板已准备，等待进入课堂";
        [self record:error?@"leave_error":@"left" completion:nil];
    }];
}
- (void)networkTick {
    NSString *documents=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    NSData *data=[NSData dataWithContentsOfFile:[documents stringByAppendingPathComponent:@"white-preload-command.json"]];
    NSDictionary *command=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;
    if(command[@"id"] && ![self.networkCommandID isEqual:command[@"id"]]) {
        self.networkCommandID=command[@"id"];
        if([command[@"action"] isEqual:@"join"]) [self enterClass];
        if([command[@"action"] isEqual:@"leave"]) [self.sdk leaveRoomWithCompletionHandler:^(NSError *error){
            self.joining=NO;self.room=nil;self.enterButton.enabled=YES;
            [self record:error?@"leave_error":@"left" completion:nil];
        }];
    }
    NSString *js=@"(function(){var p=window.__preloadProbe;if(!p)return {};var w=window.__whitePreparation;var urls=w&&w.workerUrls;if(urls&&urls.fullWorkerUrl&&!p.firstBlob)p.firstBlob=urls.fullWorkerUrl;if(window.room&&!p.firstRoom)p.firstRoom=window.room;if(!p.canaryPending){p.canaryPending=true;var x=new XMLHttpRequest();x.open('GET','https://api-cn-hz.netless.link/v5/configs/regions?networkProbe='+Date.now());x.timeout=2500;var done=function(ok){p.canary={ok:ok,status:x.status,time:Date.now()};p.canaryPending=false};x.onload=function(){done(x.status>0)};x.onerror=function(){done(false)};x.ontimeout=function(){done(false)};x.send()}return {constructors:p.constructors,joins:p.joins,sameSdk:window.sdk===p.firstSdk,sameBlob:!!p.firstBlob&&!!urls&&urls.fullWorkerUrl===p.firstBlob,sameRoom:!!window.room&&window.room===p.firstRoom,roomPresent:!!window.room,managerPresent:!!window.manager,phase:window.room&&window.room.phase,online:navigator.onLine,canary:p.canary,resources:w,content:{fixture:window.room&&window.room.state.globalState.preloadNetworkFixture,apps:window.manager&&window.manager.apps,titleVisible:document.body.innerText.indexOf('Preload Network Slide')>=0,canvases:document.querySelectorAll('canvas').length,noteData:window.appliancePlugin&&window.appliancePlugin.currentManager&&JSON.stringify(window.appliancePlugin.currentManager.collector.storage)}}})()";
    [self.board evaluateJavaScript:js completionHandler:^(id value,NSError *error){
        NSMutableArray *samples=self.evidence[@"networkSamples"];if(!samples){samples=[NSMutableArray array];self.evidence[@"networkSamples"]=samples;}
        [samples addObject:@{@"wallTimeMs":@(NSDate.date.timeIntervalSince1970*1000),@"command":self.networkCommandID?:@"",@"js":value?:@{},@"native":self.sdk.preparationInfo}];
        if(samples.count>600)[samples removeObjectAtIndex:0];
        [[NSJSONSerialization dataWithJSONObject:self.evidence options:NSJSONWritingPrettyPrinted error:nil] writeToFile:[documents stringByAppendingPathComponent:@"white-preload-demo.json"] atomically:YES];
    }];
}
#endif
- (void)logger:(NSDictionary *)dict { if(dict[@"WhitePreload"]) NSLog(@"WHITE_PRELOAD_EVENT %@",dict[@"WhitePreload"]); }
- (void)record:(NSString *)event completion:(void (^)(void))completion {
    NSDictionary *native=self.sdk.preparationInfo;
    [self.board evaluateJavaScript:@"(function(){var p=window.__preloadProbe;return {constructors:p.constructors,joins:p.joins,sameSdk:!!p.sameSdk,roomPresent:!!window.room,phase:window.room&&window.room.phase,managerPresent:!!window.manager,resources:window.__whitePreparation}})()" completionHandler:^(id value,NSError *error){
        NSDictionary *sample=@{@"native":native,@"js":value?:@{},@"uptimeMs":@(NSProcessInfo.processInfo.systemUptime*1000)};
        self.evidence[event]=sample;
        NSString *path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"white-preload-demo.json"];
        [[NSJSONSerialization dataWithJSONObject:self.evidence options:NSJSONWritingPrettyPrinted error:nil] writeToFile:path atomically:YES];
        NSLog(@"WHITE_PRELOAD_DEMO %@ %@",event,sample);if(completion)completion();
    }];
}
- (void)enterClass {
    if(self.joining)return;self.joining=YES;self.enterButton.enabled=NO;self.status.text=@"正在进入课堂…";
    if(!WhitePreloadRoomToken.length){self.status.text=@"请配置 WhitePreloadDemo.local.h";self.joining=NO;return;}
    [self record:@"join_entry" completion:^{
        WhiteRoomConfig *config=[[WhiteRoomConfig alloc] initWithUUID:WhitePreloadRoomUUID roomToken:WhitePreloadRoomToken uid:[@"ios-preload-" stringByAppendingString:NSUUID.UUID.UUIDString]];
        config.region=WhiteRegionCN;config.isWritable=NO;config.windowParams=[WhiteWindowParams new];
        [self.sdk joinRoomWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){
            self.room=room;if(!success){self.joining=NO;self.enterButton.enabled=YES;}self.status.text=success?@"已进入课堂":error.localizedDescription;
            [self record:success?@"room_ready":@"join_error" completion:^{
                if(success&&[NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-probe"] && ![NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-network"])
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),^{[self.sdk leaveRoomWithCompletionHandler:^(NSError *e){[self record:e?@"leave_error":@"left" completion:nil];}];});
            }];
        }];
    }];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if(self.isMovingFromParentViewController || self.navigationController.isBeingDismissed){
#if DEBUG
        [self.networkTimer invalidate];self.networkTimer=nil;
#endif
        [self.sdk cancelPreparation];[self.sdk leaveRoomWithCompletionHandler:^(NSError *error){}];}
}
@end

#if DEBUG
@interface StartViewController ()
@property (nonatomic, assign) BOOL didAutoJoinDynamicConfigDemo;
@property (nonatomic, assign) BOOL didAutoJoinPreloadDemo;
@property (nonatomic, assign) BOOL didAutoJoinWorkerProbe;
@property (nonatomic, assign) BOOL didAutoLaunchBenchmark;
@property (nonatomic, assign) BOOL didAutoLaunchReleaseE2E;
@end
#endif

@implementation StartViewController

#if DEBUG
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.didAutoLaunchReleaseE2E && [NSProcessInfo.processInfo.arguments containsObject:@"--white-release-e2e"]) {
        self.didAutoLaunchReleaseE2E = YES;
        [self.navigationController pushViewController:[WhiteReleaseE2EController new] animated:NO];
        return;
    }
    if (!self.didAutoLaunchBenchmark && [NSProcessInfo.processInfo.arguments containsObject:@"--white-launch-benchmark"]) {
        self.didAutoLaunchBenchmark = YES;
        [self.navigationController pushViewController:[WhiteLaunchPreloadViewController new] animated:NO];
        return;
    }
    if (!self.didAutoJoinWorkerProbe && [NSProcessInfo.processInfo.arguments containsObject:@"--white-worker-probe"]) {
        self.didAutoJoinWorkerProbe = YES;
        [self.navigationController pushViewController:[WhiteWorkerProbeViewController new] animated:YES];
        return;
    }
    if (!self.didAutoJoinPreloadDemo && [NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-probe"]) {
        self.didAutoJoinPreloadDemo=YES;[self joinPreloadDemo];return;
    }
    if (!self.didAutoJoinDynamicConfigDemo &&
        [NSProcessInfo.processInfo.arguments containsObject:@"--white-dynamic-config-probe"]) {
        self.didAutoJoinDynamicConfigDemo = YES;
        [self joinAppliancePluginWindowRoom:nil];
    }
}
#endif

- (UIButton *)createButtonWithTitle:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [btn setTitle:title forState:UIControlStateNormal];
    return btn;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *joinBtn = [self createButtonWithTitle:NSLocalizedString(@"加入多窗口房间(AppliancePlugin)", nil)];
    [joinBtn addTarget:self action:@selector(joinAppliancePluginWindowRoom:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *imageBitmapBtn = [self createButtonWithTitle:NSLocalizedString(@"加入多窗口房间(AppliancePlugin + ImageBitmap)", nil)];
    [imageBitmapBtn addTarget:self action:@selector(joinAppliancePluginImageBitmapRoom:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *preloadBtn=[self createButtonWithTitle:@"预加载候课 → 进入课堂"];
    [preloadBtn addTarget:self action:@selector(joinPreloadDemo) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[joinBtn, imageBitmapBtn, preloadBtn]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 18;
    stack.alignment = UIStackViewAlignmentCenter;
    [self.view addSubview:stack];
#if DEBUG
    UIButton *benchmarkBtn = [self createButtonWithTitle:@"启动页预加载对照 Demo"];
    [benchmarkBtn addTarget:self action:@selector(joinLaunchBenchmark) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:benchmarkBtn];
#endif
    [stack setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:16],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-16]
    ]];
}

#pragma mark - Button Action
#if DEBUG
- (void)joinLaunchBenchmark { [self.navigationController pushViewController:[WhiteLaunchPreloadViewController new] animated:YES]; }
#endif
- (void)joinPreloadDemo { [self.navigationController pushViewController:[WhitePreloadDemoController new] animated:YES]; }
- (void)joinAppliancePluginWindowRoom:(UIButton *)sender {
    WhiteAppliancePluginViewController *vc = [[WhiteAppliancePluginViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)joinAppliancePluginImageBitmapRoom:(UIButton *)sender {
    WhiteAppliancePluginViewController *vc = [[WhiteAppliancePluginViewController alloc] init];
    vc.allowImageBitmapFallback = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
