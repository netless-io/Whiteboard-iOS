//
//  StartController.m
//  white-demo-ios
//
//  Created by leavesster on 2018/8/19.
//  Copyright © 2018年 yleaf. All rights reserved.
//

#import "StartViewController.h"
#import "WhiteAppliancePluginViewController.h"

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
    self.enterButton=[UIButton buttonWithType:UIButtonTypeSystem];[self.enterButton setTitle:@"进入测试课堂" forState:UIControlStateNormal];self.enterButton.enabled=NO;
    [self.enterButton addTarget:self action:@selector(enterClass) forControlEvents:UIControlEventTouchUpInside];
    [overlay addArrangedSubview:self.status];[overlay addArrangedSubview:self.enterButton];[self.view addSubview:overlay];overlay.translatesAutoresizingMaskIntoConstraints=NO;
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
            if([NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-probe"])
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{[weakSelf enterClass];});
        }];
    }];
}
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
            self.room=room;self.status.text=success?@"已进入课堂":error.localizedDescription;
            [self record:success?@"room_ready":@"join_error" completion:^{
                if(success&&[NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-probe"])
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),^{[self.sdk leaveRoomWithCompletionHandler:^(NSError *e){[self record:e?@"leave_error":@"left" completion:nil];}];});
            }];
        }];
    }];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if(self.isMovingFromParentViewController || self.navigationController.isBeingDismissed){[self.sdk cancelPreparation];[self.sdk leaveRoomWithCompletionHandler:^(NSError *error){}];}
}
@end

#if DEBUG
@interface StartViewController ()
@property (nonatomic, assign) BOOL didAutoJoinPreloadDemo;
@end
#endif

@implementation StartViewController

#if DEBUG
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.didAutoJoinPreloadDemo && [NSProcessInfo.processInfo.arguments containsObject:@"--white-preload-probe"]) {
        self.didAutoJoinPreloadDemo=YES;[self joinPreloadDemo];return;
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
    [stack setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:16],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-16]
    ]];
}

#pragma mark - Button Action
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
