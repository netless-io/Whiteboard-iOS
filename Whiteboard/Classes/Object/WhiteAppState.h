//
//  WhiteAppState.h
//  Whiteboard
//
//  Created by Codex on 2026/2/24.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/** 开启多窗口后，应用状态。 */
@interface WhiteAppState : WhiteObject

/** 当前聚焦的 App ID。 */
@property (nonatomic, copy, nullable) NSString *focusedId;

/** 当前所有 App ID。 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *appIds;

@end

NS_ASSUME_NONNULL_END
