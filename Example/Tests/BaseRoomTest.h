//
//  BaseRoomTest.h
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/30.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "WhiteRoomViewController.h"
#import "TestUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteBoardView ()
@property (nonatomic, strong, nullable) WhiteCommonCallbacks *commonCallbacks;
@end

@interface WhiteSDK ()
@property (nonatomic, weak) WhiteBoardView *bridge;
@end

/// 房间测试的基类，提供一些测试的便捷方法
@interface BaseRoomTest : XCTestCase<WhiteRoomCallbackDelegate, WhiteCommonCallbackDelegate>

@property (nonatomic, strong) WhiteRoomViewController *roomVC;
@property (nonatomic, strong) WhiteRoom *room;
@property (nonatomic, strong) WhiteRoomConfig *roomConfig;
/// 需要加入房间失败的时候设置 YES，测试结束后会自己设置 NO
@property (nonatomic, assign) BOOL assertJoinRoomError;

- (void)sdkConfigDidSetup:(WhiteSdkConfiguration *)sdkConfig;
- (void)roomConfigDidSetup:(WhiteRoomConfig *)config;
- (void)roomVCDidSetup:(WhiteRoomViewController *)roomVC;
- (void)pushRoomVC;
- (void)popToRoot;

@end

NS_ASSUME_NONNULL_END
