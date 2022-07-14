//
//  SyncedStore+Private.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/14.
//

#import "SyncedStore.h"

NS_ASSUME_NONNULL_BEGIN

@class WhiteBoardView;

@interface SyncedStore ()
@property (nonatomic, weak) WhiteBoardView *bridge;
@end

NS_ASSUME_NONNULL_END
