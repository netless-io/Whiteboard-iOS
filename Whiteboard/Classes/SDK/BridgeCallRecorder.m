//
//  BridgeCallRecorder.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/21.
//

#import "BridgeCallRecorder.h"

@interface BridgeCallRecorder ()

@property (nonatomic, strong) NSMutableArray<WhiteCallBridgeCommand *>* recordCommands;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *>*recordKeys;
@property (nonatomic, copy) NSArray* lockedArray;
@property (nonatomic, assign) NSInteger leftLockedArrayResumeCount;

@end

@implementation BridgeCallRecorder

- (instancetype)initWithRecordKeys:(NSDictionary<NSString *, NSNumber *>*)recordingKeys {
    if (self = [super init]) {
        self.recordKeys = recordingKeys;
        self.recordCommands = [NSMutableArray array];
    }
    return self;
}

- (void)receiveCommand:(WhiteCallBridgeCommand *)command {
    NSNumber *existObject = self.recordKeys[command.method];
    if (existObject) {
        command.await = [existObject boolValue];
        [self.recordCommands addObject:command];
        return;
    }
}

- (void)resumeCommandsFromBridgeView:(WhiteBoardView *)view completionHandler:(void (^__nullable)(void))completionHandler {
    self.lockedArray = [self.recordCommands copy];
    self.leftLockedArrayResumeCount = [self.lockedArray count];
    
    self.recordCommands = [NSMutableArray array];
    [self loopLockedCommandsFromBridgeView:view completionHandler:completionHandler];
}

- (void)loopLockedCommandsFromBridgeView:(WhiteBoardView *)view completionHandler:(void (^__nullable)(void))completionHandler {
    if (self.leftLockedArrayResumeCount > 0) {
        NSInteger index = self.lockedArray.count - self.leftLockedArrayResumeCount;
        WhiteCallBridgeCommand *command = self.lockedArray[index];
        __weak typeof(self) weakSelf = self;
        __weak typeof(view) weakWebView = view;
        [self resumeCommandFromBridgeView:view command:command completionHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.leftLockedArrayResumeCount -= 1;
            [strongSelf loopLockedCommandsFromBridgeView:weakWebView completionHandler:completionHandler];
        }];
    } else {
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)resumeCommandFromBridgeView:(WhiteBoardView *)view command:(WhiteCallBridgeCommand *)command completionHandler:(void (^__nullable)(void))completionHandler {
    // TBD:
    // 缺失一个错误判断。
    if (command.await) {
        [view callHandler:command.method arguments:command.args completionHandler:^(id  _Nullable value) {
            if (completionHandler) {
                completionHandler();
            }
        }];
    } else {
        [view callHandler:command.method arguments:command.args];
        if (completionHandler) {
            completionHandler();
        }
    }
}

@end
