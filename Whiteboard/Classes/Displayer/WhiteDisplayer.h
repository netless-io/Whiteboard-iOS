//
//  WhiteDisplayer.h
//  WhiteSDK
//
//  Created by yleaf on 2019/7/1.
//

#import <Foundation/Foundation.h>
#import "WhiteCameraConfig.h"
#import "WhiteRectangleConfig.h"
#import "WhiteCameraBound.h"
#import "WhitePanEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteDisplayer : NSObject

/**
 修改白板背景色 API。
 如需在显示 WhiteBoardView 时，就改变颜色，请遵循以下步骤：
 
 1. 先设置 whiteboardView 实例属性 opaque 为 NO。
 2. 设置 WhiteboardView backgroundColr
 3. 在成功初始化实时房间或者回放房间后，通过该 API 再次设置 backgroundColor
 4. 将 WhiteBoardView opaque 属性，恢复为 YES。（由于该 API 异步生效，建议使用延迟 API 恢复）
 
 opaque 为 NO 时，iOS 系统会进行颜色合成计算。比较影响性能。
 所以建议使用该 API 替换。
 */
@property (nonatomic, strong) UIColor *backgroundColor;

#pragma mark - 通用 API

/**  如果白板窗口大小改变。应该重新调用该方法刷新尺寸 */
- (void)refreshViewSize;
/** 返回当前坐标点，在白板内部的坐标位置 */
- (void)convertToPointInWorld:(WhitePanEvent *)point result:(void (^) (WhitePanEvent *convertPoint))result;

#pragma mark -
/** 低频自定义事件注册 */
- (void)addMagixEventListener:(NSString *)eventName;
/**
 * 高频自定义事件注册
 * @param eventName 自定义事件名称
 * @param millseconds 间隔回调频率，毫秒。最低 500ms，低于该值都会被强制设置为 500ms
*/
- (void)addHighFrequencyEventListener:(NSString *)eventName fireInterval:(NSUInteger)millseconds;
- (void)removeMagixEventListener:(NSString *)eventName;

#pragma mark - 视角
/**
 设置视野范围

 @param cameraBound 视野范围描述类
 */
- (void)setCameraBound:(WhiteCameraBound *)cameraBound;

/**
 移动视角中心

 @param camera 视角描述类
 */
- (void)moveCamera:(WhiteCameraConfig *)camera;

/**
 移动到特定的视野范围

 @param rectange 视野描述类
 */
- (void)moveCameraToContainer:(WhiteRectangleConfig *)rectange;

/**
 将 ppt 等比例铺满屏幕（参考 UIViewContentModeScaleAspectFit ）。
 该操作为一次性操作，不会持续锁定。
 如果当前页没有 ppt，则不会进行缩放。
 @param mode 动画参数，连续动画，或者瞬间切换
 */
- (void)scalePptToFit:(WhiteAnimationMode)mode;

#pragma mark - 截图

/**
 截取用户切换时，看到的场景内容，不是场景内全部内容。
 图片支持：只有当图片服务器支持跨域，才可以显示在截图中。（请真机中运行）

 @param scenePath 想要截取场景的场景路径，例如 /init
 @param completionHandler 回调函数，image 可能为空
 */
- (void)getScenePreviewImage:(NSString *)scenePath completion:(void (^)(UIImage * _Nullable image))completionHandler;


/**
 场景封面截图，会包含场景内全部内容
 图片支持：只有当图片服务器支持跨域，才可以显示在截图中。（请真机中运行）

 @param scenePath 想要截取场景的场景路径，例如 /init
 @param completionHandler  回调函数，image 可能为空
 */
- (void)getSceneSnapshotImage:(NSString *)scenePath completion:(void (^)(UIImage * _Nullable image))completionHandler;

@end

NS_ASSUME_NONNULL_END
