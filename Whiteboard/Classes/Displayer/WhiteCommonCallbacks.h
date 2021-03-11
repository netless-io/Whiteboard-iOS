//
//  WhiteBaseCallbacks.h
//  WhiteSDK
//
//  Created by yleaf on 2019/3/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WhiteCommonCallbackDelegate <NSObject>

@optional

/** 当sdk出现未捕获的全局错误时，会在此处对抛出 NSError 对象 */
- (void)throwError:(NSError *)error;


/**
 图片拦截替换回调。
 启用该功能，需要在初始化 SDK 时，配置 WhiteSdkConfiguration enableInterrupterAPI 属性 为 YES；
 初始化后，无法更改。
 启用后，在调用插入图片API/插入scene 时，会回调该 API，允许在实际显示时，替换 url
 在回放中，也会持续调用。

 @param url 原始图片地址
 @return 替换后的图片地址
 */
- (NSString *)urlInterrupter:(NSString *)url;

/**
 * 动态 ppt 中的音视频媒体，播放通知
 */
- (void)pptMediaPlay;

/**
 * 动态 ppt 中的音视频媒体，暂停通知
 */
- (void)pptMediaPause;

/**
 * 初始化 SDK 时，会根据传入的 App Identifier 向服务器配置信息（最多尝试三次）
 * 如果失败，SDK 处于不可用状态，调用加入房间/回放房间会处于一直无响应状态，需要开发者重新初始化 SDK。
 * 一般触发情况：
 * 1. 初始化 SDK 时候，网络异常，导致获取配置信息失败；
 * 2. 传入了错误不合法的 App Identifier
 * @since 2.9.13
 */
- (void)sdkSetupFail:(NSError *)error;

/**
 * 转发一些在 web 端封装的一些自定义事件；
 * 目前存在的事件：
 * 1. iframe 透传信息; 数据格式由 iframe 协商定义，直接透传
 *      限制必须为 字典格式，同时必须存在 name 字段，且值必须为 "iframe"
 * 2. 图片加载失败信息（必须先在初始化先开启），格式：
 *     {name: "imageLoadError",
 *      customMessage: true,
 *      src: 图片地址}
 * 3. ppt 播放，暂停信息（该事件，可以直接监听 pptMediaPlay 和 pptMediaPause，此处不提供具体格式）
 */
- (void)customMessage:(NSDictionary *)dict;

@end


/**
 会自行设置，无需关注
 */
@interface WhiteCommonCallbacks : NSObject

@property (nonatomic, weak) id<WhiteCommonCallbackDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
