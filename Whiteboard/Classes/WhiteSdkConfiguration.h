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

@interface WhiteSdkConfiguration : WhiteObject

+ (instancetype)defaultConfig;

/** default value: Touch。native 端，无需关注该属性。 */
@property (nonatomic, assign) WhiteDeviceType deviceType;

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

@end
NS_ASSUME_NONNULL_END
