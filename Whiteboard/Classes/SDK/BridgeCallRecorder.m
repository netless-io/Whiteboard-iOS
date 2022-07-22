//
//  BridgeCallRecorder.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/21.
//

#import "BridgeCallRecorder.h"

@interface BridgeCallRecorder ()

@property (nonatomic, strong) NSMutableArray<WhiteCallBridgeCommand *>* recordedCommands;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *>*recordingKeys;
@end

@implementation BridgeCallRecorder {
    NSArray *_lockedArray;
    NSInteger _leftLockedArrayResumeCount;
}

- (instancetype)initWithRecordingKeys:(NSDictionary<NSString *, NSNumber *>*)recordingKeys {
    if (self = [super init]) {
        self.recordingKeys = recordingKeys;
        self.recordedCommands = [NSMutableArray array];
    }
    return self;
}

- (void)receiveCommand:(WhiteCallBridgeCommand *)command {
    NSNumber *awaitObject = self.recordingKeys[command.method];
    if (awaitObject) {
        command.await = [awaitObject boolValue];
        [self.recordedCommands addObject:command];
        return;
    }
}

- (void)resumeCommandsFromBridgeView:(WhiteBoardView *)view completionHandler:(void (^__nullable)(void))completionHandler {
    _lockedArray = [self.recordedCommands copy];
    _leftLockedArrayResumeCount = [_lockedArray count];
    
    self.recordedCommands = [NSMutableArray array];
    [self loopLockedCommandsFromBridgeView:view completionHandler:completionHandler];
}

- (void)loopLockedCommandsFromBridgeView:(WhiteBoardView *)view completionHandler:(void (^__nullable)(void))completionHandler {
    if (_leftLockedArrayResumeCount > 0) {
        NSInteger index = _lockedArray.count - _leftLockedArrayResumeCount;
        WhiteCallBridgeCommand *command = _lockedArray[index];
        __weak typeof(self) weakSelf = self;
        __weak typeof(view) weakWebView = view;
        [self resumeCommandFromBridgeView:view command:command completionHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf->_leftLockedArrayResumeCount -= 1;
            [strongSelf loopLockedCommandsFromBridgeView:weakWebView completionHandler:completionHandler];
        }];
    } else {
        completionHandler();
    }
}

- (void)resumeCommandFromBridgeView:(WhiteBoardView *)view command:(WhiteCallBridgeCommand *)command completionHandler:(void (^__nullable)(void))completionHandler {
    // TBD:
    // 缺失一个错误判断。
    if (command.await) {
        [view callHandler:command.method arguments:command.args completionHandler:^(id  _Nullable value) {
            completionHandler();
        }];
    } else {
        [view callHandler:command.method arguments:command.args];
        completionHandler();
    }
}

@end
