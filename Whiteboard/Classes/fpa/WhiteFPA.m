//
//  WhiteFPA.m
//  Whiteboard
//
//  Created by yleaf on 2021/11/2.
//

#import "WhiteFPA.h"
#import "WhiteSocket.h"
#import <AgoraFpaProxyService/FpaProxyService.h>


@interface WhiteFPA ()
@end

@implementation WhiteFPA

#pragma mark - default Fpa Config
+ (FpaProxyServiceConfig *)defaultFpaConfig {
    FpaProxyServiceConfig *config = [[FpaProxyServiceConfig alloc] init];
    // 设置 App ID
    config.appId = @"81ae40d666ed4fdc9b883962e9873a0b";
    // 设置 token。如果不开启 Token 鉴权，必须填入 App ID
    config.token = @"81ae40d666ed4fdc9b883962e9873a0b";
    config.logLevel = FpaLogLevelInfo;
    config.logFilePath = [NSString stringWithFormat:@"%@/fpa.log", NSTemporaryDirectory()];
    return config;
}

+ (FpaHttpProxyChainConfig *)defaultChain {
    FpaHttpProxyChainConfig *httpConfig = [[FpaHttpProxyChainConfig alloc] init];
    NSMutableArray *array = [NSMutableArray array];
    FpaChainInfo *info =[FpaChainInfo fpaChainInfoWithChainId:285 address:@"gateway.netless.link" port:443 enableFallback:YES];
    [array addObject:info];
    httpConfig.chainArray = [array copy];
    httpConfig.fallbackWhenNoChainAvailable = YES;
    return httpConfig;
}

#pragma mark - Fpa

+ (void)setupFpa:(FpaProxyServiceConfig *)config chain:(FpaHttpProxyChainConfig *)chainInfo
{
     // 1. 初始化 config 的设置并创建 FPAService 对象
     // 2. 开启 FPA 服务并注册 FPAServiceDelegate
    [[FpaProxyService sharedFpaProxyService] startWithConfig:config];
    [[FpaProxyService sharedFpaProxyService] setupDelegate:(id<FpaProxyServiceDelegate>)self];
    [[FpaProxyService sharedFpaProxyService] setOrUpdateHttpProxyChainConfig:chainInfo];

    [WhiteSocket setProxyConfig:@{
        (id)kCFNetworkProxiesHTTPEnable:@YES,
        (id)kCFNetworkProxiesHTTPProxy:@"127.0.0.1",
        (id)kCFNetworkProxiesHTTPPort:@([[FpaProxyService sharedFpaProxyService] httpProxyPort]),
        @"HTTPSEnable":@YES,
        @"HTTPSProxy":@"127.0.0.1",
        @"HTTPSPort":@([[FpaProxyService sharedFpaProxyService] httpProxyPort]),
    }];
}

#pragma mark - FpaProxyServiceDelegate
- (void)onAccelerationSuccess:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo;
{
    NSLog(@"fpa: %s %@", __func__, connectionInfo);
}

- (void)onConnected:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo;
{
    NSLog(@"fpa: %s %@", __func__, connectionInfo);
}

- (void)onDisconnectedAndFallback:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo reason:(FpaFailedReason)reason;
{
    NSLog(@"fpa: %s %@ fail reason %ld", __func__, connectionInfo, (long)reason);
}

- (void)onConnectionFailed:(FpaProxyServiceConnectionInfo * _Nonnull)connectionInfo reason:(FpaFailedReason)reason;
{
    NSLog(@"fpa: %s %@ fail reason %ld", __func__, connectionInfo, (long)reason);
}

@end
