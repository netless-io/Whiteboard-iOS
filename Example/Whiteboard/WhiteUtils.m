//
//  WhiteUtils.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/4.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import "WhiteUtils.h"

@implementation WhiteUtils

static NSString *APIHost = @"https://cloudcapiv4.herewhite.com";

/* FIXME: 此处 tonken 只做 demo 试用。
 实际使用时，请在 https://console.herewhite.com 注册并获取 sdk token
 该 sdk token 不应该保存在客户端中，所有涉及 sdk token 的请求（当前类中所有请求），都应该放在服务器中进行，以免泄露产生不必要的风险。
 */
#ifndef kWhiteSDKToken
#define kWhiteSDKToken <#@sdk Token#>
#endif

+ (NSString *)sdkToken
{

    return kWhiteSDKToken;
}

//FIXME:我们推荐将这两个请求，放在您的服务器端进行。防止您从 https://console.herewhite.com 获取的 token 发生泄露。
+ (void)createRoomWithResult:(void (^) (BOOL success, id  _Nullable response, NSError * _Nullable error))result;
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[APIHost stringByAppendingPathComponent:@"room"]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"POST"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    //在 header 中加入身份鉴权
    [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"token"];
    
    //@"mode": @"historied" 为可回放房间，默认为持久化房间。
    NSDictionary *params = @{@"name": @"whiteboard-example-ios", @"limit": @110, @"mode": @"historied"};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    
    [modifyRequest setHTTPBody:postData];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!result) {
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                result(YES, responseObject, nil);
            } else if (error) {
                result(NO, nil, error);
            } else if (data) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:401 userInfo:responseObject];
                result(NO, nil, error);
            }
        });
    }];
    [task resume];
}

+ (void)createRoomWithCompletionHandler:(void (^) (NSString * _Nullable uuid, NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{
    if (!completionHandler) {
        return;
    }
    
    //方便在不改动内部代码的情况下，直接进入调试房间
#if defined(WhiteRoomUUID) && defined(WhiteRoomToken)
    completionHandler(WhiteRoomUUID, WhiteRoomToken, nil);
    return;
#endif
    
    
    [self createRoomWithResult:^(BOOL success, id  _Nullable response, NSError * _Nullable error) {
        if (success) {
            NSString *roomToken = response[@"msg"][@"roomToken"];
            NSString *uuid = response[@"msg"][@"room"][@"uuid"];
            !completionHandler ? : completionHandler(uuid, roomToken, nil);
        } else {
            !completionHandler ? : completionHandler(nil, nil, error);
        }
    }];
}

/**
 向服务器获取对应 room uuid 所需要的房间 roomToken
 
 @param uuid 房间 uuid
 @param result 服务器返回信息
 */
+ (void)getRoomTokenWithUuid:(NSString *)uuid Result:(void (^) (BOOL success, id response, NSError *error))result
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[APIHost stringByAppendingPathComponent:@"/room/join?uuid=%@"], uuid]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    
    [modifyRequest setHTTPMethod:@"POST"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"token"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!result) {
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                result(YES, responseObject, nil);
            } else if (error) {
                result(NO, nil, error);
            } else if (data) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:401 userInfo:responseObject];
                result(NO, nil, error);
            }
        });
    }];
    [task resume];
}

+ (void)getRoomTokenWithUuid:(NSString *)uuid completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{
    [self getRoomTokenWithUuid:uuid Result:^(BOOL success, id  _Nullable response, NSError * _Nullable error) {
        if (success) {
            NSString *roomToken = response[@"msg"][@"roomToken"];
            !completionHandler ? : completionHandler(roomToken, nil);
        } else {
            !completionHandler ? : completionHandler(nil, error);
        }
    }];
}

@end
