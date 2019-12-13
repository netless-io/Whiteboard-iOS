//
//  WhiteCommandTableViewController.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2018/12/24.
//  Copyright © 2018 leavesster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Whiteboard/Whiteboard.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *WhiteCommandCustomEvent = @"WhiteCommandCustomEvent";

@interface RoomCommandListController : UITableViewController

@property (nonatomic, copy, nullable) NSString *roomToken;

- (instancetype)initWithRoom:(WhiteRoom *)room;


@end

NS_ASSUME_NONNULL_END
