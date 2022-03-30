//
//  TestUtility.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/30.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "TestUtility.h"
#import "Tests-Prefix.pch"

@implementation TestUtility

+ (void)updateRoomWithUuid:(NSString *)uuid ban:(BOOL)ban completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    NSString *questUrl = [NSString stringWithFormat:@"https://api.netless.link/v5/rooms/%@", uuid];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:questUrl]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"cn-hz" forHTTPHeaderField:@"region"];
    [request addValue:WhiteRoomToken forHTTPHeaderField:@"token"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"isBan": [NSNumber numberWithBool:ban]} options:0 error:nil];
    request.HTTPBody = data;
    request.HTTPMethod = @"PATCH";

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(error);
            });
            return;
        }
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *uuid = responseObject[@"uuid"];
        if (uuid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler([NSError new]);
            });
        }
    }];
    [task resume];
}

@end
