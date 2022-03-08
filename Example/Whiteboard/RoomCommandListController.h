//
//  WhiteCommandTableViewController.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2018/12/24.
//  Copyright © 2018 leavesster. All rights reserved.
//

#import <UIKit/UIKit.h>
#if IS_SPM
#import "Whiteboard.h"
#else
#import <Whiteboard/Whiteboard.h>
#endif

NS_ASSUME_NONNULL_BEGIN

static NSString *WhiteCommandCustomEvent = @"WhiteCommandCustomEvent";

@interface RoomCommandListController : UITableViewController

@property (nonatomic, copy, nullable) NSString *roomToken;

- (instancetype)initWithRoom:(WhiteRoom *)room;


@end

NS_ASSUME_NONNULL_END
