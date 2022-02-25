//
//  WhiteFPA.h
//  Whiteboard
//
//  Created by yleaf on 2021/11/2.
//

#import <Foundation/Foundation.h>
#import <AgoraFpaProxyService/FpaProxyService.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface WhiteFPA : NSObject

+ (FpaProxyServiceConfig *)defaultFpaConfig;
+ (FpaHttpProxyChainConfig *)defaultChain;

+ (void)setupFpa:(FpaProxyServiceConfig *)config chain:(FpaHttpProxyChainConfig *)chainInfo;

@end

NS_ASSUME_NONNULL_END
