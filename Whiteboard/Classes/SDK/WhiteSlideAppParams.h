//
//  WhiteSlideAppParams.h
//  Whiteboard
//
//  Created by xuyunshi on 2023/3/2.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * PPTInvisibleBehaviorKey NS_STRING_ENUM;

extern PPTInvisibleBehaviorKey const PPTInvisibleBehaviorKeyFrozen;
extern PPTInvisibleBehaviorKey const PPTInvisibleBehaviorKeyPause;

@interface WhiteSlideAppParams : WhiteObject

/**
 是否显示 Slide 中的错误提示
 
 - `YES`：显示。
 - `NO`：不显示 (默认)。
 */
@property (nonatomic, assign) BOOL showRenderError;

/**
 是否开启 Debug 模式 (默认 NO)。
*/
@property (nonatomic, assign) BOOL debug;

/**
 是否可以通过点击 ppt 画面执行下一步功能 (默认 YES)。
*/
@property (nonatomic, assign) BOOL enableGlobalClick;

/**
 设置最小 fps, 应用会尽量保证实际 fps 高于此值, 此值越小, cpu 开销越小 (默认 25)。
 */
@property (nonatomic, strong) NSNumber *minFPS;

/**
 设置最大 fps, 应用会保证实际 fps 低于此值, 此值越小, cpu 开销越小 (默认 30)。
 */
@property (nonatomic, strong) NSNumber *maxFPS;

/**
 渲染分辨倍率, 原始 ppt 有自己的像素尺寸，当在 2k 或者 4k 屏幕下，如果按原始 ppt 分辨率显示，画面会比较模糊。可以调整此值，使画面更清晰，同时性能开销也变高。
 建议保持默认值就行，或者固定为 1  (默认 1)。
 */
@property (nonatomic, strong) NSNumber *resolution;

/**
 Used to set the maximum display resolution. This value not only affects the canvas rendering resolution, but also affects the texture quality.
 On low-end devices, reducing this value can greatly improve memory usage and image black screen phenomenon.
 
 [0] 640 * 360
 
 [1] 960 * 540;
 
 [2] Normal 1280 * 720; --- default setting for mobile devices.
 
 [3] HD 1920 * 1080;
 
 [4] 3K 3200 × 1800, greater than 4 is calculated as 4; --- default setting for PC devices.
 
 By default, PC devices are set to 3K, and mobile devices are set to 720P（默认 2）。
 */
@property (nonatomic, strong) NSNumber *maxResolutionLevel;

/**
 Whether to force the use of 2D rendering, forcing the use of 2D rendering will lose some 3D, filters, and effects. (默认 NO)。
 */
@property (nonatomic, assign) BOOL forceCanvas;

/**
 background color for slide animations. ex. "#ff0000" (默认 nil）。
 */
@property (nonatomic, copy, nullable) NSString *bgColor;

/**
 Specify the behavior after hiding the slide; Freeze will destroy the slide and replace it with a snapshot, while Pause simply pauses the slide @default: 'frozen'
 */
@property (nonatomic, copy, nullable) PPTInvisibleBehaviorKey invisibleBehavior;

@end

NS_ASSUME_NONNULL_END
