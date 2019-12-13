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

+ (NSString *)sdkToken
{
    /* FIXME: 此处 tonken 只做 demo 试用。
     实际使用时，请从 https://console.herewhite.com 重新注册申请。
     该 sdk token 不应该保存在客户端中，所有涉及 sdk token 的请求（当前类中所有请求），都应该放在服务器中。
     */
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"white-sdk-token"];
}

//FIXME:我们推荐将这两个请求，放在您的服务器端进行。防止您从 https://console.herewhite.com 获取的 token 发生泄露。
+ (void)createRoomWithResult:(void (^) (BOOL success, id  _Nullable response, NSError * _Nullable error))result;
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[APIHost stringByAppendingPathComponent:@"room?token=%@"], self.sdkToken]]];
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"POST"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    //@"mode": @"historied" 为可回放房间，默认为持久化房间。
    NSDictionary *params = @{@"name": @"test", @"limit": @110, @"mode": @"historied"};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    [modifyRequest setHTTPBody:postData];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error && result) {
                result(NO, nil, error);
            } else if (result) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                result(YES, responseObject, nil);
            }
        });
    }];
    [task resume];
}

+ (void)createRoomWithCompletionHandler:(void (^) (NSString * _Nullable uuid, NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{
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
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[APIHost stringByAppendingPathComponent:@"/room/join?uuid=%@&token=%@"], uuid, self.sdkToken]]];
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"POST"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error && result) {
                result(NO, nil, error);
            } else if (result) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([responseObject[@"code"] integerValue]  == 200) {
                    result(YES, responseObject, nil);
                } else {
                    result(NO, responseObject, nil);
                }
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
