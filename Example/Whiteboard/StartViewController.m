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

    UIButton *imageBitmapBtn = [self createButtonWithTitle:NSLocalizedString(@"加入多窗口房间(AppliancePlugin + ImageBitmap)", nil)];
    [imageBitmapBtn addTarget:self action:@selector(joinAppliancePluginImageBitmapRoom:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[joinBtn, imageBitmapBtn]];
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
