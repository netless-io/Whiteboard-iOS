//
//  WhiteRoomConfig+FPA.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/2/16.
//

#import "WhiteRoomConfig.h"

@interface WhiteRoomConfig ()

/** 将 WhiteboardView 中的 webSocket 迁移到 WhiteSocket 中连接实现  */
@property (nonatomic, assign) BOOL nativeWebSocket API_AVAILABLE(ios(13.0));

@end
