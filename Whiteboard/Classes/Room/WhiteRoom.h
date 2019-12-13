//
//  WhiteRoom.h
//  dsBridge
//
//  Created by leavesster on 2018/8/11.
//

#import <Foundation/Foundation.h>
#import "WhiteGlobalState.h"
#import "WhiteMemberState.h"
#import "WhiteImageInformation.h"
#import "WhitePptPage.h"
#import "WhiteRoomMember.h"
#import "WhiteBroadcastState.h"
#import "WhiteRoomCallbacks.h"
#import "WhiteRoomState.h"
#import "WhiteEvent.h"
#import "WhiteScene.h"
#import "WhiteSceneState.h"
#import "WhitePanEvent.h"
#import "WhiteDisplayer.h"

@class WhiteBoardView;

NS_ASSUME_NONNULL_BEGIN

@interface WhiteRoom : WhiteDisplayer

#pragma mark - 同步 API
/** 当前用户在白板上的序号 id。
 从 0 开始，与 RoomMember 中的 memberId 相同
 */
@property (nonatomic, strong, readonly) NSNumber *observerId;
/** 房间 uuid */
@property (nonatomic, copy, readonly) NSString *uuid;
/** 全局状态，由于遗留问题，目前该 API，不支持 customGlobalState，如需获取 customGlobalState，请使用 room.state.globalState */
@property (nonatomic, strong, readonly) WhiteGlobalState *globalState;
/** 教具信息 */
@property (nonatomic, strong, readonly) WhiteReadonlyMemberState *memberState;
/** 白板在线成员信息 */
@property (nonatomic, strong, readonly) NSArray<WhiteRoomMember *> *roomMembers;
/** 视角状态信息，用户当前场景状态，主播信息 */
@property (nonatomic, strong, readonly) WhiteBroadcastState *broadcastState;
/** 缩放比例 */
@property (nonatomic, assign, readonly) CGFloat scale;
@property (nonatomic, strong, readonly) WhiteRoomState *state;
/** 场景状态 */
@property (nonatomic, strong, readonly) WhiteSceneState *sceneState;
/** 连接状态 */
@property (nonatomic, assign, readonly) WhiteRoomPhase phase;

#pragma mark - action API

/** 白板所有人共享的全局状态
 1.0 用户请阅读文档站中 [场景管理] 更新 API，使用setScencePath API
 */
- (void)setGlobalState:(WhiteGlobalState * )globalState;

/** 目前主要用来切换教具 */
- (void)setMemberState:(WhiteMemberState *)modifyState;

/** 切换用户视角模式 */
- (void)setViewMode:(WhiteViewMode)viewMode;
#pragma mark - action API

/**
 如果白板窗口大小改变。应该重新调用该方法刷新尺寸
 查看父类 WhiteDisplayer 类中方法
 */
//- (void)refreshViewSize;

/** 主动断开连接 */
- (void)disconnect:(void (^ _Nullable) (void))completeHandler;

#pragma mark - Operation
/**
 进入只读模式，不响应用户任何手势
 @param readonly 是否进入只读模式
 */
- (void)disableOperations:(BOOL)readonly;

/**
 禁止视野移动

 @param disableCameraTransform 是否禁止移动
 */
- (void)disableCameraTransform:(BOOL)disableCameraTransform;

/**
 禁止用户的教具操作

 @param disable 是否禁止教具操作
 */
- (void)disableDeviceInputs:(BOOL)disable;

#pragma mark - PPT
- (void)pptNextStep;
- (void)pptPreviousStep;

#pragma mark - Image API

/**
 1. 先使用 insertImage API，插入占位图
 2. 再通过 completeImageUploadWithUuid:src: 替换内容
 */
- (void)insertImage:(WhiteImageInformation *)imageInfo;

/**
 替换占位图中的内容，如不需要占位符显示，可以直接使用 insertImage:src: API

 @param uuid insertImage API 中，imageInfo 传入的图片 uuid
 @param src 图片的网络地址
 */
- (void)completeImageUploadWithUuid:(NSString *)uuid src:(NSString *)src;

/** 封装上述两个 API */
- (void)insertImage:(WhiteImageInformation *)imageInfo src:(NSString *)src;

#pragma mark - 延时
- (void)setTimeDelay:(NSTimeInterval)delay;
@property (nonatomic, assign, readonly) NSTimeInterval delay;

#pragma mark - 自定义事件
/**
 发送自定义事件，详细内容，可以查看文档，或者单元测试代码，
 注册，移除自定义事件 API，在 WhiteDisplayer 父类中
 */
- (void)dispatchMagixEvent:(NSString *)eventName payload:(NSDictionary *)payload;

@end


#pragma mark - 场景管理 API
/** 白板场景（多页面）API，为了更好理解本部分 API，请先阅读 [文档站](https://developer.herewhite.com/) 中 [场景管理] 部分概念介绍 */
@interface WhiteRoom (Scene)

/** 获取场景 State，具体信息可以查看 WhiteSceneState 类 */
- (void)getSceneStateWithResult:(void (^) (WhiteSceneState *state))result;

/** 获取当前目录下，所有页面的信息 */
- (void)getScenesWithResult:(void (^) (NSArray<WhiteScene *> *scenes))result;

/**
 切换至具体页面
 
 @param path 具体的页面路径
 
 当传入的页面路径有以下情况时，会导致调用该方法失败
 
 1. 路径不合法。请通过之前的章节确保页面路径符合规范。
 2. 路径对应的页面不存在。
 3. 路径对应的是页面组。注意页面组和页面是不一样的。
 */
- (void)setScenePath:(NSString *)path;
/** 多一个回调，如果失败，会返回具体错误内容 */
- (void)setScenePath:(NSString *)dirOrPath completionHandler:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completionHandler;

/**
 切换上下页
 
 @param index 目标场景 index。当前页面 index，可以通过 getSceneStateWithResult 获取
 @param completionHandler 完成回调，如果失败，会在 error 中的 userInfo 显示错误信息，一般为数组越界
 */
- (void)setSceneIndex:(NSUInteger)index completionHandler:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completionHandler;

/**
 插入，或许新建多个页面
 
 @param dir scene 页面组名称，相当于目录。
 @param scenes WhiteScence 实例；在生成 WhiteScence 时，可以同时配置 ppt。
 @param index 选择在页面组，插入的位置。index 即为新 scence 的 index 位置。如果想要放在最末尾，可以传入 NSUIntegerMax。
 
 注意：scenes 实际上只是白板页面的配置项，scenes 都会生成新页面
 */
- (void)putScenes:(NSString *)dir scenes:(NSArray<WhiteScene *> *)scenes index:(NSUInteger)index;

/**
 清除当前屏幕内容
 
 @param retainPPT 是否保留 ppt
 */
- (void)cleanScene:(BOOL)retainPPT;

/**
 
 当有
 /ppt/page0
 /ppt/page1
 传入 "/ppt/page0" 时，则只删除对应页面。
 传入 "/ppt" 时，会将两个页面一起移除。
 
 @param dirOrPath 页面具体路径，或者为页面组路径
 */
- (void)removeScenes:(NSString *)dirOrPath;

/**
 移动/重命名页面
 
 @param source 想要移动的页面的绝对路径
 @param target 目标路径。如果是文件夹，则将 source 移入；否则，移动的同时重命名。
 */
- (void)moveScene:(NSString *)source target:(NSString *)target;

@end


#pragma mark - 异步 API
/** 该部分 API，均为异步获取。可以使用同步 property 直接获取新数据 */
@interface WhiteRoom (Asynchronous)

/**
 获取当前房间 GlobalState， 该 API不支持自定义 GlobalState。
 通过 + (BOOL)setCustomGlobalStateClass:(Class)clazz 设置自定义状态后，如需异步获取，可以通过 getRoomStateWithResult 获取 自定义 GlobalState。
 */
- (void)getGlobalStateWithResult:(void (^) (WhiteGlobalState *state))result;
/** 获取当前房间 WhiteMemberState:教具 */
- (void)getMemberStateWithResult:(void (^) (WhiteMemberState *state))result;
/** 获取当前房间 WhiteRoomMember：房间成员信息 */
- (void)getRoomMembersWithResult:(void (^) (NSArray<WhiteRoomMember *> *roomMembers))result;
/** 获取当前视角状态 */
- (void)getBroadcastStateWithResult:(void (^) (WhiteBroadcastState *state))result;
/** 获取当前房间连接状态 */
- (void)getRoomPhaseWithResult:(void (^) (WhiteRoomPhase phase))result;
/** 获取当前缩放比例 */
- (void)getZoomScaleWithResult:(void (^) (CGFloat scale))result;
/** 获取当前房间状态，包含 globalState，教具，房间成员信息，缩放，SceneState，用户视角状态 */
- (void)getRoomStateWithResult:(void (^) (WhiteRoomState *state))result;

@end

#pragma mark - 弃用方法
@interface WhiteRoom (Deprecated)

- (void)setViewSizeWithWidth:(CGFloat)width height:(CGFloat)height DEPRECATED_MSG_ATTRIBUTE("use refreshViewSize");

/**
 缩小放大白板
 @param scale 相对于原始大小的比例，而不是相对当前的缩放比例
 
 */
- (void)zoomChange:(CGFloat)scale DEPRECATED_MSG_ATTRIBUTE("use moveCamera:");

/**
 获取所有 ppt 图片，回调内容为所有 ppt 图片的地址。
 @param result 如果当前页面，没有插入过 PPT，则该页面会返回一个空字符串
 */
- (void)getPptImagesWithResult:(void (^) (NSArray<NSString *> *pptPages))result DEPRECATED_MSG_ATTRIBUTE("use getScenesWithResult:");

@end

NS_ASSUME_NONNULL_END
