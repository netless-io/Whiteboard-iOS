//
//  WhiteBoardView+Private.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteBoardView.h"

@class WhiteRoomCallbacks, WhitePlayerEvent, WhiteCommonCallbacks, WhiteSdkConfiguration, WhiteSDK;

@interface WhiteBoardView ()
- (BOOL)whiteClaimSdk;
- (void)whiteReplaceRoom:(NSString *)identity configuration:(NSDictionary *)configuration timeout:(NSTimeInterval)timeout bind:(void (^)(void))bind start:(void (^)(NSNumber *generation))start failure:(void (^)(NSError *error))failure;
- (BOOL)whiteCanConfigureCallbacks;
@property (nonatomic, weak, nullable) WhiteSDK *whiteCallbackOwner;
- (nullable NSNumber *)whiteBeginWithCancellation:(void (^)(NSError *error))cancel;
- (BOOL)whiteContinueJoin:(NSNumber *)generation cancellation:(void (^)(NSError *error))cancel;
- (BOOL)whiteComplete:(NSNumber *)generation success:(BOOL)success;
- (WhiteBoardView *)whiteScopedBridge:(NSNumber *)generation;
- (void)whiteLeaveRoom:(void (^ _Nullable)(NSError * _Nullable))completion;
- (void)whiteLeave:(nullable NSNumber *)generation completion:(void (^_Nullable)(NSError * _Nullable error))completion;
- (void)whiteInvalidate;
- (BOOL)whiteCurrent:(NSNumber *)generation;


@property (nonatomic, strong, nullable) WhiteRoomCallbacks *roomCallbacks;
@property (nonatomic, strong, nullable) WhitePlayerEvent *playerEvent;
@property (nonatomic, strong, nullable) WhiteCommonCallbacks *commonCallbacks;

- (void)setupWebSDKWithConfig:(WhiteSdkConfiguration *_Nonnull)config completion:(void (^_Nullable) (id _Nullable value))completionHandler;

// Renderer exit invalidates this host. This entry no longer replays a pending/active join.
- (void)reloadFromCrash:(void (^__nullable)(void))completionHandler;

- (void)observeWKWebViewConsole;
- (void)setDebugViewStateLoggingEnabled:(BOOL)enabled;
- (void)logDebugViewStateWithReason:(NSString *)reason force:(BOOL)force;

@end
