//
//  TestUtility.h
//  Whiteboard_Tests
//
//  Created by xuyunshi on 2022/3/30.
//  Copyright © 2022 leavesster. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval kTimeout = 30;

@interface TestUtility : NSObject

+ (void)updateRoomWithUuid:(NSString *)uuid ban:(BOOL)ban completionHandler:(void(^)(NSError * _Nullable error)) completionHandler;

@end

NS_ASSUME_NONNULL_END
