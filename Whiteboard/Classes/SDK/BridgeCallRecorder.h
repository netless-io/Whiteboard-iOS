//
//  BridgeCallRecorder.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/21.
//

#import <Foundation/Foundation.h>
#import "WhiteCallBridgeCommand.h"
#import "WhiteBoardView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeCallRecorder : NSObject

/// Values是重放时是否 await
- (instancetype)initWithRecordKeys:(NSDictionary<NSString *, NSNumber *>*)recordingKeys;

- (void)receiveCommand:(WhiteCallBridgeCommand *)command;

- (void)resumeCommandsFromBridgeView:(WhiteBoardView *)view completionHandler:(void (^__nullable)(void))completionHandler;
@end

NS_ASSUME_NONNULL_END
