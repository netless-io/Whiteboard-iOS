//
//  WhiteAppliancePluginViewController.m
//  Whiteboard_Example
//
//  Created by Codex on 2026/8/19.
//

#import "WhiteAppliancePluginViewController.h"
#import "Masonry.h"
#import "WhiteUtils.h"

static NSString * const kAppliancePluginRoomUUID = @"b192fe80ba1b11f1b109bd7837044901";
static NSString * const kAppliancePluginRoomToken = @"NETLESSROOM_YWs9VWtNUk92M1JIN2I2Z284dCZleHBpcmVBdD0xNzkwNTYyNzUzMjg1Jm5vbmNlPWIxYWFmMzUwLWJhMWItMTFmMS1iYzM4LWQ3Yjg5YzgwZTNlMSZyb2xlPTEmc2lnPWQzODBiNzExNjE1ZjMwNmU2N2JiMzE5MDc5ODBiZmQ3MjA2NmJmZWI3ZjRiOGMyNjFlMGFmNzYzNjNkMTVmNjImdXVpZD1iMTkyZmU4MGJhMWIxMWYxYjEwOWJkNzgzNzA0NDkwMQ";
static CGFloat const kAppliancePluginOriginWidth = 1280.0;
static CGFloat const kAppliancePluginOriginHeight = 720.0;
static NSString * const kAppliancePluginSlidePrefix = @"https://conversion-demo-cn.oss-cn-hangzhou.aliyuncs.com/demo/dynamicConvert";
static NSString * const kAppliancePluginSlideTaskId = @"3e3a2b8845194f998e6e05adab70e1a1";

@interface WhiteRoomViewController (WhiteAppliancePluginPrivate)
- (void)setupViews;
- (void)joinRoomWithToken:(NSString *)roomToken;
- (void)actionAfterSuccessJoinRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken;
@end

@interface WhiteAppliancePluginViewController () <WhiteCommonCallbackDelegate>

@property (nonatomic, strong) UIButton *writableButton;
@property (nonatomic, strong) UIButton *exitButton;
@property (nonatomic, strong) UIScrollView *toolbarView;
@property (nonatomic, copy, nullable) NSString *currentDocsAppId;

- (void)scalePage:(UIButton *)sender;
- (void)insertImage:(UIButton *)sender;
- (void)addSlideApp;
- (void)addPresentationApp;
- (void)previousPage:(UIButton *)sender;
- (void)nextPage:(UIButton *)sender;
- (void)dispatchDocsEvent:(WhiteWindowDocsEventKey)event target:(nullable NSString *)target;

@end

@implementation WhiteAppliancePluginViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.roomUuid = kAppliancePluginRoomUUID;
        self.useMultiViews = YES;
        self.allowImageBitmapFallback = NO;

        WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:[WhiteUtils appIdentifier]];
        config.useMultiViews = YES;
        config.renderEngine = WhiteSdkRenderEngineCanvas;
        config.region = WhiteRegionCN;
        config.log = YES;
        config.enableAppliancePlugin = YES;
        config.userCursor = NO;
        config.loggerOptions = @{
            @"printLevelMask": WhiteSDKLoggerOptionLevelDebug
        };

        WhiteBackgroundImageLoadOptions *backgroundImageLoadOptions = [[WhiteBackgroundImageLoadOptions alloc] init];
        backgroundImageLoadOptions.maxRetries = 3;
        config.backgroundImageLoadOptions = backgroundImageLoadOptions;

        WhiteSlideAppParams *slideParams = [[WhiteSlideAppParams alloc] init];
        slideParams.enableGlobalClick = NO;
        slideParams.enableScale = YES;
        slideParams.syncEventQueuePolicy = WhiteSlideSyncEventQueuePolicyLatestPendingRender;
        config.whiteSlideAppParams = slideParams;

        WhiteLocalLogOptions *localLogOptions = [[WhiteLocalLogOptions alloc] init];
        localLogOptions.enabled = @YES;
        localLogOptions.enabledUpload = @YES;
        config.localLogOptions = localLogOptions;

        self.sdkConfig = config;
    }
    return self;
}

- (void)viewDidLoad
{
    self.delayJoinRoom = YES;
    [super viewDidLoad];
    self.title = @"Appliance Plugin";
    self.controlView.hidden = YES;

    [self.boardView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self setupApplianceUI];
    [self joinRoomWithToken:kAppliancePluginRoomToken];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)joinRoomWithToken:(NSString *)roomToken
{
    if (!self.roomConfig) {
        WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUUID:self.roomUuid roomToken:roomToken uid:@"1" userPayload:@{
            @"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg"
        }];
        roomConfig.region = WhiteRegionCN;
        roomConfig.isWritable = NO;

        WhiteWindowParams *windowParams = [[WhiteWindowParams alloc] init];
        windowParams.chessboard = NO;
        windowParams.fullscreen = YES;
        windowParams.useBoxesStatus = NO;
        windowParams.forceMaximized = YES;
        windowParams.lazySetupInMaximizedMode = YES;
        windowParams.maxCachedAppsInMaximizedMode = @5;
        windowParams.overwriteStyles =
            @".telebox-collector{display:none !important;}"
             ".vjs-p .player-controller{display:none !important;}"
             ".netless-app-slide-wb-view {clip-path: none !important;}"
             ".telebox-box.telebox-blur.telebox-maximized {display: none !important;}"
             ".netless-app-slide-content [data-resizable-scroll=\"true\"] ~ .scroll-bar { display: none !important;}"
             ".netless-app-slide-content [data-resizable-scroll=\"true\"] { width: 100% !important; height: 100% !important;}";
        roomConfig.windowParams = windowParams;

        WhiteAppliancePluginOptions *pluginOptions = [[WhiteAppliancePluginOptions alloc] init];
        pluginOptions.extras = [self appliancePluginExtras];
        roomConfig.appliancePluginOptions = pluginOptions;

        self.roomConfig = roomConfig;
    }
    [super joinRoomWithToken:roomToken];
}

- (void)actionAfterSuccessJoinRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken
{
    [super actionAfterSuccessJoinRoom:room roomToken:roomToken];
    [self updateWritableUI];
}

#pragma mark - UI

- (void)setupApplianceUI
{
    self.view.backgroundColor = UIColor.whiteColor;

    self.writableButton = [self overlayButtonWithTitle:@"获取可写"
                                               color:[UIColor colorWithRed:0.05 green:0.62 blue:0.98 alpha:1]
                                               action:@selector(toggleWritable:)];
    [self.view addSubview:self.writableButton];
    [self.writableButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(12);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(10);
    }];

    self.exitButton = [self overlayButtonWithTitle:@"退出房间"
                                            color:[UIColor colorWithRed:0.96 green:0.40 blue:0.36 alpha:1]
                                            action:@selector(exitRoom:)];
    [self.view addSubview:self.exitButton];
    [self.exitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-12);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(10);
    }];

    self.toolbarView = [[UIScrollView alloc] init];
    self.toolbarView.showsHorizontalScrollIndicator = NO;
    self.toolbarView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    [self.view addSubview:self.toolbarView];
    [self.toolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@96);
    }];

    UIStackView *toolbarStack = [[UIStackView alloc] init];
    toolbarStack.axis = UILayoutConstraintAxisHorizontal;
    toolbarStack.spacing = 8;
    toolbarStack.alignment = UIStackViewAlignmentCenter;
    [self.toolbarView addSubview:toolbarStack];
    [toolbarStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.toolbarView).insets(UIEdgeInsetsMake(0, 10, 10, 10));
        make.height.equalTo(self.toolbarView).offset(-10);
    }];

    NSArray<NSString *> *toolbarTitles = @[@"Pencil", @"Text", @"Selector", @"Eraser", @"Star", @"Clicker", @"Head"];
    [toolbarTitles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        UIButton *toolButton = [self toolButtonWithTitle:title tag:idx];
        [toolbarStack addArrangedSubview:toolButton];
    }];

    NSArray<NSDictionary *> *docsButtons = @[
        @{ @"title": @"Insert Image", @"action": NSStringFromSelector(@selector(insertImage:)) },
        @{ @"title": @"Add Slide", @"action": NSStringFromSelector(@selector(addSlideApp)) },
        @{ @"title": @"Add Presentation", @"action": NSStringFromSelector(@selector(addPresentationApp)) },
        @{ @"title": @"Scale 2x", @"action": NSStringFromSelector(@selector(scalePage:)) },
        @{ @"title": @"Prev", @"action": NSStringFromSelector(@selector(previousPage:)) },
        @{ @"title": @"Next", @"action": NSStringFromSelector(@selector(nextPage:)) }
    ];
    [docsButtons enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        UIButton *button = [self toolButtonWithTitle:item[@"title"] tag:-1];
        [button removeTarget:self action:@selector(selectAppliance:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];
        [toolbarStack addArrangedSubview:button];
    }];

    self.toolbarView.hidden = YES;
}

- (UIButton *)overlayButtonWithTitle:(NSString *)title color:(UIColor *)color action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    button.backgroundColor = color;
    button.layer.cornerRadius = 18;
    button.contentEdgeInsets = UIEdgeInsetsMake(8, 14, 8, 14);
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)toolButtonWithTitle:(NSString *)title tag:(NSInteger)tag
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    button.tag = tag;
    button.backgroundColor = [UIColor colorWithRed:0.05 green:0.62 blue:0.98 alpha:1];
    button.layer.cornerRadius = 16;
    button.contentEdgeInsets = UIEdgeInsetsMake(7, 12, 7, 12);
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button addTarget:self action:@selector(selectAppliance:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)updateWritableUI
{
    BOOL writable = self.room.isWritable;
    [self.writableButton setTitle:writable ? @"移除可写" : @"获取可写" forState:UIControlStateNormal];
    self.toolbarView.hidden = !writable;
}

#pragma mark - Actions

- (void)toggleWritable:(UIButton *)sender
{
    BOOL next = !self.room.isWritable;
    __weak typeof(self) weakSelf = self;
    [self.room setWritable:next completionHandler:^(BOOL isWritable, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"[Whiteboard] setWritable failed: %@", error);
            }
            [weakSelf updateWritableUI];
        });
    }];
}

- (void)exitRoom:(UIButton *)sender
{
    __weak typeof(self) weakSelf = self;
    [self leaveRoomWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (void)selectAppliance:(UIButton *)sender
{
    WhiteMemberState *state = [[WhiteMemberState alloc] init];
    switch (sender.tag) {
        case 0:
            state.currentApplianceName = AppliancePencil;
            break;
        case 1:
            state.currentApplianceName = ApplianceText;
            break;
        case 2:
            state.currentApplianceName = ApplianceSelector;
            break;
        case 3:
            state.currentApplianceName = ApplianceEraser;
            break;
        case 4:
            state.currentApplianceName = ApplianceShape;
            state.shapeType = ApplianceShapeTypePentagram;
            break;
        case 5:
            state.currentApplianceName = ApplianceClicker;
            break;
        case 6:
            state.currentApplianceName = ApplianceHand;
            break;
        default:
            return;
    }
    [self.room setMemberState:state];
}

#pragma mark - Extras

- (NSDictionary *)appliancePluginExtras
{
    return @{
        @"useSimple": @YES,
        @"useBackgroundThread": @YES,
        @"allowImageBitmapFallback": @(self.allowImageBitmapFallback),
        @"cursor": @{
            @"enable": @YES,
            @"expirationTime": @500,
            @"syncedLabel": @{
                @"enableShowName": @YES
            },
            @"appearance": @{
                @"pencil": @{
                    @"synced": @{
                        @"enableShowName": @NO
                    }
                },
                @"clicker": @{
                    @"synced": @{
                        @"images": @{
                            @"standardResolution": @"https://api.iconify.design/mdi:video-wireless-outline.svg?color=%237f7f7f"
                        }
                    }
                }
            }
        },
        @"bezier": @{
            @"enable": @NO,
            @"maxDrawCount": @200
        },
        @"textEditor": @{
            @"showFloatBar": @NO,
            @"canSelectorSwitch": @NO,
            @"rightBoundBreak": @YES
        }
    };
}

- (void)scalePage:(UIButton *)sender
{
    if (!self.room) {
        return;
    }
    WhiteWindowDocsEventOptions *options = [[WhiteWindowDocsEventOptions alloc] init];
    options.target = self.currentDocsAppId;
    options.scale = @2.0;
    __weak typeof(self) weakSelf = self;
    [self.room dispatchDocsEvent:WhiteWindowDocsEventScalePage options:options completionHandler:^(WhiteDispatchDocsEventResult *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *failure = result.message.length ? [NSString stringWithFormat:@" (%@: %@)", result.reason, result.message] : @"";
            NSLog(@"[Whiteboard] dispatch scalePage(2x): %@%@", result.accepted ? @"YES" : @"NO", failure);
            (void)weakSelf;
        });
    }];
}

- (void)insertImage:(UIButton *)sender
{
    if (!self.room) {
        return;
    }
    WhiteImageInformation *info = [[WhiteImageInformation alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    [self.room insertImage:info src:@"https://p5.ssl.qhimg.com/t01a2bd87890397464a.png"];
}

- (void)addSlideApp
{
    if (!self.room) {
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/appliance-slide/%@", NSUUID.UUID.UUIDString];
    WhiteAppParam *param = [WhiteAppParam createSlideApp:path
                                                   taskId:kAppliancePluginSlideTaskId
                                                      url:kAppliancePluginSlidePrefix
                                                    title:@"Slide 1280x720"];
    param.originSize = [[WhiteWindowOriginSize alloc] initWithWidth:kAppliancePluginOriginWidth
                                                              height:kAppliancePluginOriginHeight];
    __weak typeof(self) weakSelf = self;
    [self.room addApp:param completionHandler:^(NSString *appId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.currentDocsAppId = appId;
            NSLog(@"[Whiteboard] add slide app: %@", appId);
        });
    }];
}

- (void)addPresentationApp
{
    if (!self.room) {
        return;
    }
    NSArray<WhiteScene *> *scenes = @[
        [[WhiteScene alloc] initWithName:@"1" ppt:[[WhitePptPage alloc] initWithSrc:@"https://convertcdn.netless.link/staticConvert/18140800fe8a11eb8cb787b1c376634e/1.png" size:CGSizeMake(714, 1010)]],
        [[WhiteScene alloc] initWithName:@"2" ppt:[[WhitePptPage alloc] initWithSrc:@"https://convertcdn.netless.link/staticConvert/18140800fe8a11eb8cb787b1c376634e/2.png" size:CGSizeMake(714, 1010)]]
    ];
    WhiteAppParam *param = [WhiteAppParam createPresentationApp:@"/appliance-presentation"
                                                           scenes:scenes
                                                            title:@"Presentation 1280x720"];
    param.originSize = [[WhiteWindowOriginSize alloc] initWithWidth:kAppliancePluginOriginWidth
                                                              height:kAppliancePluginOriginHeight];
    __weak typeof(self) weakSelf = self;
    [self.room addApp:param completionHandler:^(NSString *appId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.currentDocsAppId = appId;
            NSLog(@"[Whiteboard] add presentation app: %@", appId);
        });
    }];
}

- (void)previousPage:(UIButton *)sender
{
    [self dispatchDocsEvent:WhiteWindowDocsEventPrevPage target:self.currentDocsAppId];
}

- (void)nextPage:(UIButton *)sender
{
    [self dispatchDocsEvent:WhiteWindowDocsEventNextPage target:self.currentDocsAppId];
}

- (void)dispatchDocsEvent:(WhiteWindowDocsEventKey)event target:(NSString *)target
{
    if (!self.room) {
        return;
    }
    WhiteWindowDocsEventOptions *options = [[WhiteWindowDocsEventOptions alloc] init];
    options.target = target;
    __weak typeof(self) weakSelf = self;
    [self.room dispatchDocsEvent:event options:options completionHandler:^(WhiteDispatchDocsEventResult *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[Whiteboard] dispatch %@ target=%@: %@ reason=%@", event, target ?: @"focused", result.accepted ? @"YES" : @"NO", result.reason);
            (void)weakSelf;
        });
    }];
}

#pragma mark - WhiteCommonCallbackDelegate

- (void)onBackgroundImageLoad:(WhiteBackgroundImageLoadEvent *)event
{
    NSLog(@"[Whiteboard] backgroundImageLoad: name=%@ state=%@ source=%@ viewId=%@ scenePath=%@",
          event.name, event.state, event.source, event.viewId, event.scenePath);
    if (![event.state isEqualToString:@"failed"]) {
        return;
    }
    // mainView 可直接比较；appId 对应的路径由 reload API 在插件内原子校验。
    if ([event.viewId isEqualToString:@"mainView"] &&
        ![event.scenePath isEqualToString:self.room.sceneState.scenePath]) {
        return;
    }
    WhiteReloadBackgroundImageParams *params = [[WhiteReloadBackgroundImageParams alloc] init];
    params.source = event.source;
    params.viewId = event.viewId;
    params.scenePath = event.scenePath;
    [self.sdk reloadBackgroundImage:params completionHandler:^(WhiteReloadBackgroundImageResult *result, NSError *error) {
        NSLog(@"[Whiteboard] reloadBackgroundImage: %@ error: %@", result, error);
    }];
}

- (void)onApplianceInitLoadingChange:(WhiteApplianceInitLoadingChangeEvent *)event
{
    NSLog(@"[Whiteboard] appliance init loading change: name=%@ loading=%d phase=%@ status=%@",
          event.name, event.loading, event.phase, event.status);
}

- (void)localLogStateChange:(NSDictionary *)state
{
    NSLog(@"[Whiteboard] local log state changed: %@", state);
}

@end
