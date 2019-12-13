//
//  WhiteBaseViewController.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/4.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import "WhiteBaseViewController.h"
#import <Masonry/Masonry.h>

@interface WhiteBaseViewController ()<WhiteCommonCallbackDelegate>
@property (nonatomic, strong, nonnull) WhiteSdkConfiguration *sdkConfig;
@end

@implementation WhiteBaseViewController

- (instancetype)initWithSdkConfig:(WhiteSdkConfiguration *)sdkConfig
{
    if (self = [super init]) {
        _sdkConfig = sdkConfig;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self initSDK];
}

#pragma mark - WhiteBoardView
- (void)setupViews {
    // 1. 初始化 WhiteBoardView，
    // FIXME: 请提前加入视图栈，否则 iOS12 上，SDK 无法正常初始化。
    self.boardView = [[WhiteBoardView alloc] init];
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
        make.left.bottom.right.equalTo(self.view);
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFrame) name:@"changeframe" object:nil];
}

- (void)changeFrame
{
    CGFloat newOffset = CGRectGetMaxY(self.view.frame) == CGRectGetMaxY(self.boardView.frame) ? -200 : 0;
    
    [self.boardView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(newOffset);
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // room 需要调用 refreshViewSize（由于文字教具弹起键盘的原因，sdk 无法主动调用）
    });
}

#pragma mark - WhiteSDK
- (WhiteSdkConfiguration *)sdkConfig
{
    if (!_sdkConfig) {
        // 4. 初始化 SDK 配置项，根据需求配置属性
        WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
        
        //如果不需要拦截图片API，则不需要开启，页面内容较为复杂时，可能会有性能问题
        //    config.enableInterrupterAPI = YES;
        config.debug = YES;
        
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

@end
