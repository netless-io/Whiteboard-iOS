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
#import <Whiteboard/Whiteboard.h>
#import "WhitePureReplayViewController.h"
#import <SSZipArchive/SSZipArchive.h>
#import <NETURLSchemeHandler/NETURLSchemeHandler.h>

@interface StartViewController ()
@property (nonatomic, strong) UITextField *inputV;
@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillProportionally;
    stackView.alignment = UIStackViewAlignmentCenter;
    [self.view addSubview:stackView];
    
    stackView.frame = CGRectMake(0, 0, 300, 120);
    stackView.center = self.view.center;
    stackView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    UITextField *field = [[UITextField alloc] init];
    field.enabled = YES;
    field.placeholder = NSLocalizedString(@"输入房间ID，加入房间", nil);
    [stackView addArrangedSubview:field];
    self.inputV = field;
    
    UIButton *joinBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [joinBtn setTitle:NSLocalizedString(@"加入房间", nil) forState:UIControlStateNormal];
    [joinBtn addTarget:self action:@selector(joinRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:joinBtn];
    
    UIButton *createBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [createBtn setTitle:NSLocalizedString(@"创建新房间", nil) forState:UIControlStateNormal];
    [createBtn addTarget:self action:@selector(createRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    createBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [createBtn setTitle:NSLocalizedString(@"回放房间", nil) forState:UIControlStateNormal];
    [createBtn addTarget:self action:@selector(replayRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    createBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [createBtn setTitle:NSLocalizedString(@"纯白板回放房间", nil) forState:UIControlStateNormal];
    [createBtn addTarget:self action:@selector(pureReplayRoom:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:createBtn];
    
    
    for (UIView *view in stackView.arrangedSubviews) {
        [view setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [view setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeybroader:)];
    [self.view addGestureRecognizer:tap];

    [self downloadZip:@"https://convertcdn.netless.link/publicFiles.zip"];
    [self downloadZip:[NSString stringWithFormat:@"https://convertcdn.netless.link/dynamicConvert/%@.zip", @"e1ee27fdb0fc4b7c8f649291010c4882"]];
}

- (void)dismissKeybroader:(id)sender
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

@end
