//
//  WhiteViewController.h
//  WhiteSDK
//
//  Created by leavesster on 08/12/2018.
//  Copyright (c) 2018 leavesster. All rights reserved.
//

@import UIKit;
#import "WhiteBaseViewController.h"
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

typedef void(^RoomBlock)(WhiteRoom * _Nullable room, NSError * _Nullable eroror);
typedef void(^BeginJoinRoomBlock)();


NS_ASSUME_NONNULL_BEGIN
@interface WhiteRoomViewController : WhiteBaseViewController

@property (nonatomic, strong, nullable) WhiteRoom *room;

#pragma mark - CallbackDelegate
@property (nonatomic, weak, nullable) id<WhiteRoomCallbackDelegate> roomCallbackDelegate;

@end


@interface WhiteRoomViewController (UnitTest)

@property (nonatomic, copy, nullable) BeginJoinRoomBlock beginJoinRoomBlock;
@property (nonatomic, copy, nullable) RoomBlock roomBlock;
@property (nonatomic, strong, nullable) WhiteRoomConfig *roomConfig;

@end

NS_ASSUME_NONNULL_END
