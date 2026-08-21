//
//  RoomLifecycleGuardTests.m
//  Whiteboard_Tests
//

#import <XCTest/XCTest.h>
#import "WhiteRoomLifecycleGuard.h"
#import "WhiteRoomViewController.h"

@interface RoomLifecycleGuardTests : XCTestCase
@end

@implementation RoomLifecycleGuardTests

- (WhiteRoomLifecycleGuard *)startedGuard
{
    WhiteRoomLifecycleGuard *guard = [[WhiteRoomLifecycleGuard alloc] init];
    [guard start];
    return guard;
}

- (void)testReconnectingShowsLoadingAndConnectedHidesIt
{
    WhiteRoomLifecycleGuard *guard = [self startedGuard];
    NSMutableArray<NSNumber *> *changes = [NSMutableArray array];
    guard.loadingHandler = ^(BOOL visible) {
        [changes addObject:@(visible)];
    };

    [guard handlePhase:WhiteRoomPhaseReconnecting];
    XCTAssertTrue(guard.isLoadingVisible);
    [guard handlePhase:WhiteRoomPhaseConnected];
    XCTAssertFalse(guard.isLoadingVisible);
    XCTAssertEqualObjects(changes, (@[@YES, @NO]));
}

- (void)testConnectingShowsLoading
{
    WhiteRoomLifecycleGuard *guard = [self startedGuard];

    [guard handlePhase:WhiteRoomPhaseConnecting];

    XCTAssertTrue(guard.isLoadingVisible);
}

- (void)testDisconnectingAndDisconnectedRequestOnlyOneReplacement
{
    WhiteRoomLifecycleGuard *guard = [self startedGuard];
    __block NSUInteger reconnectCount = 0;
    guard.reconnectHandler = ^{
        reconnectCount += 1;
    };

    [guard handlePhase:WhiteRoomPhaseDisconnecting];
    [guard handlePhase:WhiteRoomPhaseDisconnected];

    XCTAssertTrue(guard.isRecovering);
    XCTAssertTrue(guard.isLoadingVisible);
    XCTAssertEqual(reconnectCount, (NSUInteger)1);
}

- (void)testFailedReplacementKeepsRetryingWithBackoff
{
    WhiteRoomLifecycleGuard *guard = [self startedGuard];
    guard.initialRetryDelay = 1;
    guard.maximumRetryDelay = 2;
    __block NSUInteger reconnectCount = 0;
    __block dispatch_block_t scheduledRetry = nil;
    NSMutableArray<NSNumber *> *delays = [NSMutableArray array];
    guard.reconnectHandler = ^{
        reconnectCount += 1;
    };
    guard.scheduler = ^(NSTimeInterval delay, dispatch_block_t block) {
        [delays addObject:@(delay)];
        scheduledRetry = block;
    };

    [guard handlePhase:WhiteRoomPhaseDisconnected];
    XCTAssertEqual(reconnectCount, (NSUInteger)1);

    [guard rejoinDidFail];
    XCTAssertNotNil(scheduledRetry);
    scheduledRetry();
    XCTAssertEqual(reconnectCount, (NSUInteger)2);

    [guard rejoinDidFail];
    scheduledRetry();
    XCTAssertEqual(reconnectCount, (NSUInteger)3);

    [guard rejoinDidFail];
    XCTAssertEqualObjects(delays, (@[@1, @2, @2]));
}

- (void)testStopCancelsScheduledRetryAndHidesLoading
{
    WhiteRoomLifecycleGuard *guard = [self startedGuard];
    __block NSUInteger reconnectCount = 0;
    __block dispatch_block_t scheduledRetry = nil;
    guard.reconnectHandler = ^{
        reconnectCount += 1;
    };
    guard.scheduler = ^(NSTimeInterval delay, dispatch_block_t block) {
        scheduledRetry = block;
    };

    [guard handlePhase:WhiteRoomPhaseDisconnected];
    [guard rejoinDidFail];
    [guard stop];
    scheduledRetry();

    XCTAssertFalse(guard.isActive);
    XCTAssertFalse(guard.isLoadingVisible);
    XCTAssertEqual(reconnectCount, (NSUInteger)1);
}

- (void)testViewControllerLoadingOverlayFollowsRoomPhase
{
    WhiteRoomViewController *viewController = [[WhiteRoomViewController alloc] init];
    viewController.delayJoinRoom = YES;
    __unused UIView *view = viewController.view;

    [viewController firePhaseChanged:WhiteRoomPhaseReconnecting];
    XCTAssertTrue(viewController.isRoomLoadingVisible);
    [viewController firePhaseChanged:WhiteRoomPhaseConnected];
    XCTAssertFalse(viewController.isRoomLoadingVisible);
}

@end
