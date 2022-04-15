//
//  WhiteBaseViewController.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/4.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import "WhiteBaseViewController.h"
#import "Masonry.h"
#import "NETURLSchemeHandler.h"
#import "WhiteUtils.h"

@interface WhiteBaseViewController ()<WhiteCommonCallbackDelegate>
@property (nonatomic, strong, nullable) NETURLSchemeHandler *schemeHandler API_AVAILABLE(ios(11.0));
@end

/** 动态 ppt 请求时的 scheme 部分，不能带 - */
static NSString *kPPTScheme = @"netless";

@implementation WhiteBaseViewController

- (instancetype)init
{
    if (self = [super init]) {
        if (@available(iOS 11.0, *)) {
            _schemeHandler = [[NETURLSchemeHandler alloc] initWithScheme:kPPTScheme directory:NSTemporaryDirectory()];
        }
    }
    return self;
}

- (instancetype)initWithSdkConfig:(WhiteSdkConfiguration *)sdkConfig
{
    if (self = [self init]) {
        _sdkConfig = sdkConfig;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self initSDK];
}

#pragma mark - Property

- (NSString *)roomUuid
{
    if (!_roomUuid) {
#ifdef WhiteRoomUUID
        _roomUuid = WhiteRoomUUID;
#endif
    }
    return _roomUuid;
}

#pragma mark - WhiteBoardView
- (void)setupViews {
    // 1. 初始化 WhiteBoardView，
    // FIXME: 请提前加入视图栈，否则 iOS12 上，SDK 无法正常初始化。
    
    if (@available(iOS 11, *)) {
        // 在初始化 sdk 时，配置 PPTParams 的 scheme，保证与此处传入的 scheme 一致。
        self.schemeHandler = [[NETURLSchemeHandler alloc] initWithScheme:kPPTScheme directory:NSTemporaryDirectory()];
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        [config setURLSchemeHandler:self.schemeHandler forURLScheme:kPPTScheme];
        self.boardView = [[WhiteBoardView alloc] initWithFrame:CGRectZero configuration:config];
    } else {
        self.boardView = [[WhiteBoardView alloc] init];
    }
    [self.view addSubview:self.boardView];
    
    // 2. 为 WhiteBoardView 做 iOS10 及其以下兼容
    /*
     WhiteBoardView 内部有 UIScrollView,
     在 iOS 10及其以下时，如果 WhiteBoardView 是当前视图栈中第一个 UIScrollView 的话，会出现内容错位。
     */
    if (@available(iOS 11, *)) {
    } else {
        //可以参考此处处理
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    // 3. 使用 Masonry 进行 Autolayout 处理
    [self.boardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.left.right.equalTo(self.view).inset(88);
        make.height.equalTo(self.boardView.mas_width).multipliedBy(9.0 / 16.0);
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFrame) name:@"changeframe" object:nil];
    
    // 4. ControlView
    ExampleControlView* controlView = [[ExampleControlView alloc] initWithItems:@[]];
    [self.view addSubview:controlView];
    [controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.boardView.mas_bottom).offset(10);
        make.left.right.equalTo(self.view).inset(10);
        make.bottom.equalTo(self.view);
    }];
    self.controlView = controlView;
}

- (void)changeFrame
{
    static int i = 0;
    if (i % 3 == 1) {
        [self.boardView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_topLayoutGuideBottom);
            make.left.bottom.right.equalTo(self.view);
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            // room 需要调用 refreshViewSize（由于文字教具弹起键盘的原因，sdk 无法主动调用）
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
        });
    } else if (i % 3 == 0) {
        [self.boardView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.width.equalTo(@90);
            make.height.equalTo(@51);
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            // room 需要调用 refreshViewSize（由于文字教具弹起键盘的原因，sdk 无法主动调用）
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
        });
    } else if (i % 3 == 2) {
        [self.boardView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_topLayoutGuideBottom);
            make.bottom.equalTo(self.view).inset(200);
            make.left.right.equalTo(self.view).inset(50);
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            // room 需要调用 refreshViewSize（由于文字教具弹起键盘的原因，sdk 无法主动调用）
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
        });
    }
    i++;
}

#pragma mark - WhiteSDK
- (WhiteSdkConfiguration *)sdkConfig
{
    if (!_sdkConfig) {
        // 4. 初始化 SDK 配置项，根据需求配置属性
        WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:[WhiteUtils appIdentifier]];
        config.renderEngine = WhiteSdkRenderEngineCanvas;
//        config.enableSyncedStore = YES;
        config.useMultiViews = self.useMultiViews;
        
        //如果不需要拦截图片API，则不需要开启，页面内容较为复杂时，可能会有性能问题
        //    config.enableInterrupterAPI = YES;
        config.log = YES;
        config.region = WhiteRegionCN;
        config.enableIFramePlugin = YES;
        //自定义 netless 协议，所有 ppt 请求，都由 https 更改为 kPPTScheme，需要配合 NETURLSchemeHandler 进行操作
        if (@available(iOS 11.0, *)) {
//            WhitePptParams *pptParams = [[WhitePptParams alloc] init];
//            pptParams.scheme = kPPTScheme;
//            config.pptParams = pptParams;
        }
        
        //打开用户头像显示信息
        config.userCursor = YES;
        _sdkConfig = config;
    }
    return _sdkConfig;
}

- (void)initSDK {
    // 5.初始化 SDK，传入 commomDelegate
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:self.sdkConfig commonCallbackDelegate:self.commonDelegate];
}

- (void)insertFontFace
{
    WhiteFontFace *f = [[WhiteFontFace alloc] initWithFontFamily:@"Times New Roman" src:@"url(https://white-pan.oss-cn-shanghai.aliyuncs.com/Pacifico-Regular.ttf)"];
    f.fontStyle = @"Italic";
    f.fontWeight = @"500";
    
    
    // loadFontFace 与 insertFontFace 二选一即可
    [self.sdk loadFontFaces:@[f] completionHandler:^(BOOL success, WhiteFontFace * _Nonnull fontFace, NSError * _Nullable error) {
        NSLog(@"success: %d fontface: %@ error:%@", success, fontFace, error);
    }];
    // [self.sdk insertFontFaces:@[f]];
    
    
    [self.sdk updateTextFont:@[@"Times New Roman"]];
}

#pragma mark - PopoverViewController
- (void)showPopoverViewController:(UIViewController *)vc sourceView:(id)sourceView
{
    vc.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *present = vc.popoverPresentationController;
    present.permittedArrowDirections = UIPopoverArrowDirectionAny;
    present.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
    if ([sourceView isKindOfClass:[UIView class]]) {
        present.sourceView = sourceView;
        present.sourceRect = [sourceView bounds];
    } else if ([sourceView isKindOfClass:[UIBarButtonItem class]]) {
        present.barButtonItem = sourceView;
    } else {
        present.sourceView = self.view;
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return YES;
}

#pragma mark - CallbackDelegate
- (id<WhiteCommonCallbackDelegate>)commonDelegate
{
    if (!_commonDelegate) {
        _commonDelegate = self;
    }
    return _commonDelegate;
}

#pragma mark - WhiteCommonCallbackDelegate
- (void)throwError:(NSError *)error
{
    NSLog(@"throwError: %@", error.userInfo);
}

- (NSString *)urlInterrupter:(NSString *)url
{
    return @"https://white-pan.oss-cn-shanghai.aliyuncs.com/124/image/beauty2.png";
}

- (void)sdkSetupFail:(NSError *)error {
    return;
}

- (void)pptMediaPlay
{
    NSLog(@"%s", __func__);
}

- (void)pptMediaPause
{
    NSLog(@"%s", __func__);
}

@end
