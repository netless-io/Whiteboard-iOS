//
//  WhiteCustomAppViewController.m
//  Whiteboard_Example
//
//  Created by xuyunshi on 2022/3/22.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "WhiteCustomAppViewController.h"

@interface WhiteCustomAppViewController ()

- (NSDictionary *)embeddedPlyrStateWithMediaURL:(NSString *)mediaURL title:(NSString *)title;
- (NSDictionary *)embeddedPlyrAttributesWithPageURL:(NSString *)pageURL
                                           mediaURL:(NSString *)mediaURL
                                              title:(NSString *)title;
- (nullable NSString *)embeddedPlyrProviderForMediaURL:(NSString *)mediaURL;
- (NSString *)embeddedPlyrTypeForMediaURL:(NSString *)mediaURL;

@end

@implementation WhiteCustomAppViewController

static NSString * const WhiteEmbeddedPlyrPageURL = @"https://plyr-cdn.netless.group/index.html";
static NSString * const WhiteEmbeddedPlyrMediaURL = @"https://www.youtube.com/watch?v=bTqVqk7FSmY";
static NSString * const WhiteEmbeddedPageAppScriptURL = @"https://cdn.jsdelivr.net/npm/@netless/app-embedded-page@0.1.3/dist/main.iife.js";
static NSString * const WhiteEmbeddedPageAppVariable = @"NetlessAppEmbeddedPageForExample";

static NSString *WhiteEmbeddedPlyrAppIdentityURL(void) {
    NSString *bundleId = [NSBundle mainBundle].bundleIdentifier ?: @"localhost";
    return [NSString stringWithFormat:@"https://%@", bundleId];
}

static WhiteRegisterAppParams *WhiteCreateEmbeddedPageRegisterParams(void) {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"embedPage.iife" ofType:@"js"];
    NSError *readError = nil;
    NSString *jsString = jsPath ? [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:&readError] : nil;
    if (jsString.length > 0) {
        jsString = [jsString stringByAppendingFormat:@"\nvar %@ = (typeof NetlessAppEmbeddedPage !== 'undefined' && (NetlessAppEmbeddedPage.default || NetlessAppEmbeddedPage));\n", WhiteEmbeddedPageAppVariable];
        return [WhiteRegisterAppParams paramsWithJavascriptString:jsString
                                                             kind:@"EmbeddedPage"
                                                       appOptions:@{}
                                                         variable:WhiteEmbeddedPageAppVariable];
    }
    NSLog(@"load local embedPage.iife.js failed: %@", readError);
    return [WhiteRegisterAppParams paramsWithUrl:WhiteEmbeddedPageAppScriptURL
                                            kind:@"EmbeddedPage"
                                      appOptions:@{}];
}

- (instancetype)init
{
    self.sdkConfig.useMultiViews = YES;
    self.sdkConfig.enableAppliancePlugin = YES;
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
    NSString *variable = @"NetlessAppMonacoForExample";
    NSString* jsPath = [[NSBundle mainBundle] pathForResource:@"monaco.iife" ofType:@"js"];
    NSString* jsString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:jsPath] encoding:NSUTF8StringEncoding error:nil];
    jsString = [jsString stringByAppendingFormat:@"\nvar %@ = (typeof NetlessAppMonaco !== 'undefined' && (NetlessAppMonaco.default || NetlessAppMonaco));\n", variable];
    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithJavascriptString:jsString
                                                  kind:kind
                                            appOptions:@{}
                                              variable:variable];
    
//    WhiteRegisterAppParams* params = [WhiteRegisterAppParams paramsWithUrl:@"https://cdn.jsdelivr.net/npm/@netless/app-monaco@0.1.13-beta.0/dist/main.iife.js"
//                                                  kind:kind
//                                            appOptions:@{}];
    
    [self.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"registerMonaco failed: %@", error);
        } else {
            NSLog(@"registerMonaco success");
        }
    }];
}

- (void)registerEmbedPage
{
    WhiteRegisterAppParams *params = WhiteCreateEmbeddedPageRegisterParams();
    
    [self.sdk registerAppWithParams:params completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"registerEmbedPage failed: %@", error);
        } else {
            NSLog(@"registerEmbedPage success");
        }
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

- (void)addEmbeddedPlyr
{
    NSString *title = @"Embedded Plyr";
    WhiteAppOptions *options = [[WhiteAppOptions alloc] init];
    options.title = title;

    WhiteAppParam *app = [[WhiteAppParam alloc] initWithKind:@"EmbeddedPage"
                                                     options:options
                                                       attrs:[self embeddedPlyrAttributesWithPageURL:WhiteEmbeddedPlyrPageURL
                                                                                            mediaURL:WhiteEmbeddedPlyrMediaURL
                                                                                               title:title]];

    [self.room addApp:app completionHandler:^(NSString * _Nonnull appId) {
        NSLog(@"Embedded Plyr app added: %@", appId);
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

- (NSDictionary *)embeddedPlyrAttributesWithPageURL:(NSString *)pageURL
                                           mediaURL:(NSString *)mediaURL
                                              title:(NSString *)title
{
    return @{
        @"src": pageURL ?: @"",
        @"store": @{
            @"state": [self embeddedPlyrStateWithMediaURL:mediaURL title:title]
        }
    };
}

- (NSDictionary *)embeddedPlyrStateWithMediaURL:(NSString *)mediaURL title:(NSString *)title
{
    NSTimeInterval nowMs = [[NSDate date] timeIntervalSince1970] * 1000.0;
    NSMutableDictionary *state = [@{
        @"src": mediaURL ?: @"",
        @"type": [self embeddedPlyrTypeForMediaURL:mediaURL],
        @"poster": @"",
        @"paused": @YES,
        @"currentTime": @0,
        @"useNewPlayer": @YES,
        @"useCustomControls": @YES,
        @"volume": @1,
        @"muted": @NO,
        @"playTimeState": @[@YES, @((long long)nowMs), @((long long)nowMs)],
        @"syncVolume": @NO,
        @"syncMuted": @NO,
        @"customControlsTitle": title ?: @"Embedded Plyr",
        @"allowBackgroundPlayback": @YES,
        @"keepPlayerStateInSync": @YES
    } mutableCopy];

    NSString *provider = [self embeddedPlyrProviderForMediaURL:mediaURL];
    if (provider.length > 0) {
        state[@"provider"] = provider;
        state[@"type"] = @"";
        if ([provider isEqualToString:@"youtube"]) {
            NSString *appIdentityURL = WhiteEmbeddedPlyrAppIdentityURL();
            state[@"youtubeOrigin"] = appIdentityURL;
            state[@"youtubeWidgetReferrer"] = appIdentityURL;
        }
    }

    return state.copy;
}

- (nullable NSString *)embeddedPlyrProviderForMediaURL:(NSString *)mediaURL
{
    NSString *lowercased = mediaURL.lowercaseString;
    if ([lowercased containsString:@"youtube.com"] || [lowercased containsString:@"youtu.be"]) {
        return @"youtube";
    }
    if ([lowercased containsString:@"vimeo.com"]) {
        return @"vimeo";
    }
    return nil;
}

- (NSString *)embeddedPlyrTypeForMediaURL:(NSString *)mediaURL
{
    NSString *sanitized = [[mediaURL componentsSeparatedByString:@"?"] firstObject] ?: mediaURL;
    NSString *lowercased = sanitized.lowercaseString;
    if ([lowercased hasSuffix:@".mp4"]) return @"video/mp4";
    if ([lowercased hasSuffix:@".mp3"]) return @"audio/mpeg";
    if ([lowercased hasSuffix:@".m4a"]) return @"audio/mp4";
    if ([lowercased hasSuffix:@".webm"]) return @"video/webm";
    if ([lowercased hasSuffix:@".wav"]) return @"audio/wav";
    if ([lowercased hasSuffix:@".m3u8"]) return @"application/vnd.apple.mpegurl";
    return @"";
}

- (void)setupShareBarItem
{
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"Plyr" style:UIBarButtonItemStylePlain target:self action:@selector(addEmbeddedPlyr)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"EmbedPage" style:UIBarButtonItemStylePlain target:self action:@selector(addEmbedPage)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithTitle:@"VSCode" style:UIBarButtonItemStylePlain target:self action:@selector(addMonaco)];
    
    self.navigationItem.rightBarButtonItems = @[item1, item2, item3];
}



@end
