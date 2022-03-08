//
//  WhiteTestSocket.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/7.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import "WhiteTestSocket.h"

@interface WhiteSocket ()

- (void)setupWebSocket:(NSDictionary *)dict;

- (void)receiveSocket:(NSURLSessionWebSocketTask *)task messageWithCompletionHandler:(void (^)(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error))completionHandler;

- (void)reportToJsWebSocketClose:(NSURLSessionWebSocketTask *)webSocket reason:(NSString *)reason closeCode:(NSInteger)closeCode;

@end

@implementation WhiteTestSocket

- (instancetype)initWithBridge:(WhiteBoardView *)bridge {
    if (self = [super initWithBridge:bridge]) {
        _testAbandonMessageDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setupWebSocket:(NSDictionary *)dict
{
    [super setupWebSocket:dict];
    NSLog(@"ws: setup, dic %@", dict[@"key"]);
}

- (void)reportToJsWebSocketClose:(NSURLSessionWebSocketTask *)webSocket reason:(NSString *)reason closeCode:(NSInteger)closeCode {
    [super reportToJsWebSocketClose:webSocket reason:reason closeCode:closeCode];
    NSLog(@"ws: close, reason %@, key %@", reason, webSocket.taskDescription);
}

- (void)receiveSocket:(NSURLSessionWebSocketTask *)task messageWithCompletionHandler:(void (^)(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error))completionHandler {
    NSString *key = task.taskDescription;
    if (_testAbandonMessageDic[key]) {
        return;
    }
    [super receiveSocket:task messageWithCompletionHandler:completionHandler];
}

@end
