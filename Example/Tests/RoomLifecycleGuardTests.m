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

- (void)testTerminalAndFailedJoinDoNotScheduleReplacement
{
    WhiteRoomLifecycleGuard *guard = [self startedGuard];
    __block NSUInteger reconnectCount = 0;
    guard.reconnectHandler = ^{ reconnectCount++; };
    guard.scheduler = ^(NSTimeInterval delay, dispatch_block_t block) { XCTFail(@"Unknown exit must not schedule another join"); };
    [guard handlePhase:WhiteRoomPhaseDisconnecting];
    [guard handlePhase:WhiteRoomPhaseDisconnected];
    [guard rejoinDidFail];
    XCTAssertTrue(guard.isLoadingVisible);
    XCTAssertEqual(reconnectCount, (NSUInteger)0);
    [guard stop];
    XCTAssertFalse(guard.isLoadingVisible);
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
