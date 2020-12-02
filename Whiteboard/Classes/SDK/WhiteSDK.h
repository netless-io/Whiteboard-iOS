//
//  WhiteSDK.h
//  Pods-white-ios-sdk_Example
//
//  Created by leavesster on 2018/8/11.
//

#import <Foundation/Foundation.h>
#import "WhiteBoardView.h"
#import "WhiteCommonCallbacks.h"
#import "WhiteSdkConfiguration.h"
#import "WhiteAudioMixerBridge.h"
#import "WhiteFontFace.h"
NS_ASSUME_NONNULL_BEGIN

/** 非单例，一个 SDK 实例绑定，为了能够进行重连房间操作，最好由当前 ViewController 持有。 */
@interface WhiteSDK : NSObject


/** White SDK 版本号 */
+ (NSString *)version;

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback audioMixerBridgeDelegate:(nullable id<WhiteAudioMixerBridgeDelegate>)mixer;
/**
 初始化方法, CommonCallback 为 Room 与 Player 都支持的 callback
 注意: 在 iOS 12 以后，调用该方法，以及任何 sdk 代码时，都先确保 WhiteBoardView 在视图栈中，并且没有被隐藏（可以被遮盖）
 */
- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config commonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callback;

- (instancetype)initWithWhiteBoardView:(WhiteBoardView *)boardView config:(WhiteSdkConfiguration *)config DEPRECATED_MSG_ATTRIBUTE("initWithWhiteBoardView:config:commonCallbackDelegate");

@property (nonatomic, strong, readonly, nullable) WhiteAudioMixerBridge *audioMixer;

#pragma mark - 字体

/**
 * @param fontFaces 需要增加的字体，当名字可以提供给 ppt 和文字教具使用。
 * 注意：1. 该修改只在本地有效，不会对远端造成影响。
 *      2. 以这种方式插入的 FontFace，只有当该字体被使用时，才会触发下载。
 *      3. FontFace，可能会影响部分设备的渲染逻辑，部分设备，可能会在完成字体加载后，才渲染文字。
 *      4. 该 API 插入的字体，为一个整体，重复调用该 API，会覆盖之前的字体内容。
 *      5. 该 API 与 loadFontFaces 重复使用，无法预期行为，请尽量避免。
 * @since 2.11.3
 */
- (void)setupFontFaces:(NSArray <WhiteFontFace *>*)fontFaces;

/**
 * @param fontFaces 需要增加的字体，可以提供给 ppt 和文字教具使用。
 * @param completionHandler 如果有报错，会在此处错误回调。该回调会在每一个字体加载成功或者失败后，单独回调。FontFace 填写正确的话，有多少个字体，就会有多少个回调。
 * 注意：1. 该修改只在本地有效，不会对远端造成影响。
 *      2. FontFace，可能会影响部分设备的渲染逻辑，部分设备，可能会在完成字体加载后，才渲染文字。
 *      3. 该 API 插入的字体，无法删除；每次都是增加新字体。
 *      4. 该 API 与 setupFontFaces 重复使用，无法预期行为，请尽量避免。
 * @since 2.11.3
 */
- (void)loadFontFaces:(NSArray <WhiteFontFace *>*)fontFaces completionHandler:(void (^)(BOOL success, WhiteFontFace *fontFace, NSError * _Nullable error))completionHandler;

/**
 * @param fonts 定义文字教具，在本地使用的字体。
 * 注意：该修改只在本地有效，不会对远端造成影响。
 * @since 2.11.3
 */
- (void)updateTextFont:(NSArray <NSString *>*)fonts;

#pragma mark - CommonCallback

/// 更新 CommonCallback 的 delegate
/// @param callbackDelegate 为空，会移除原有的 CallbackDelegate
- (void)setCommonCallbackDelegate:(nullable id<WhiteCommonCallbackDelegate>)callbackDelegate;


@end
NS_ASSUME_NONNULL_END
