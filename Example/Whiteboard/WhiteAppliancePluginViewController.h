//
//  WhiteAppliancePluginViewController.h
//  Whiteboard_Example
//
//  Created by Codex on 2026/8/19.
//

#import "WhiteRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

/** 与 Android/Harmony demo 对齐的 appliance-plugin 演示房间。 */
@interface WhiteAppliancePluginViewController : WhiteRoomViewController

/** Enable the appliance-plugin ImageBitmap fallback path for this demo instance. */
@property (nonatomic, assign) BOOL allowImageBitmapFallback;

@end

NS_ASSUME_NONNULL_END
