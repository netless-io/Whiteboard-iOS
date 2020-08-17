//
//  WhiteUtils.m
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/4.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import "WhiteUtils.h"

@implementation WhiteUtils

static NSString *APIHost = @"https://shunt-api.netless.link/v5/";
static NSString *tokenHost = @"https://shunt-api.netless.link/v5/tokens/";

/** FIXME: 此处 tonken 只做 demo 试用。
 实际使用时，请在 https://console.netless.link 注册并获取 sdk token
 该 sdk token 不应该保存在客户端中，所有涉及 sdk token 的请求（当前类中所有请求），都应该放在服务器中进行，以免泄露产生不必要的风险。
 */
#ifndef WhiteSDKToken
#define WhiteSDKToken <#@sdk Token#>
#endif

/** FIXME: 2.8.0 新增必填项 AppIdentitier，通过该 API 可以避免大量预先的网络请求，极大增加异常网络下，用户的连通率。
 请在 https://console.netless.link 中进行获取。
 */
#ifndef WhiteAppIdentifier
#define WhiteAppIdentifier <#@App identifier#>
#endif

+ (NSString *)appIdentifier
{
    return WhiteAppIdentifier;
}

+ (NSString *)sdkToken
{
    return WhiteSDKToken;
}

+ (void)createRoomWithAccessKey:(NSString *)accessKey lifespan:(NSUInteger)lifespan role:(NSString *)role completionHandler:(void (^) (NSString * _Nullable uuid, NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{
    if (!completionHandler) {
        return;
    }
    
//方便在不改动内部代码的情况下，直接进入调试房间
//#if defined(WhiteRoomUUID) && defined(WhiteRoomToken)
//    completionHandler(WhiteRoomUUID, WhiteRoomToken, nil);
//    return;
//#endif
    
    __weak __typeof(self)weakSelf = self;
    [weakSelf createRoomWithResult:^(BOOL success, id  _Nullable response, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (success) {
//            NSString *roomToken = response[@"roomToken"];
            NSString *uuid = response[@"uuid"];
            [strongSelf createRoomTokenWithUuid:uuid accessKey:accessKey lifespan:lifespan role:role Result:^(BOOL success, id response, NSError *error) {
                if (success) {
                    !completionHandler ? : completionHandler(uuid, response, nil);
                } else {
                    !completionHandler ? : completionHandler(nil, nil, error);
                }
            }];
        } else {
            !completionHandler ? : completionHandler(nil, nil, error);
        }
    }];
}

+ (void)getRoomTokenWithUuid:(NSString *)uuid completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{

#if defined(WhiteRoomUUID) && defined(WhiteRoomToken)
    if (([uuid isEqualToString:WhiteRoomUUID] && [WhiteRoomToken length] > 0) || [uuid length] == 0) {
        completionHandler(WhiteRoomToken, nil);
        return;
    }
#endif

    [self getRoomTokenWithUuid:uuid Result:^(BOOL success, id  _Nullable response, NSError * _Nullable error) {
        if (success) {
            NSString *roomToken = response[@"msg"][@"roomToken"];
            !completionHandler ? : completionHandler(roomToken, nil);
        } else {
            !completionHandler ? : completionHandler(nil, error);
        }
    }];
}

+ (void)getRoomInfoWithUuid:(NSString *)uuid completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{

    [self getRoomInfoWithUuid:uuid Result:^(BOOL success, id response, NSError *error) {
        NSString *roomUuid = response[@"response"];
        NSString *name = response[@"name"];
        NSString *teamUUID = response[@"teamUUID"];
        NSNumber *recordNumber = response[@"isRecord"];
        NSNumber *banNumber = response[@"isBan"];
        NSNumber *limitNumber = response[@"limit"];

        BOOL isRecord = [recordNumber boolValue];
        BOOL isBan = [banNumber boolValue];
        int limit = [limitNumber intValue];
        NSLog(@"~~ roomUuid: %@,name: %@, teamUUID: %@, isRecord: %d, isBan: %d, limit: %d", roomUuid, name, teamUUID, isRecord, isBan, limit);
    }];
}

+ (void)getRoomsListWithUuid:(NSString *)uuid limit:(NSUInteger)limit completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{
    
    [self getRoomsListWithUuid:uuid limit:limit Result:^(BOOL success, id response, NSError *error) {
        //FIXME: 返回是单个房间，不是数组
    }];
}

+ (void)banRoomWithUuid:(NSString *)uuid isBan:(BOOL)isBan completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler
{
    [self banRoomWithUuid:uuid isBan:isBan Result:^(BOOL success, id response, NSError *error) {
        
    }];
}

#pragma mark - Private

//FIXME:我们推荐将这两个请求，放在您的服务器端进行。防止您从 https://console.netless.link 获取的 token 发生泄露。
+ (void)createRoomWithResult:(void (^) (BOOL success, id  _Nullable response, NSError * _Nullable error))result;
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[APIHost stringByAppendingPathComponent:@"rooms"]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"POST"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    //在 header 中加入身份鉴权
    [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"token"];
    
    //@"isRecord": @YES 是否开启录制，YES 为可回放房间，默认为持久化房间。
    NSDictionary *params = @{@"name": @"whiteboard-example-ios", @"limit": @110, @"isRecord": @YES};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    
    [modifyRequest setHTTPBody:postData];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!result) {
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 201) {
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

+ (void)createRoomTokenWithUuid:(NSString *)uuid accessKey:(NSString *)accessKey lifespan:(NSUInteger)lifespan role:(NSString *)role Result:(void (^) (BOOL success, id response, NSError *error))result
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[tokenHost stringByAppendingPathComponent:@"rooms/%@"], uuid]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    
    [modifyRequest setHTTPMethod:@"POST"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"token"];
    
    NSDictionary *params = @{@"lifespan": @(lifespan), @"role": role};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    
    [modifyRequest setHTTPBody:postData];

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!result) {
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 201) {
                NSMutableDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
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

+ (void)getRoomInfoWithUuid:(NSString *)uuid Result:(void (^) (BOOL success, id response, NSError *error))result
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[APIHost stringByAppendingPathComponent:@"rooms/%@"], uuid]]];

    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    
    [modifyRequest setHTTPMethod:@"GET"];
    
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

+ (void)getRoomsListWithUuid:(NSString *)uuid limit:(NSUInteger)limit Result:(void (^) (BOOL success, id response, NSError *error))result
{
    //FIXME: 参数调整
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[APIHost stringByAppendingPathComponent:@"rooms"]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    
    [modifyRequest setHTTPMethod:@"POST"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"token"];
    
    
    if (limit) {
        [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"limit"];
    }
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!result) {
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 201) {
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

+ (void)banRoomWithUuid:(NSString *)uuid isBan:(BOOL)isBan Result:(void (^) (BOOL success, id response, NSError *error))result
{
    //FIXME: 参数调整
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[APIHost stringByAppendingPathComponent:@"rooms/:uuid=%@"], uuid, isBan]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    
    [modifyRequest setHTTPMethod:@"PATCH"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:self.sdkToken forHTTPHeaderField:@"token"];
    
    NSDictionary *params = @{@"isBan": @(isBan)};
     NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
     
     [modifyRequest setHTTPBody:postData];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!result) {
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 201) {
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

@end
