//
//  WhiteBroadView.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#if __has_include(<NTLBridge/ntl_dsbridge.h>)
#import <NTLBridge/ntl_dsbridge.h>
#else
#import "ntl_dsbridge.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class WhiteRoom, WhitePlayer;

/**白板界面类。*/
@interface WhiteBoardView : NTLDWKWebView

/**白板房间类。详见 [WhiteRoom](WhiteRoom)。*/
@property (nonatomic, strong, nullable) WhiteRoom *room;
/**白板回放类。详见 [WhitePlayer](WhitePlayer)。*/
@property (nonatomic, strong, nullable) WhitePlayer *player;

/**
 是否禁用 SDK 本身对键盘偏移的处理。

 - `YES`:禁用 SDK 本身对键盘偏移的处理。
 - `NO`:启用 SDK 本身对键盘偏移的处理。
 */
@property (nonatomic, assign) BOOL disableKeyboardHandler;

/**
 初始化白板界面。
 
 @return 初始化的 `WhiteBroadView` 对象。
 */
- (instancetype)init;

/**
 使用自定义 URL 加载白板资源。
 */
- (instancetype)initCustomUrl:(nullable NSString *)customUrl;

/**
 初始化白板界面，并配置是否启用 https scheme 的本地资源加载方式（试验性功能）。
 */
- (instancetype)initWithEnableHttpsScheme:(BOOL)enableHttpsScheme;

/**
 使用自定义 URL 加载白板资源，并配置是否启用 https scheme 的本地资源加载方式（试验性功能）。
 */
- (instancetype)initCustomUrl:(nullable NSString *)customUrl enableHttpsScheme:(BOOL)enableHttpsScheme;

@end

NS_ASSUME_NONNULL_END
