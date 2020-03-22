//
//  PlayerCommandListController.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/15.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Whiteboard/Whiteboard.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerCommandListController : UITableViewController

- (instancetype)initWithPlayer:(WhiteCombinePlayer *)player;
- (instancetype)initWithWhitePlayer:(WhitePlayer *)whitePlayer;

@end

NS_ASSUME_NONNULL_END
