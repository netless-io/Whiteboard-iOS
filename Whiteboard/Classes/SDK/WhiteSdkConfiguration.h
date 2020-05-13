//
//  WhiteSdkConfiguration.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteObject.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WhiteDeviceType) {
    WhiteDeviceTypeTouch,
    WhiteDeviceTypeDesktop,
};

NS_ASSUME_NONNULL_BEGIN

typedef NSString * WhiteSdkRenderEngineKey NS_STRING_ENUM;
FOUNDATION_EXPORT WhiteSdkRenderEngineKey const WhiteSdkRenderEngineSvg;
FOUNDATION_EXPORT WhiteSdkRenderEngineKey const WhiteSdkRenderEngineCanvas;

@interface WhiteSdkConfiguration : WhiteObject

/** 请使用 initWithApp: 方法，传入 appIdentifier 进行初始化，否则无法连接房间。 */
//+ (instancetype)defaultConfig;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithApp:(NSString *)appIdentifier NS_DESIGNATED_INITIALIZER;

/**
 白板 APP id，2.8.0 开始，强制要求。可以在管理控制台 console.netless.link 中登录后查看
 */
@property (nonatomic, copy) NSString *appIdentifier;

/** default value: Touch。native 端，无需关注该属性。 */
@property (nonatomic, assign) WhiteDeviceType deviceType;

/**
 画笔教具的渲染模式。
 2.8.0 新增 canvas 渲染引擎，性能更好。有强烈书写需求的用户，推荐使用该引擎。
 默认为 WhiteSdkRenderEngineSvg，旧版本渲染方式
 */
@property (nonatomic, copy) WhiteSdkRenderEngineKey renderEngine;

/** default value: 0.1 */
@property (nonatomic, assign) CGFloat zoomMinScale;
/** default value: 10 */
@property (nonatomic, assign) CGFloat zoomMaxScale;

/** 设置后，SDK 会打印大部分 房间中的 function，以及收到的参数 */
@property (nonatomic, assign) BOOL debug;

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

/**
 字段 disableReportLog: BOOL
 关闭日志上传功能，默认开启
 */
@property (nonatomic, strong) NSDictionary *loggerOptions;

/** 多路由操作，针对部分 dns 污染情况，临时提供的 native 端解决方案 */
@property (nonatomic, assign) BOOL routeBackup;

/** 服务端连接情况配置项，可以提前使用 WhiteOriginPrefetcher 进行检测服务器连接情况，在初始化 SDK 时，直接传入。 */
@property (nonatomic, nullable, copy) NSDictionary *sdkStrategyConfig;

@end
NS_ASSUME_NONNULL_END
