//
//  ApplePencilDrawTest.m
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2024/4/29.
//  Copyright © 2024 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseRoomTest.h"
#import "Whiteboard.h"

@interface ApplePencilDrawTest : BaseRoomTest
@end

@implementation ApplePencilDrawTest

- (void)testMatchInteractionView {
    XCTAssertEqual([[UIDevice currentDevice] userInterfaceIdiom], UIUserInterfaceIdiomPad);
    NSObject *handler = [self.room valueForKey:@"applePencilDrawHandler"];
    NSObject *o1 = [handler valueForKey:@"originalGesture"];
    NSObject *o2 = [handler valueForKey:@"originalDelegate"];
    XCTAssertNotNil(o1);
    XCTAssertNotNil(o2);
}

- (void)roomConfigDidSetup:(WhiteRoomConfig *)config {
    [super roomConfigDidSetup:config];
    config.drawOnlyApplePencil = YES;
}

@end
