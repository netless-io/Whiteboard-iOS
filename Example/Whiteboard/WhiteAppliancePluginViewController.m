//
//  WhiteAppliancePluginViewController.m
//  Whiteboard_Example
//
//  Created by Codex on 2026/8/19.
//

#import "WhiteAppliancePluginViewController.h"
#import "Masonry.h"
#import "WhiteUtils.h"

static NSString * const kAppliancePluginRoomUUID = @"cd1221809b8111f1aaeead87383431cf";
static NSString * const kAppliancePluginRoomToken = @"NETLESSROOM_YWs9VWtNUk92M1JIN2I2Z284dCZleHBpcmVBdD0xNzg3Mzc4Mzk0OTY3Jm5vbmNlPTg4MzQzNjcwLTlkMjUtMTFmMS1iYzM4LWQ3Yjg5YzgwZTNlMSZyb2xlPTEmc2lnPWZkYjI5MjRkNmMwYTkxMmMzZWQ5YmU5OGZmMTZlNjA3ZDQyYjgxMzljNzA4NTVjMzVkOGM5NzlmOGJjMmY0NTUmdXVpZD1jZDEyMjE4MDliODExMWYxYWFlZWFkODczODM0MzFjZg";

@interface WhiteRoomViewController (WhiteAppliancePluginPrivate)
- (void)setupViews;
- (void)joinRoomWithToken:(NSString *)roomToken;
- (void)actionAfterSuccessJoinRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken;
@end

@interface WhiteAppliancePluginViewController () <WhiteCommonCallbackDelegate>

@property (nonatomic, strong) UIButton *writableButton;
@property (nonatomic, strong) UIButton *exitButton;
@property (nonatomic, strong) UIScrollView *toolbarView;

@end

@implementation WhiteAppliancePluginViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.roomUuid = kAppliancePluginRoomUUID;
        self.useMultiViews = YES;

        WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:[WhiteUtils appIdentifier]];
        config.useMultiViews = YES;
        config.renderEngine = WhiteSdkRenderEngineCanvas;
        config.region = WhiteRegionCN;
        config.log = YES;
        config.enableAppliancePlugin = YES;
        config.userCursor = YES;
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

        WhitePresentationAppOptions *presentationAppOptions = [[WhitePresentationAppOptions alloc] init];
        presentationAppOptions.maxCameraScale = @4;
        presentationAppOptions.useScrollbar = @YES;
        config.presentationAppOptions = presentationAppOptions;

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
        windowParams.overwriteStyles = @".netless-app-slide-wb-view {clip-path: none !important;}";
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
        @"canvasOpt": @{
            @"contextType": @"2d"
        },
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
        @"syncOpt": @{
            @"interval": @100,
            @"smoothSync": @NO
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
