//
//  StartController.m
//  white-demo-ios
//
//  Created by leavesster on 2018/8/19.
//  Copyright © 2018年 yleaf. All rights reserved.
//

#import "StartViewController.h"
#import "WhiteRoomViewController.h"
#import "WhitePlayerViewController.h"
#import "WhitePureReplayViewController.h"
#import "NETURLSchemeHandler.h"
#import "WhiteCustomAppViewController.h"
#if IS_SPM
#import "ZipArchive.h"
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#import "SSZipArchive.h"
#endif

@interface StartViewController ()
@property (nonatomic, strong) UITextField *inputV;
@property (nonatomic, strong) WhiteAdvanceConvertProgressPolling *advancePolling;
@property (nonatomic, strong) WhiteProjectorPolling *polling;
@property (nonatomic, strong) WhiteConverterV5 *pollingV5;
@end

@implementation StartViewController

- (UIButton *)createButtonWithTitle:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [btn setTitle:title forState:UIControlStateNormal];
    return btn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillProportionally;
    stackView.alignment = UIStackViewAlignmentCenter;
    [self.view addSubview:stackView];
    
    stackView.frame = CGRectMake(0, 0, 320, 240);
    stackView.center = self.view.center;
    stackView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    UITextField *field = [[UITextField alloc] init];
    field.enabled = YES;
    field.placeholder = NSLocalizedString(@"输入房间ID，加入房间", nil);
    [stackView addArrangedSubview:field];
    self.inputV = field;
    
    UIButton *joinBtn = [self createButtonWithTitle: NSLocalizedString(@"加入房间", nil)];
    [joinBtn addTarget:self action:@selector(joinRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:joinBtn];
    
    UIButton *joinWindowBtn = [self createButtonWithTitle: NSLocalizedString(@"加入多窗口房间", nil)];
    [joinWindowBtn addTarget:self action:@selector(joinWindowRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:joinWindowBtn];
    
    UIButton *joinAppliancePluginWindowRoomBtn = [self createButtonWithTitle: NSLocalizedString(@"加入多窗口房间(AppliancePlugin)", nil)];
    [joinAppliancePluginWindowRoomBtn addTarget:self action:@selector(joinAppliancePluginWindowRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:joinAppliancePluginWindowRoomBtn];
    
    UIButton *createBtn = [self createButtonWithTitle: NSLocalizedString(@"创建新房间", nil)];
    [createBtn addTarget:self action:@selector(createRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    createBtn = [self createButtonWithTitle: NSLocalizedString(@"回放房间", nil)];
    [createBtn addTarget:self action:@selector(replayRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    createBtn = [self createButtonWithTitle: NSLocalizedString(@"纯白板回放房间", nil)];
    [createBtn addTarget:self action:@selector(pureReplayRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    createBtn = [self createButtonWithTitle: NSLocalizedString(@"自定义插件房间", nil)];
    [createBtn addTarget:self action:@selector(customAppRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    createBtn = [self createButtonWithTitle: NSLocalizedString(@"转码查询", nil)];
    [createBtn addTarget:self action:@selector(convertPolling:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    for (UIView *view in stackView.arrangedSubviews) {
        [view setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [view setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [self.view addGestureRecognizer:tap];

    [self downloadZip:@"https://convertcdn.netless.link/publicFiles.zip"];
    /** 此处传入的 uuid 是 ppt 转换任务返回的 taskUUID 而不是房间的 uuid */
    [self downloadZip:[NSString stringWithFormat:@"https://convertcdn.netless.link/dynamicConvert/%@.zip", @"93b0bee742774cd58f6fef6ec5e12b92"]];
}

- (void)dismissKeyboard:(id)sender
{
    [self.inputV resignFirstResponder];
}

#pragma mark - Dynamic
//https://convertcdn.netless.link/publicFiles.zip
- (void)downloadZip:(NSString *)zipUrl
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:zipUrl]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            
            NSString *des = NSTemporaryDirectory();
            // zip 包解压后，会有一个叫 taskUUID 或者 publicFiles 的文件夹，里面的内容才是真正可以用的内容。
            if ([zipUrl containsString:@"publicFiles"]) {
                des = [des stringByAppendingPathComponent:@"convertcdn.netless.link"];
            } else {
                des = [des stringByAppendingPathComponent:@"convertcdn.netless.link/dynamicConvert"];
            }
            BOOL result = [SSZipArchive unzipFileAtPath:location.path toDestination:des];
            NSLog(@"download %@ success and unzip complete %d", zipUrl, result);
            [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
        } else {
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            if (![res isKindOfClass:[NSHTTPURLResponse class]]) {
                return;
            }
            
            if (res.statusCode < 200 || res.statusCode >= 400) {
                NSLog(@"response error: %@", response);
                return;
            }
        }
    }];
    [task resume];
}

#pragma mark - Button Action
- (void)joinRoom:(UIButton *)sender
{
    WhiteRoomViewController *vc = [[WhiteRoomViewController alloc] init];
    vc.roomUuid = self.inputV.text;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)joinWindowRoom:(UIButton *)sender {
    WhiteRoomViewController *vc = [[WhiteRoomViewController alloc] init];
    vc.roomUuid = self.inputV.text;
    vc.useMultiViews = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)joinAppliancePluginWindowRoom:(UIButton *)sender {
    WhiteRoomViewController *vc = [[WhiteRoomViewController alloc] init];
    vc.roomUuid = self.inputV.text;
    vc.useMultiViews = YES;
    vc.sdkConfig.enableAppliancePlugin = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createRoom:(UIButton *)sender
{
    WhiteRoomViewController *vc = [[WhiteRoomViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)replayRoom:(UIButton *)sender
{
    WhitePlayerViewController *vc = [[WhitePlayerViewController alloc] init];
    vc.roomUuid = self.inputV.text;
    
    #if defined(WhiteRoomUUID) && defined(WhiteRoomToken)
        if ([self.inputV.text length] == 0) {
            vc.roomUuid = WhiteRoomUUID;
        }
    #endif
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pureReplayRoom:(UIButton *)sender
{
    WhitePureReplayViewController *vc = [[WhitePureReplayViewController alloc] init];
    vc.roomUuid = self.inputV.text;

    #if defined(WhiteRoomUUID) && defined(WhiteRoomToken)
        if ([self.inputV.text length] == 0) {
            vc.roomUuid = WhiteRoomUUID;
        }
    #endif
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)customAppRoom:(UIButton *)sender
{
    WhiteCustomAppViewController *vc = [[WhiteCustomAppViewController alloc] init];
    vc.roomUuid = self.inputV.text;

    #if defined(WhiteRoomUUID) && defined(WhiteRoomToken)
        if ([self.inputV.text length] == 0) {
            vc.roomUuid = WhiteRoomUUID;
        }
    #endif
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)convertPolling:(UIButton *)sender
{
//    self.polling = [[WhiteProjectorPolling alloc] init];
//    [self.polling insertPollingTaskWithTaskUUID:@"" token:@"" region:WhiteRegionCN progress:^(CGFloat progress, WhiteProjectorQueryResult * _Nullable info) {
//        NSLog(@"progress %f", progress);
//    } result:^(BOOL success, WhiteProjectorQueryResult * _Nullable info, NSError * _Nullable error) {
//        NSLog(@"success %d, %@", success, error);
//    }];
//    [self.polling startPolling];
    
//    [WhiteProjectorPolling checkProgressWithTaskUUID:@"" token:@"" region:WhiteRegionCN result:^(WhiteProjectorQueryResult * _Nullable info, NSError * _Nullable error) {
//        NSLog(@"success %@, %@", error);
//    }];
    
//    self.pollingV5 = [[WhiteConverterV5 alloc] init];
//    [self.pollingV5 insertPollingTaskWithTaskUUID:@"" token:@"" region:WhiteRegionCN taskType:WhiteConvertTypeStatic progress:^(CGFloat progress, WhiteConversionInfoV5 * _Nullable info) {
//        
//    } result:^(BOOL success, WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
//        NSLog(@"success %d, %@", success, error);
//    }];
//    [self.pollingV5 startPolling];
    
    
//    [WhiteConverterV5 checkProgressWithTaskUUID:@"" token:@"" region:WhiteRegionCN taskType:WhiteConvertTypeStatic result:^(WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
//        NSLog(@"success %@", error);
//    }];
    
//    self.advancePolling = [[WhiteAdvanceConvertProgressPolling alloc] init];
//    [self.advancePolling insertV5PollingTaskWithTaskUUID:@"" token:@"" region:WhiteRegionCN taskType:WhiteConvertTypeStatic progress:^(CGFloat progress) {
//    } result:^(BOOL success, WhiteConversionInfoV5 * _Nullable info, NSError * _Nullable error) {
//        NSLog(@"success %d, %@", success, error);
//    }];
//    [self.advancePolling insertProjectorPollingTaskWithTaskUUID:@"" token:@"" region:WhiteRegionCN progress:^(CGFloat progress) {
//        
//    } result:^(BOOL success, WhiteProjectorQueryResult * _Nullable info, NSError * _Nullable error) {
//        NSLog(@"success %d, %@", success, error);
//    }];
//    [self.advancePolling startPolling];
}

@end
