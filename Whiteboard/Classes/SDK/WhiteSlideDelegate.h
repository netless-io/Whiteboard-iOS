//
//  WhiteSlideDelegate.h
//  Whiteboard
//
//  Created by xuyunshi on 2023/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * WhiteSlideErrorType NS_STRING_ENUM;

extern WhiteSlideErrorType const WhiteSlideErrorTypeResourceError;
extern WhiteSlideErrorType const WhiteSlideErrorTypeRuntimeError;
extern WhiteSlideErrorType const WhiteSlideErrorTypeRuntimeWarn;
extern WhiteSlideErrorType const WhiteSlideErrorTypeCanvasCrash;
extern WhiteSlideErrorType const WhiteSlideErrorTypeCanvasUnknown;

typedef void (^SlideUrlInterrupterCallback)(NSString * _Nullable result);

/** 多窗口 Slide 回调。 */
@protocol WhiteSlideDelegate <NSObject>

@optional

/**
 Slide 资源拦截回调。
 
 **Note:**
 
 - 要触发该回调，必须在初始化白板 SDK 时，设置 `WhiteSdkConfiguration.enableSlideInterrupterAPI(YES)` 开启 Slide 拦截替换功能。详见 [WhiteSdkConfiguration](WhiteSdkConfiguration)。
 @param url 资源原地址。
 @param completionHandler 替换后的地址回调，完成 url 替换后请调用该方法。
 */
- (void)slideUrlInterrupter:(NSString * _Nullable)url completionHandler:(SlideUrlInterrupterCallback _Nullable )completionHandler;

/**
 - 当 ppt 点击链接时触发该回调。
 @param url 点击的链接地址。
 */
- (void)slideOpenUrl:(NSString *)url;

/**
 Slide 资源加载失败达到最大重试次数时触发。
 @param url 资源地址。
 @param error 错误信息。`NSLocalizedDescriptionKey` 为错误消息，`NSDebugDescriptionErrorKey` 为 JS 堆栈。
 */
- (void)onSlideResourceMaxRetries:(NSString *)url error:(NSError *)error;

/**
 Slide 资源重试耗尽回调，包含失败页的上下文。实现此回调时，SDK 优先调用此方法。
 @param url 加载失败的资源 URL。
 @param error 错误信息。
 @param slideId Slide 实例 ID，旧资源包可能返回空字符串。
 @param pageIndex 失败页码，从 1 开始，-1 表示未知。
 @param isPreload 为 YES 时该资源错误未阻塞当前页渲染，旧资源包默认为 YES。
 */
- (void)onSlideResourceMaxRetries:(NSString *)url error:(NSError *)error slideId:(NSString *)slideId pageIndex:(NSInteger)pageIndex isPreload:(BOOL)isPreload;

- (void)onSlideError:(WhiteSlideErrorType)slideError errorMessage:(NSString *)errorMessage slideId:(NSString *)slideId slideIndex:(NSInteger)slideIndex;

/**
 Slide 页面状态变化回调。

 @param appId SlideApp 的窗口 ID。
 @param page 当前页码，从 1 开始。
 @param pageCount 页面总数。
 */
- (void)onSlidePageStateChanged:(NSString *)appId page:(NSInteger)page pageCount:(NSInteger)pageCount;

@end

NS_ASSUME_NONNULL_END
