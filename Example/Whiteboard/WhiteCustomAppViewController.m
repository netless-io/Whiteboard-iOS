//
//  WhiteCustomAppViewController.m
//  Whiteboard_Example
//
//  Created by xuyunshi on 2022/3/22.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "WhiteCustomAppViewController.h"

@interface WhiteCustomAppViewController ()

@end

@implementation WhiteCustomAppViewController

- (instancetype)init
{
    self.sdkConfig.useMultiViews = YES;
    return [super init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerEmbedPage];
    [self registerMonaco];
}

- (void)registerMonaco
{
    // 该示例演示的是一个VSCode插件
    NSString* kind = @"Monaco";
    NSString* jsPath = [[NSBundle mainBundle] pathForResource:@"monaco.iife" ofType:@"js"];
    NSString* jsString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:nil];
    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithJavascriptString:jsString
                                                  kind:kind
                                            appOptions:@{}
                                              variable:@"NetlessAppMonaco.default"];
    
//    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithUrl:@"https://cdn.jsdelivr.net/npm/@netless/app-monaco@0.1.13-beta.0/dist/main.iife.js"
//                                                  kind:kind
//                                            appOptions:@{}];
    
    [self.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        return;
    }];
}

- (void)registerEmbedPage
{
    NSString* kind = @"EmbeddedPage";
    NSString* variable = @"NetlessAppEmbeddedPage.default";
    NSString* jsPath = [[NSBundle mainBundle] pathForResource:@"embedPage.iife" ofType:@"js"];
    NSString* jsString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:nil];
    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithJavascriptString:jsString kind:kind appOptions:@{} variable:variable];
    
    [self.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        return;
    }];
}

- (void)addEmbedPage
{
    WhiteAppOptions* options = [[WhiteAppOptions alloc] init];
    options.title = @"My page 1";
    options.scenePath = @"/embedPage";
    WhiteAppParam* app = [[WhiteAppParam alloc] initWithKind:@"EmbeddedPage"
                                                     options:options
                                                       attrs:@{
        @"src": @"https://example.org/"
    }];
    [self.room addApp:app completionHandler:^(NSString * _Nonnull appId) {
        
    }];
}

- (void)addMonaco
{
    WhiteAppOptions* options = [[WhiteAppOptions alloc] init];
    options.title = @"VSCode";
    WhiteAppParam* app = [[WhiteAppParam alloc] initWithKind:@"Monaco"
                                                     options:options
                                                       attrs:@{
        
    }];
    [self.room addApp:app completionHandler:^(NSString * _Nonnull appId) {
        
    }];
}

- (void)setupShareBarItem
{
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"EmbedPage" style:UIBarButtonItemStylePlain target:self action:@selector(addEmbedPage)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"VSCode" style:UIBarButtonItemStylePlain target:self action:@selector(addMonaco)];
    
    self.navigationItem.rightBarButtonItems = @[item1, item2];
}



@end
