//
//  WhiteSocket.m
//  Whiteboard
//
//  Created by yleaf on 2021/11/1.
//

#import "WhiteSocket.h"

@interface WhiteSocket()<NSURLSessionWebSocketDelegate>

@property (nonatomic, weak, readonly) WhiteBoardView *bridge;
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocket;
@property (nonatomic, strong) NSURLSession *session;
/// 手动记录socket的开关状态，因为前后台切换的时候，不能保证所有回调都被正确调用
@property (nonatomic, copy) NSMutableDictionary *socketClosedDic;

@end

@implementation WhiteSocket

static NSDictionary *_proxyConfig = nil;
+ (NSDictionary *)proxyConfig {
    return _proxyConfig;
}

+ (void)setProxyConfig:(NSDictionary *)proxyConfig
{
    _proxyConfig = proxyConfig;
}

#pragma mark - Instance Class

- (void)dealloc {
    NSLog(@"white socket dealloc");
}

- (instancetype)initWithBridge:(WhiteBoardView *)bridge {
    self = [super init];
    _bridge = bridge;
    return self;
}

- (NSMutableDictionary *)socketClosedDic {
    if (!_socketClosedDic) {
        _socketClosedDic = [NSMutableDictionary dictionary];
    }
    return _socketClosedDic;
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.connectionProxyDictionary = [WhiteSocket proxyConfig];
        // delegate 会被强制引用 WhiteSocket 实例，需要手动 invalidateAndCancel
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

#pragma mark - private

- (BOOL)isCurrentSocket:(NSDictionary *)payload {
    return [self.webSocket.taskDescription isEqual:[payload[kPayloadKey] description]];
}

- (void)releaseSocket {
    [self releaseSocketIfNeeded];
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)releaseSocketIfNeeded {
    if (self.webSocket) {
        NSURLSessionWebSocketTask *webSocket = self.webSocket;
        self.webSocket = nil;
        [webSocket cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    }
}

#pragma mark - Const

static NSString * const kPayloadKey = @"key";
static NSString * const kPayloadData = @"data";
static NSString * const kPayloadType = @"type";

typedef NSString * WhiteSocketPayloadType NS_STRING_ENUM;
WhiteSocketPayloadType const PayloadArrayBuffer = @"arraybuffer";
WhiteSocketPayloadType const PayloadTypeString = @"string";

#pragma mark - ws DSBridge

- (NSString *)setup:(NSDictionary *)payload
{
    [self setupWebSocket:payload];
    return @"";
}

- (NSString *)send:(NSDictionary *)payload {
    if (![self isCurrentSocket:payload]) {
        return @"";
    }
    NSString *dataString = payload[kPayloadData];
    NSURLSessionWebSocketMessage *message;
    if ([payload[kPayloadType] isEqualToString:PayloadArrayBuffer]) {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        message = [[NSURLSessionWebSocketMessage alloc] initWithData:data];
    } else if ([payload[kPayloadType] isEqualToString:PayloadTypeString]) {
        message = [[NSURLSessionWebSocketMessage alloc] initWithString:dataString];
    }
    if (message) {
        [self.webSocket sendMessage:message completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"webSocket send message error: %@", error);
            }
        }];
    }
    return @"";
}

- (NSString *)close:(NSDictionary *)payload {
    if ([self isCurrentSocket:payload]) {
        return @"";
    }
    
    [self.webSocket cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    return @"";
}

#pragma mark - WebSocket

- (void)setupWebSocket:(NSDictionary *)dict {
    [self releaseSocketIfNeeded];
    
    NSString *key = [dict[kPayloadKey] description];
    NSNumber *numberKey = @([key intValue]);
    NSURL *url = [NSURL URLWithString:dict[@"url"]];
    self.webSocket = [self.session webSocketTaskWithURL:url];
    self.webSocket.taskDescription = key;
    [self.webSocket resume];
    self.socketClosedDic[key] = @(FALSE);

    __weak typeof(self)weakSelf = self;
    [self receiveSocket:self.webSocket messageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        if (error) {
            [weakSelf.bridge callHandler:@"ws.onError" arguments:@[@{kPayloadKey: numberKey}]];
        } else if (message.type == NSURLSessionWebSocketMessageTypeString) {
            [weakSelf.bridge callHandler:@"ws.onMessage" arguments:@[@{kPayloadKey: numberKey, kPayloadData: message.string, kPayloadType: PayloadTypeString}]];
        } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
            [weakSelf.bridge callHandler:@"ws.onMessage" arguments:@[@{kPayloadKey: numberKey, kPayloadData: [message.data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength], kPayloadType: PayloadArrayBuffer}]];
        }
    }];
}

- (void)receiveSocket:(NSURLSessionWebSocketTask *)task messageWithCompletionHandler:(void (^)(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error))completionHandler {
    __weak typeof(self)weakSelf = self;
    [task receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        // 出现已关闭的socket，但是又没有被记录过关闭
        // 说明是在后台关闭的
        // 这时候需要主动通知调起关闭通知
        if (task.state == NSURLSessionTaskStateCompleted
            && ![weakSelf.socketClosedDic[task.taskDescription] boolValue]) {
            [weakSelf processBackgroundClosedSocket:task];
        } else if (task.state == NSURLSessionTaskStateRunning) {
            if (completionHandler) {
                completionHandler(message, error);
            }
            [weakSelf receiveSocket:task messageWithCompletionHandler:completionHandler];
        }
    }];
}

// 处理在后台被关闭的Socket
- (void)processBackgroundClosedSocket:(NSURLSessionWebSocketTask *)socket {
    self.socketClosedDic[socket.taskDescription] = @(TRUE);
    NSDictionary *payload = @{@"code": @(-9999),
                              @"reason": @"backgroundKilledWebSocket",
                              kPayloadKey: @([socket.taskDescription intValue]),
                              @"wasClean": @(YES)};
    [self.bridge callHandler:@"ws.onClose" arguments:@[payload]];
}

#pragma mark - NSURLSessionWebSocketDelegate


/* Indicates that the WebSocket handshake was successful and the connection has been upgraded to webSockets.
 * It will also provide the protocol that is picked in the handshake. If the handshake fails, this delegate will not be invoked.
 */
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(nullable NSString *) protocol;
{
    if (self.webSocket == webSocketTask) {
        [self.bridge callHandler:@"ws.onOpen" arguments:@[@{kPayloadKey: @([webSocketTask.taskDescription intValue])}]];
    }
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(nullable NSData *)reason;
{
    self.socketClosedDic[webSocketTask.taskDescription] = @(YES);
    if (self.webSocket == webSocketTask) {
        NSString *r = reason ? @"" : [[NSString alloc] initWithData:reason encoding:NSUTF8StringEncoding];
        NSDictionary *payload = @{@"code": @(closeCode), @"reason": r, kPayloadKey: @([webSocketTask.taskDescription intValue]), @"wasClean": @(YES)};
        [self.bridge callHandler:@"ws.onClose" arguments:@[payload]];
    }
}

@end
