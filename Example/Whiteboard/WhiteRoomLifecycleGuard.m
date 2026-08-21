//
//  WhiteRoomLifecycleGuard.m
//  Whiteboard_Example
//

#import "WhiteRoomLifecycleGuard.h"
#import <math.h>

@interface WhiteRoomLifecycleGuard ()

@property (nonatomic, assign, readwrite, getter=isActive) BOOL active;
@property (nonatomic, assign, readwrite, getter=isRecovering) BOOL recovering;
@property (nonatomic, assign, readwrite, getter=isLoadingVisible) BOOL loadingVisible;
@property (nonatomic, assign) NSUInteger retryAttempt;
@property (nonatomic, assign) NSUInteger scheduleGeneration;

@end

@implementation WhiteRoomLifecycleGuard

- (instancetype)init
{
    self = [super init];
    if (self) {
        _initialRetryDelay = 1;
        _maximumRetryDelay = 8;
        _scheduler = ^(NSTimeInterval delay, dispatch_block_t block) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
        };
    }
    return self;
}

- (void)start
{
    self.scheduleGeneration += 1;
    self.active = YES;
    self.recovering = NO;
    self.retryAttempt = 0;
    [self updateLoadingVisible:NO];
}

- (void)stop
{
    self.scheduleGeneration += 1;
    self.active = NO;
    self.recovering = NO;
    self.retryAttempt = 0;
    [self updateLoadingVisible:NO];
}

- (void)handlePhase:(WhiteRoomPhase)phase
{
    if (!self.isActive) {
        return;
    }

    switch (phase) {
        case WhiteRoomPhaseConnected:
            [self rejoinDidSucceed];
            break;
        case WhiteRoomPhaseReconnecting:
            [self updateLoadingVisible:YES];
            break;
        case WhiteRoomPhaseDisconnecting:
        case WhiteRoomPhaseDisconnected:
            [self updateLoadingVisible:YES];
            [self requestReconnectIfNeeded];
            break;
        case WhiteRoomPhaseConnecting:
            [self updateLoadingVisible:YES];
            break;
    }
}

- (void)rejoinDidSucceed
{
    if (!self.isActive) {
        return;
    }
    self.scheduleGeneration += 1;
    self.recovering = NO;
    self.retryAttempt = 0;
    [self updateLoadingVisible:NO];
}

- (void)rejoinDidFail
{
    if (!self.isActive) {
        return;
    }

    self.recovering = NO;
    [self updateLoadingVisible:YES];

    NSTimeInterval multiplier = pow(2, MIN(self.retryAttempt, (NSUInteger)16));
    NSTimeInterval delay = MIN(self.maximumRetryDelay, self.initialRetryDelay * multiplier);
    self.retryAttempt += 1;
    NSUInteger generation = ++self.scheduleGeneration;
    __weak typeof(self) weakSelf = self;
    self.scheduler(delay, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.isActive || generation != self.scheduleGeneration) {
            return;
        }
        [self requestReconnectIfNeeded];
    });
}

- (void)requestReconnectIfNeeded
{
    if (!self.isActive || self.isRecovering) {
        return;
    }
    self.recovering = YES;
    if (self.reconnectHandler) {
        self.reconnectHandler();
    }
}

- (void)updateLoadingVisible:(BOOL)visible
{
    if (self.loadingVisible == visible) {
        return;
    }
    self.loadingVisible = visible;
    if (self.loadingHandler) {
        self.loadingHandler(visible);
    }
}

@end
