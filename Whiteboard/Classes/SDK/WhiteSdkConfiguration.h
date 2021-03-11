//
//  WhiteSdkConfiguration.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteObject.h"
#import <UIKit/UIKit.h>
#import "WhiteConsts.h"

typedef NS_ENUM(NSInteger, WhiteDeviceType) {
    WhiteDeviceTypeTouch,
    WhiteDeviceTypeDesktop,
};

NS_ASSUME_NONNULL_BEGIN


typedef NSString * WhiteSdkRenderEngineKey NS_STRING_ENUM;
FOUNDATION_EXPORT WhiteSdkRenderEngineKey const WhiteSdkRenderEngineSvg;
FOUNDATION_EXPORT WhiteSdkRenderEngineKey const WhiteSdkRenderEngineCanvas;


typedef NSString * WhiteSDKLoggerOptionLevelKey NS_STRING_ENUM;
/** debug 为最详细的日志，目前内容与 info 一致 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelDebug;
/** info 主要为连接日志 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelInfo;
/** warn 主要为对开发者传入的部分不符合 sdk 参数时，进行自动调整的警告（API 弃用警告不会在上报） */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelWarn;
/** error 报错，直接导致 sdk 无法正常运行的信息 */
FOUNDATION_EXPORT WhiteSDKLoggerOptionLevelKey const WhiteSDKLoggerOptionLevelError;

typedef NSString * WhiteSDKLoggerReportModeKey NS_STRING_ENUM;
/** 总是上报 */
FOUNDATION_EXPORT WhiteSDKLoggerReportModeKey const WhiteSDKLoggerReportAlways;
/** 不上报 */
FOUNDATION_EXPORT WhiteSDKLoggerReportModeKey const WhiteSDKLoggerReportBan;

@interface WhitePptParams : WhiteObject

/**
 如果传入，则所有 ppt 的网络请求，以及图片地址，都会从 https 换成该值。
 该属性，配合 iOS 11 WebKit 中 WKWebViewConfiguration 类的 setURLSchemeHandler:forURLScheme: 方法，就可以对 ppt 的资源进行拦截，选择使用本地资源
 */
@property (nonatomic, copy, nullable) NSString *scheme API_AVAILABLE(ios(11.0));

/**
 * 2021-02-10 之后转换的动态 ppt 支持服务端排版功能，可以确保不同平台排版一致
 *
 */
@property (nonatomic, assign) BOOL useServerWrap;

@end


@interface WhiteSdkConfiguration : WhiteObject

/** 请使用 initWithApp: 方法，传入 appIdentifier 进行初始化，否则无法连接房间。 */
//+ (instancetype)defaultConfig;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithApp:(NSString *)appIdentifier NS_DESIGNATED_INITIALIZER;

/**
 白板 APP id，2.8.0 开始，强制要求。可以在管理控制台 console.netless.link 中登录后查看
 */
@property (nonatomic, copy) NSString *appIdentifier;

/**
 * 监听白板中所有 img 标签图片加载失败事件，默认关闭
 * 2.11.23 新增 API
 */
@property (nonatomic, assign) BOOL enableImgErrorCallback;
/**
 * 是否开启 iFrame 插件，默认关闭。
 * 2.10.0 版本默认打开，后续版本默认关闭
 */
@property (nonatomic, assign) BOOL enableIFramePlugin;

/** default value: Touch。native 端，无需关注该属性。 */
@property (nonatomic, assign) WhiteDeviceType deviceType;

/** 默认为中国数据集群，@since 2.11.0 */
@property (nonatomic, strong, nullable) WhiteRegionKey region;
/**
 画笔教具的渲染模式。
 2.8.0 新增 canvas 渲染引擎，性能更好。2.9.0 开始，默认为 WhiteSdkRenderEngineCanvas。
 */
@property (nonatomic, copy) WhiteSdkRenderEngineKey renderEngine;

/** 显示操作用户头像(需要在加入房间时，配置 userPayload，并确保存在 avatar 字段) */
@property (nonatomic, assign) BOOL userCursor;
/** 文档转网页中字体文件映射关系 */
@property (nonatomic, copy, nullable) NSDictionary *fonts;

/** 是否预加载动态 ppt 资源，默认否 */
@property (nonatomic, assign) BOOL preloadDynamicPPT;
/**
  图片拦截替换功能，实时房间与回放房间通用
  当开启图片拦截后，最后显示图片时，会回调初始化 sdk 时，传入的 WhiteCommonCallbackDelegate 对象。
 */
@property (nonatomic, assign) BOOL enableInterrupterAPI;

/** 设置后，SDK 会打印大部分 房间中的 function，以及收到的参数 */
@property (nonatomic, assign) BOOL log;

/**
 
{
    // SDK 日志信息上报模式（可选，默认 info）
    @"reportDebugLogMode": WhiteSDKLoggerOptionLevelKey;
 
    // 客户端本地，用户连接质量上报模式（可选，默认上报）
    @"reportQualityMode": WhiteSDKLoggerReportModeKey;

    // SDK 日志上报等级（可选，默认 info）
    @"reportLevelMask": Level;
    // webview 控制台打印日志等级（可选，默认 info）
    @"printLevelMask": Level;
 };

 关闭日志上传功能，默认开启。
 */
@property (nonatomic, copy) NSDictionary *loggerOptions;

/** 多路由操作，针对部分 dns 污染情况，临时提供的 native 端解决方案 */
@property (nonatomic, assign) BOOL routeBackup;

/** 动态 ppt 参数，目前可以修改动态 ppt 发起的所有网络请求的 scheme，然后在 iOS11 及其以上，可以通过 WKWebview 的接口，对其进行拦截 */
@property (nonatomic, strong) WhitePptParams *pptParams;

/** 禁止教具操作 */
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
