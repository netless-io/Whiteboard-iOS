//
//  WhiteWindowParams.h
//  Whiteboard
//
//  Created by yleaf on 2022/2/9.
//

#import "WhiteObject.h"
#import "WhiteTeleBoxManagerThemeConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * WhiteTeleBoxFullscreen NS_STRING_ENUM;
/** 全屏模式顶部没有 Title Bar */
FOUNDATION_EXPORT WhiteTeleBoxFullscreen const WhiteTeleBoxFullscreenNoTitleBar;
/** 全屏模式顶部总是显示 Title Bar */
FOUNDATION_EXPORT WhiteTeleBoxFullscreen const WhiteTeleBoxFullscreenAlwaysTitleBar;

typedef NSString * WhitePrefersColorScheme NS_STRING_ENUM;
/** auto只有在iOS13以上才会生效*/
FOUNDATION_EXPORT WhitePrefersColorScheme const WhitePrefersColorSchemeAuto;
FOUNDATION_EXPORT WhitePrefersColorScheme const WhitePrefersColorSchemeLight;
FOUNDATION_EXPORT WhitePrefersColorScheme const WhitePrefersColorSchemeDark;

@interface WhiteWindowParams : WhiteObject

/** 各个端本地显示多窗口内容时，高与宽比例，默认为 9:16。该值应该各个端保持统一，否则会有不可预见的情况。 */
@property (nonatomic, strong) NSNumber *containerSizeRatio;
/** 多窗口区域（主窗口）以外的空间显示 PS 棋盘背景，默认 YES */
@property (nonatomic, assign) BOOL chessboard DEPRECATED_MSG_ATTRIBUTE("no more chessboard");
/** 驼峰形式的 CSS，透传给多窗口时，最小化 div 的 css */
@property (nonatomic, copy, nullable) NSDictionary *collectorStyles;
/**
 是否只允许垂直滚动。（默认为 FALSE)
 TRUE:  只允许垂直滚动，不允许放大。
 FALSE: 允许放大和任意方向滚动。
 注意该值必须在各端保持一致，否则会导致画布无法同步。该参数为 TURE 时，与 room.viewMode 冲突。
 */
@property (nonatomic, assign) BOOL scrollVerticalOnly;
/** 是否在网页控制台打印日志，默认 YES */
@property (nonatomic, assign) BOOL debug;
/** 暗黑模式, 本地效果， 不会同步到远端， 默认Light, 设置auto只有在iOS13以上才会生效*/
@property (nonatomic, copy) WhitePrefersColorScheme prefersColorScheme;
/** 设置该值启动全屏模式，不同的值对应全屏模式的不同样式 */
@property (nonatomic, copy) WhiteTeleBoxFullscreen fullscreen;
/** 配置 telebox-manager-container 的样式, 设置详情见[https://github.com/netless-io/window-manager/blob/1.0/docs/mirgrate-to-1.0.md]*/
@property (nonatomic, copy) NSString *containerStyle;
/** 配置 telebox-manager-stage 的样式, 设置详情见[https://github.com/netless-io/window-manager/blob/1.0/docs/mirgrate-to-1.0.md]*/
@property (nonatomic, copy) NSString *stageStyle;
/** 配置应用窗口默认 body 的样式, 设置详情见[https://github.com/netless-io/window-manager/blob/1.0/docs/mirgrate-to-1.0.md] */
@property (nonatomic, copy) NSString *defaultBoxBodyStyle;
/** 配置应用窗口默认 stage 也就是内容区域的样式, 设置详情见[https://github.com/netless-io/window-manager/blob/1.0/docs/mirgrate-to-1.0.md] */
@property (nonatomic, copy) NSString *defaultBoxStageStyle;
/** 配置默认的颜色变量 */
@property (nonatomic, strong) WhiteTeleBoxManagerThemeConfig *theme;

@end

NS_ASSUME_NONNULL_END
