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

- (void)onSlideError:(WhiteSlideErrorType)slideError errorMessage:(NSString *)errorMessage slideId:(NSString *)slideId slideIndex:(NSInteger)slideIndex;

@end

NS_ASSUME_NONNULL_END
