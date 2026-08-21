//
//  WhiteRoomLifecycleGuard.h
//  Whiteboard_Example
//

#import <Foundation/Foundation.h>

#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^WhiteRoomGuardLoadingHandler)(BOOL visible);
typedef void (^WhiteRoomGuardReconnectHandler)(void);
typedef void (^WhiteRoomGuardScheduler)(NSTimeInterval delay, dispatch_block_t block);

@interface WhiteRoomLifecycleGuard : NSObject

@property (nonatomic, copy, nullable) WhiteRoomGuardLoadingHandler loadingHandler;
@property (nonatomic, copy, nullable) WhiteRoomGuardReconnectHandler reconnectHandler;
@property (nonatomic, copy) WhiteRoomGuardScheduler scheduler;
@property (nonatomic, assign) NSTimeInterval initialRetryDelay;
@property (nonatomic, assign) NSTimeInterval maximumRetryDelay;
@property (nonatomic, assign, readonly, getter=isActive) BOOL active;
@property (nonatomic, assign, readonly, getter=isRecovering) BOOL recovering;
@property (nonatomic, assign, readonly, getter=isLoadingVisible) BOOL loadingVisible;

- (void)start;
- (void)stop;
- (void)handlePhase:(WhiteRoomPhase)phase;
- (void)rejoinDidSucceed;
- (void)rejoinDidFail;

@end

NS_ASSUME_NONNULL_END
