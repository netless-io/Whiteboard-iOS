//
//  StartController.m
//  white-demo-ios
//
//  Created by leavesster on 2018/8/19.
//  Copyright © 2018年 yleaf. All rights reserved.
//

#import "StartViewController.h"
#import "WhiteAppliancePluginViewController.h"

@implementation StartViewController

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
    [self.view addSubview:joinBtn];
    [joinBtn sizeToFit];
    joinBtn.center = self.view.center;
    joinBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
}

#pragma mark - Button Action
- (void)joinAppliancePluginWindowRoom:(UIButton *)sender {
    WhiteAppliancePluginViewController *vc = [[WhiteAppliancePluginViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
