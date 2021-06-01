//
//  WhiteSdkConfiguration.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteObject.h"
#import <UIKit/UIKit.h>
#import "WhiteConsts.h"

//文档中隐藏
typedef NS_ENUM(NSInteger, WhiteDeviceType) {
    WhiteDeviceTypeTouch,
    WhiteDeviceTypeDesktop,
};

NS_ASSUME_NONNULL_BEGIN

/**
 笔迹的渲染引擎模式。
 */
typedef NSString * WhiteSdkRenderEngineKey NS_STRING_ENUM;
/**
 * SVG 渲染模式。
 * 2.8.0 及之前版本的 `WhiteSdk` 默认使用的渲染模式，该模式兼容性较好，但性能较差。
 */
FOUNDATION_EXPORT WhiteSdkRenderEngineKey const WhiteSdkRenderEngineSvg;
/**
 * Canvas 渲染模式。
 * <p>
 * 2.8.0 版本起新增 `canvas` 渲染模式，该模式性能较好，但兼容性较差。
 * 2.9.0 及之后版本的 `WhiteSdk` 默认使用 `canvas` 渲染模式。
 *
 */
FOUNDATION_EXPORT WhiteSdkRenderEngineKey const WhiteSdkRenderEngineCanvas;

/** 日志类型 */
typedef NSString * WhiteSDKLoggerOptionLevelKey NS_STRING_ENUM;
/**  Debug 调试日志：最详细的日志，目前内容与 `info` 一致。 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelDebug;
/** Info 信息日志：主要为连接状态。 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelInfo;
/** Warn 警告日志：当传入的参数不符合 SDK 要求时，SDK 会自动调整并发出警告。

 **Note：** 
 
 如果调用废弃 API，SDK 不会发出警告信息。 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelWarn;
/** Error 报错日志：直接导致 SDK 无法正常运行的错误。 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelError;

/** 日志上报模式。 */
typedef NSString * WhiteSDKLoggerReportModeKey NS_STRING_ENUM;
/** 总是上报日志（默认）。 */
FOUNDATION_EXPORT WhiteSDKLoggerReportModeKey const WhiteSDKLoggerReportAlways;
/** 禁止上报日志。 */
FOUNDATION_EXPORT WhiteSDKLoggerReportModeKey const WhiteSDKLoggerReportBan;

/** 设置动态 PPT 参数。 */
@interface WhitePptParams : WhiteObject

/**
 `scheme`：更改动态 ppt 请求时的请求协议，可以将 https://www.exmaple.com/1.pptx 更改成 scheme://www.example.com/1.pptx

 该属性配合 iOS 11 WebKit 中 `WKWebViewConfiguration` 类的 `setURLSchemeHandler:forURLScheme:` 方法，可以对 PPT 的资源进行拦截，选择使用本地资源。
 */
@property (nonatomic, copy, nullable) NSString *scheme API_AVAILABLE(ios(11.0));

/**
 动态 PPT 服务端排版功能的开启状态。
 
 @since 2.12.25

 - `YES`：开启。
 - `NO`：关闭。

 **Note：**
 
 2021-02-10 之后转换的动态 PPT 支持服务端排版功能，可以确保不同平台排版一致。
 */
@property (nonatomic, assign) BOOL useServerWrap;

@end

/** 用于配置 `WhiteSdk` 对象。*/
@interface WhiteSdkConfiguration : WhiteObject

//+ (instancetype)defaultConfig;
- (instancetype)init NS_UNAVAILABLE;

/**
 初始化 `WhiteSdkConfiguration` 对象。

 @param appIdentifier 白板项目的唯一标识。详见[获取白板项目的 App Identifier](https://docs.agora.io/cn/whiteboard/enable_whiteboard?platform=iOS#获取-app-identifier)。
 @return 初始化的 `WhiteSdkConfiguration` 对象。
*/
- (instancetype)initWithApp:(NSString *)appIdentifier NS_DESIGNATED_INITIALIZER;

/**
 白板项目的唯一标识。
 
 @since 2.8.0 
 */
@property (nonatomic, copy) NSString *appIdentifier;

/**
 是否监听图片加载失败事件。

  - `YES`：开启监听。
  - `NO`：（默认）关闭。

 @since 2.12.0
 */
@property (nonatomic, assign) BOOL enableImgErrorCallback;
/**
 是否启用 iframe 插件。

 - `YES`：开启。
 - `NO`：未启用。

 2.10.0 默认打开，后续版本默认关闭。
 */
@property (nonatomic, assign) BOOL enableIFramePlugin;


@property (nonatomic, assign) WhiteDeviceType deviceType;

/** 
 互动白板房间所在的数据中心。

 数据中心包括：

 - `"cn-hz"`：中国杭州。该数据中心为其他数据中心服务区未覆盖的地区提供服务。
 - `"us-sv"`：美国硅谷。该数据中心为北美洲、南美洲地区提供服务。
 - `"in-mum"`：印度孟买。该数据中心为印度地区提供服务。
 - `"sg"`：新加坡。该数据中心为新加坡、东亚、东南亚地区提供服务。
 - `"gb-lon"`：英国伦敦。该数据中心为欧洲地区提供服务。

 **Note:**
 
 SDK 初始化时设置的 region 必须和创建房间时指定的 region 一致；否则，SDK 无法连接到房间。
 
 @since 2.11.0 */
@property (nonatomic, strong, nullable) WhiteRegionKey region;
/**
 画笔教具的渲染引擎模式。详见 [WhiteSdkRenderEngineKey](WhiteSdkRenderEngineKey)。

 @since 2.8.0
 
 2.8.0 版本新增 `canvas` 渲染引擎。从 2.9.0 版本开始，默认值为 `WhiteSdkRenderEngineCanvas`。
 */
@property (nonatomic, copy) WhiteSdkRenderEngineKey renderEngine;

/** 
 是否显示用户头像。

 要显示用户头像，请确保你在 [initWithUuid]([WhiteRoomConfig initWithUuid:roomToken:userPayload:]) 时 在`userPayload` 对象中传入了头像的键值对。

 - `YES`：显示。
 - `NO`：（默认）不显示。
 */
@property (nonatomic, assign) BOOL userCursor;
/** 自定义字体名称和地址。 */
@property (nonatomic, copy, nullable) NSDictionary *fonts;

/** 
 是否在加载动态 PPT 首页时，一次性加载动态 PPT 中的所有图片资源。

 **Note：** 
 
 Agora 不推荐设置 setPreloadDynamicPPT(true)，这样会使 PPT 显示缓慢。

 - `YES`：开启。
 - `NO`: （默认）未开启。
 */
@property (nonatomic, assign) BOOL preloadDynamicPPT;
/**
 是否开启图片拦截和替换功能。

 - `YES`：开启。
 - `NO`：关闭。
 */
@property (nonatomic, assign) BOOL enableInterrupterAPI;

/** 是否开启调试日志回调。

 - `YES`：开启。
 - `NO`：（默认）关闭。 
 */
@property (nonatomic, assign) BOOL log;

/**
 日志等级。

 日志级别顺序依次为 `error`、`warn`、`info`、和 `debug`。选择一个级别，你就可以看到在该级别之前所有级别的日志信息。
 
 例如，你选择 `info` 级别，就可以看到在 `error`、`warn`、`info` 级别上的所有日志信息。

 - 日志信息上报模式：可选，默认为 `info`。
 - 客户端本地：用户连接质量上报模式，默认为`上报`。
 - 日志上报等级：可选，默认为 `info`。
 - webview 控制台打印日志等级：可选，默认为 `info`。
 - 关闭日志上传功能：默认开启。
 */
@property (nonatomic, copy) NSDictionary *loggerOptions;


@property (nonatomic, assign) BOOL routeBackup;

/** 动态 ppt 参数。详见 [WhitePptParams](WhitePptParams)。 */
@property (nonatomic, strong) WhitePptParams *pptParams;


@property (nonatomic, assign) BOOL disableDeviceInputs;

@end

@implementation WhiteSdkConfiguration (Deleted)

/**
 在加入实时房间/回放房间时，将构造的 cameraBound 参数传入初始化方法中。
 具体见 WhiteDisplayer.h 中 setCameraBound API。
 */

//@property (nonatomic, assign) CGFloat zoomMinScale;
//@property (nonatomic, assign) CGFloat zoomMaxScale;

/**
 服务端连接情况配置项，可以提前使用 WhiteOriginPrefetcher 进行检测服务器连接情况，在初始化 SDK 时，直接传入。
 2.8.0 开始，sdk 算法优化，自动在请求时，选择最佳链路。该配置不再起作用。
 */
//@property (nonatomic, nullable, copy) NSDictionary *sdkStrategyConfig;

@end
NS_ASSUME_NONNULL_END
