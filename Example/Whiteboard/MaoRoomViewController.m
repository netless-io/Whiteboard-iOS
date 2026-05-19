//
//  MaoRoomViewController.m
//  Whiteboard_Example
//
//  Created by Codex on 2026/5/19.
//

#import "MaoRoomViewController.h"
#import "Masonry.h"
#import "WhiteUtils.h"

static NSString * const MaoDemoAppId = @"123/123";
static NSString * const MaoSlidePrefix = @"https://white-cover.oss-cn-hangzhou.aliyuncs.com/flat/dynamicConvert";
static NSString * const MaoSlideTaskId = @"46e8ff5db5714fec818f5594a6c55083";
static NSInteger const MaoFallbackPageCount = 12;

@interface WhiteRoomViewController (MaoRoomViewControllerPrivate)
- (void)setupViews;
- (void)joinRoomWithToken:(NSString *)roomToken;
- (void)actionAfterSuccessJoinRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken;
- (void)firePhaseChanged:(WhiteRoomPhase)phase;
- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState;
@end

@interface MaoRoomViewController () <WhiteRoomCallbackDelegate, WhiteSlideDelegate>

@property (nonatomic, strong) UIView *toolbarView;
@property (nonatomic, strong) UIScrollView *appScrollView;
@property (nonatomic, strong) UIStackView *appStackView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *pageStateLabel;
@property (nonatomic, strong) UIScrollView *previewScrollView;
@property (nonatomic, strong) UIStackView *previewStackView;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) NSDictionary<NSString *, WhiteAppSyncAttributes *> *apps;
@property (nonatomic, strong) NSCache<NSString *, UIImage *> *previewCache;
@property (nonatomic, strong) NSMutableSet<NSString *> *loadingPreviewURLs;
@property (nonatomic, copy, nullable) NSString *currentSlideAppId;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, assign) BOOL didAddInitialSlideApp;

@end

@implementation MaoRoomViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.useMultiViews = YES;
        _apps = @{};
        _previewCache = [[NSCache alloc] init];
        _previewCache.countLimit = 48;
        _loadingPreviewURLs = [NSMutableSet set];
        _currentPage = 1;
        _pageCount = MaoFallbackPageCount;
        WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:MaoDemoAppId];
        config.useMultiViews = YES;
        config.renderEngine = WhiteSdkRenderEngineCanvas;
        config.region = WhiteRegionCN;
        config.log = YES;
        self.sdkConfig = config;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Mao Custom Window";
    self.roomCallbackDelegate = self;
    [self.sdk setSlideDelegate:self];
    [self setupMaoViews];
    [self renderPreviewBar];
}

- (void)setupViews
{
    [super setupViews];
    self.controlView.hidden = YES;

    [self.boardView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(48);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-158);
    }];
}

- (void)joinRoomWithToken:(NSString *)roomToken
{
    if (!self.roomConfig) {
        NSDictionary *payload = @{@"avatar": @"https://white-pan.oss-cn-shanghai.aliyuncs.com/40/image/mask.jpg"};
        WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUUID:self.roomUuid roomToken:roomToken uid:@"1" userPayload:payload];
        roomConfig.cameraBound = [WhiteCameraBound defaultMinContentModeScale:0 maxContentModeScale:10];
        roomConfig.region = WhiteRegionCN;
        roomConfig.windowParams = [[WhiteWindowParams alloc] init];
        roomConfig.windowParams.fullscreen = YES;
        self.roomConfig = roomConfig;
    }
    [super joinRoomWithToken:roomToken];
}

- (void)actionAfterSuccessJoinRoom:(WhiteRoom *)room roomToken:(NSString *)roomToken
{
    [super actionAfterSuccessJoinRoom:room roomToken:roomToken];
    [self log:@"joined room"];
    [self refreshApps];
    if (!self.didAddInitialSlideApp) {
        self.didAddInitialSlideApp = YES;
        [self addSlideApp];
    }
}

- (void)setupMaoViews
{
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];

    self.toolbarView = [[UIView alloc] init];
    self.toolbarView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.toolbarView];
    [self.toolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@48);
    }];

    UIStackView *boxStack = [[UIStackView alloc] init];
    boxStack.axis = UILayoutConstraintAxisHorizontal;
    boxStack.spacing = 6;
    [self.toolbarView addSubview:boxStack];
    [boxStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.toolbarView).offset(8);
        make.centerY.equalTo(self.toolbarView);
        make.width.lessThanOrEqualTo(@340);
    }];
    [boxStack addArrangedSubview:[self controlButton:@"Normal" action:@selector(setNormalBoxState)]];
    [boxStack addArrangedSubview:[self controlButton:@"Max" action:@selector(setMaxBoxState)]];
    [boxStack addArrangedSubview:[self controlButton:@"Min" action:@selector(setMinBoxState)]];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
    self.closeButton.tintColor = UIColor.systemRedColor;
    [self.closeButton addTarget:self action:@selector(closeCurrentApp) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarView addSubview:self.closeButton];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.toolbarView).offset(-8);
        make.centerY.equalTo(self.toolbarView);
        make.width.height.equalTo(@44);
    }];

    self.appScrollView = [[UIScrollView alloc] init];
    self.appScrollView.showsHorizontalScrollIndicator = NO;
    [self.toolbarView addSubview:self.appScrollView];
    [self.appScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(boxStack.mas_right).offset(8);
        make.right.equalTo(self.closeButton.mas_left).offset(-8);
        make.top.bottom.equalTo(self.toolbarView);
    }];

    self.appStackView = [[UIStackView alloc] init];
    self.appStackView.axis = UILayoutConstraintAxisHorizontal;
    self.appStackView.spacing = 8;
    self.appStackView.alignment = UIStackViewAlignmentCenter;
    [self.appScrollView addSubview:self.appStackView];
    [self.appStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.appScrollView).insets(UIEdgeInsetsMake(0, 8, 0, 8));
        make.height.equalTo(self.appScrollView);
    }];

    UIView *bottomView = [[UIView alloc] init];
    bottomView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@158);
    }];

    self.previewScrollView = [[UIScrollView alloc] init];
    self.previewScrollView.showsHorizontalScrollIndicator = YES;
    [bottomView addSubview:self.previewScrollView];
    [self.previewScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(bottomView);
        make.height.equalTo(@92);
    }];

    self.previewStackView = [[UIStackView alloc] init];
    self.previewStackView.axis = UILayoutConstraintAxisHorizontal;
    self.previewStackView.spacing = 6;
    self.previewStackView.alignment = UIStackViewAlignmentCenter;
    [self.previewScrollView addSubview:self.previewStackView];
    [self.previewStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.previewScrollView).insets(UIEdgeInsetsMake(6, 8, 6, 8));
        make.height.equalTo(self.previewScrollView).offset(-12);
    }];

    UIStackView *actionStack = [[UIStackView alloc] init];
    actionStack.axis = UILayoutConstraintAxisHorizontal;
    actionStack.spacing = 8;
    actionStack.alignment = UIStackViewAlignmentCenter;
    [bottomView addSubview:actionStack];
    [actionStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bottomView).offset(8);
        make.top.equalTo(self.previewScrollView.mas_bottom).offset(8);
        make.height.equalTo(@44);
    }];
    [actionStack addArrangedSubview:[self controlButton:@"Add Slide" action:@selector(addSlideApp)]];
    [actionStack addArrangedSubview:[self controlButton:@"Prev" action:@selector(prevPage)]];
    [actionStack addArrangedSubview:[self controlButton:@"Next" action:@selector(nextPage)]];

    self.pageStateLabel = [[UILabel alloc] init];
    self.pageStateLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightMedium];
    self.pageStateLabel.textColor = UIColor.darkGrayColor;
    self.pageStateLabel.text = @"1/12";
    [actionStack addArrangedSubview:self.pageStateLabel];

    self.logTextView = [[UITextView alloc] init];
    self.logTextView.editable = NO;
    self.logTextView.font = [UIFont systemFontOfSize:11];
    self.logTextView.textColor = UIColor.darkGrayColor;
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    [bottomView addSubview:self.logTextView];
    [self.logTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(actionStack.mas_right).offset(8);
        make.right.equalTo(bottomView).offset(-8);
        make.top.equalTo(self.previewScrollView.mas_bottom).offset(6);
        make.bottom.equalTo(bottomView).offset(-6);
    }];
}

- (UIButton *)controlButton:(NSString *)title action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    button.contentEdgeInsets = UIEdgeInsetsMake(7, 10, 7, 10);
    button.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    button.layer.cornerRadius = 5;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor colorWithWhite:0.84 alpha:1].CGColor;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)setNormalBoxState
{
    [self.room setWindowBoxState:WhiteWindowBoxStateNormal];
}

- (void)setMaxBoxState
{
    [self.room setWindowBoxState:WhiteWindowBoxStateMax];
}

- (void)setMinBoxState
{
    [self.room setWindowBoxState:WhiteWindowBoxStateMini];
}

- (void)addSlideApp
{
    if (!self.room) {
        [self log:@"room not ready"];
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/mao-slide/%@", NSUUID.UUID.UUIDString];
    WhiteAppParam *param = [WhiteAppParam createSlideApp:path
                                                  taskId:MaoSlideTaskId
                                                     url:MaoSlidePrefix
                                                   title:@"Mao Slide"];
    __weak typeof(self) weakSelf = self;
    [self.room addApp:param completionHandler:^(NSString * _Nonnull appId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.currentSlideAppId = appId;
            [weakSelf log:[NSString stringWithFormat:@"add slide: %@", appId]];
            [weakSelf refreshApps];
            [weakSelf querySlidePageState];
        });
    }];
}

- (void)refreshApps
{
    if (!self.room) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *,WhiteAppSyncAttributes *> * _Nonnull apps, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [weakSelf log:[NSString stringWithFormat:@"query apps failed: %@", error.localizedDescription]];
                return;
            }
            weakSelf.apps = apps ?: @{};
            [weakSelf renderAppBar];
        });
    }];
}

- (void)renderAppBar
{
    for (UIView *view in self.appStackView.arrangedSubviews) {
        [self.appStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    if (self.apps.count == 0) {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"No apps";
        label.textColor = UIColor.grayColor;
        label.font = [UIFont systemFontOfSize:13];
        [self.appStackView addArrangedSubview:label];
        return;
    }
    NSArray<NSString *> *keys = [self.apps.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *appId in keys) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = [keys indexOfObject:appId];
        [button setTitle:appId forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        button.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        button.contentEdgeInsets = UIEdgeInsetsMake(8, 10, 8, 10);
        button.layer.cornerRadius = 5;
        button.layer.borderWidth = 1;
        BOOL selected = [appId isEqualToString:self.currentSlideAppId];
        button.backgroundColor = selected ? [UIColor colorWithRed:0.84 green:0.92 blue:1 alpha:1] : UIColor.whiteColor;
        button.layer.borderColor = selected ? UIColor.systemBlueColor.CGColor : [UIColor colorWithWhite:0.84 alpha:1].CGColor;
        [button addTarget:self action:@selector(appButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button.widthAnchor constraintLessThanOrEqualToConstant:220].active = YES;
        [self.appStackView addArrangedSubview:button];
    }
}

- (void)appButtonTapped:(UIButton *)sender
{
    NSArray<NSString *> *keys = [self.apps.allKeys sortedArrayUsingSelector:@selector(compare:)];
    if (sender.tag >= keys.count) {
        return;
    }
    NSString *appId = keys[sender.tag];
    self.currentSlideAppId = appId;
    [self.room focusApp:appId];
    [self renderAppBar];
    [self querySlidePageState];
}

- (void)closeCurrentApp
{
    if (self.currentSlideAppId.length == 0) {
        [self log:@"no focused app to close"];
        return;
    }
    NSString *appId = self.currentSlideAppId;
    __weak typeof(self) weakSelf = self;
    [self.room closeApp:appId completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf log:[NSString stringWithFormat:@"close app: %@", appId]];
            if ([weakSelf.currentSlideAppId isEqualToString:appId]) {
                weakSelf.currentSlideAppId = nil;
            }
            [weakSelf refreshAppsAndFocusAfterClosingApp:appId];
        });
    }];
}

- (void)refreshAppsAndFocusAfterClosingApp:(NSString *)closedAppId
{
    if (!self.room) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.room queryAllAppsWithCompletionHandler:^(NSDictionary<NSString *,WhiteAppSyncAttributes *> * _Nonnull apps, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [weakSelf log:[NSString stringWithFormat:@"query apps failed: %@", error.localizedDescription]];
                return;
            }
            weakSelf.apps = apps ?: @{};
            NSString *nextAppId = [weakSelf nextFocusAppIdAfterClosingApp:closedAppId apps:weakSelf.apps];
            if (nextAppId.length > 0) {
                weakSelf.currentSlideAppId = nextAppId;
                [weakSelf.room focusApp:nextAppId];
                [weakSelf querySlidePageState];
                [weakSelf log:[NSString stringWithFormat:@"focus app: %@", nextAppId]];
            } else {
                weakSelf.currentPage = 1;
                weakSelf.pageCount = MaoFallbackPageCount;
                weakSelf.pageStateLabel.text = @"0/0";
                [weakSelf renderPreviewBar];
            }
            [weakSelf renderAppBar];
        });
    }];
}

- (NSString *)nextFocusAppIdAfterClosingApp:(NSString *)closedAppId apps:(NSDictionary<NSString *,WhiteAppSyncAttributes *> *)apps
{
    NSArray<NSString *> *keys = [apps.allKeys sortedArrayUsingSelector:@selector(compare:)];
    if (keys.count == 0) {
        return nil;
    }
    NSUInteger insertionIndex = [keys indexOfObjectPassingTest:^BOOL(NSString * _Nonnull appId, NSUInteger idx, BOOL * _Nonnull stop) {
        return [appId compare:closedAppId] == NSOrderedDescending;
    }];
    if (insertionIndex != NSNotFound && insertionIndex < keys.count) {
        return keys[insertionIndex];
    }
    return keys.lastObject;
}

- (void)prevPage
{
    [self dispatchDocsEvent:WhiteWindowDocsEventPrevPage page:nil];
}

- (void)nextPage
{
    [self dispatchDocsEvent:WhiteWindowDocsEventNextPage page:nil];
}

- (void)jumpToPage:(NSNumber *)page
{
    [self dispatchDocsEvent:WhiteWindowDocsEventJumpToPage page:page];
}

- (void)dispatchDocsEvent:(WhiteWindowDocsEventKey)event page:(NSNumber * _Nullable)page
{
    if (!self.room) {
        return;
    }
    WhiteWindowDocsEventOptions *options = nil;
    if (page) {
        options = [[WhiteWindowDocsEventOptions alloc] init];
        options.page = page;
    }
    __weak typeof(self) weakSelf = self;
    [self.room dispatchDocsEvent:event options:options completionHandler:^(bool success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf log:[NSString stringWithFormat:@"dispatch %@: %@", event, success ? @"YES" : @"NO"]];
            [weakSelf querySlidePageState];
        });
    }];
}

- (void)querySlidePageState
{
    if (!self.room || self.currentSlideAppId.length == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.room querySlidePageState:self.currentSlideAppId completionHandler:^(WhiteSlidePageState * _Nullable pageState, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [weakSelf log:[NSString stringWithFormat:@"query slide page failed: %@", error.localizedDescription]];
                return;
            }
            [weakSelf updateSlideAppId:pageState.appId page:pageState.page pageCount:pageState.pageCount];
        });
    }];
}

- (void)updateSlideAppId:(NSString *)appId page:(NSInteger)page pageCount:(NSInteger)pageCount
{
    self.currentSlideAppId = appId;
    self.currentPage = MAX(page, 1);
    self.pageCount = MAX(pageCount, 1);
    self.pageStateLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)self.currentPage, (long)self.pageCount];
    [self renderAppBar];
    [self renderPreviewBar];
}

- (void)renderPreviewBar
{
    for (UIView *view in self.previewStackView.arrangedSubviews) {
        [self.previewStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    NSInteger count = MAX(self.pageCount, 1);
    for (NSInteger page = 1; page <= count; page++) {
        UIControl *item = [[UIControl alloc] init];
        item.tag = page;
        item.backgroundColor = page == self.currentPage ? [UIColor colorWithRed:0.84 green:0.92 blue:1 alpha:1] : UIColor.whiteColor;
        item.layer.cornerRadius = 5;
        item.layer.borderWidth = 1;
        item.layer.borderColor = page == self.currentPage ? UIColor.systemBlueColor.CGColor : [UIColor colorWithWhite:0.86 alpha:1].CGColor;
        [item addTarget:self action:@selector(previewTapped:) forControlEvents:UIControlEventTouchUpInside];
        [item mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@120);
            make.height.equalTo(@80);
        }];

        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        [item addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(item).inset(4);
            make.height.equalTo(@54);
        }];

        UILabel *label = [[UILabel alloc] init];
        label.text = [NSString stringWithFormat:@"%ld", (long)page];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
        label.textColor = UIColor.darkTextColor;
        [item addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(item);
            make.top.equalTo(imageView.mas_bottom);
        }];

        [self.previewStackView addArrangedSubview:item];
        [self loadPreviewForPage:page imageView:imageView];
    }
}

- (void)previewTapped:(UIControl *)sender
{
    [self jumpToPage:@(sender.tag)];
}

- (NSString *)previewURLForPage:(NSInteger)page
{
    return [NSString stringWithFormat:@"%@/%@/preview/%ld.png", MaoSlidePrefix, MaoSlideTaskId, (long)page];
}

- (void)loadPreviewForPage:(NSInteger)page imageView:(UIImageView *)imageView
{
    NSString *url = [self previewURLForPage:page];
    imageView.accessibilityIdentifier = url;
    UIImage *cached = [self.previewCache objectForKey:url];
    if (cached) {
        imageView.image = cached;
        return;
    }
    imageView.image = nil;
    if ([self.loadingPreviewURLs containsObject:url]) {
        return;
    }
    [self.loadingPreviewURLs addObject:url];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingPreviewURLs removeObject:url];
            if (!image) {
                if (error) {
                    [weakSelf log:[NSString stringWithFormat:@"preview load failed: %@", error.localizedDescription]];
                }
                return;
            }
            [weakSelf.previewCache setObject:image forKey:url];
            if ([imageView.accessibilityIdentifier isEqualToString:url]) {
                imageView.image = image;
            }
        });
    }];
    [task resume];
}

- (void)log:(NSString *)message
{
    NSString *current = self.logTextView.text ?: @"";
    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@", message, current];
}

#pragma mark - WhiteRoomCallbackDelegate

- (void)firePhaseChanged:(WhiteRoomPhase)phase
{
    [super firePhaseChanged:phase];
    [self log:[NSString stringWithFormat:@"phase: %ld", (long)phase]];
}

- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState
{
    [super fireRoomStateChanged:modifyState];
    if (modifyState.windowBoxState) {
        [self log:[NSString stringWithFormat:@"windowBoxState: %@", modifyState.windowBoxState]];
    }
    if (modifyState.appState) {
        self.currentSlideAppId = modifyState.appState.focusedId;
        [self refreshApps];
        if (self.currentSlideAppId.length > 0) {
            [self querySlidePageState];
        } else {
            self.currentPage = 1;
            self.pageCount = MaoFallbackPageCount;
            self.pageStateLabel.text = @"0/0";
            [self renderPreviewBar];
        }
    }
}

#pragma mark - WhiteSlideDelegate

- (void)onSlidePageStateChanged:(NSString *)appId page:(NSInteger)page pageCount:(NSInteger)pageCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSlideAppId:appId page:page pageCount:pageCount];
    });
}

@end
