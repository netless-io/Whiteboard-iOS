//
//  WhiteRoomConfig.h
//  WhiteSDK
//
//  Created by yleaf on 2019/3/30.
//

#import "WhiteObject.h"
#import "WhiteMemberInformation.h"
#import "WhiteCameraBound.h"
#import "WhiteConsts.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteRoomConfig : WhiteObject

- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken;
- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken memberInfo:(WhiteMemberInformation * _Nullable)memberInfo  __attribute__((deprecated("memberInfo is deprecated, please use userPayload")));;
- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken userPayload:(id _Nullable)userPayload NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *roomToken;

/** 默认为中国数据集群，@since 2.11.0 */
@property (nonatomic, strong, nullable) WhiteRegionKey region;

/**
 禁止教具响应用户输入，默认 NO，即允许。
 */
@property (nonatomic, assign) BOOL disableDeviceInputs;

/**
 禁止用户缩放、移动视角，默认 NO,即允许
 */
@property (nonatomic, assign) BOOL disableCameraTransform;
/**
 禁止贝塞尔曲线优化，默认 NO，即允许。
 */
@property (nonatomic, assign) BOOL disableBezier;

/**
 禁止白板响应用户操作，默认 NO，即允许。直接操作该属性，会同时修改 disableDeviceInputs disableCameraTransform 两个属性。
 */
@property (nonatomic, assign) BOOL disableOperations __attribute__((deprecated("please use disableDeviceInputs and disableCameraTransform")));

/**
 禁止橡皮擦擦除所有图片，默认 NO，即允许橡皮擦擦除图片。
 */
@property (nonatomic, assign) BOOL disableEraseImage;

/**
 视野范围限制
 */
@property (nonatomic, strong, nullable) WhiteCameraBound *cameraBound;

/**
 加入房间时，允许带入用户数据（限制：允许转换为 JSON，或者单纯的 NSString，数字 NSNumber）。
 推荐为 NSDictionary
 */
@property (nonatomic, copy, nullable) id userPayload;
@property (nonatomic, copy, nullable) WhiteMemberInformation *memberInfo __attribute__((deprecated("memberInfo is deprecated, please use userPayload")));

/**
 进入房间时的读写模式， 默认为 true。
 当为 false 时，只能接收其他人同步过来的信息。不能操作教具、修改房间状态，当前用户也不会出现在 roomMembers 列表中。
 在加入房间后，也可以通过 WhiteRoom 的 setWritable:completionHander: 方法，切换读写模式。
 */
@property (nonatomic, assign) BOOL isWritable;

/**
 * 2.12.2 默认 false；2.12.3 默认 true，不开启笔锋。
 * 打开笔锋功能绘制的内容，需要本地客户端 2.12.2 sdk 以上才能看到。
 */
@property (nonatomic, assign) BOOL disableNewPencil;

/**
 房间进入重连的最长时间，超时后，会主动断连，并在 phaseChange 中回调。同时还会触发 fireDisconnectWithError，会返回：重连时长超出 xx 毫秒...的提示
 单位：秒。
 */
@property (nonatomic, strong) NSNumber *timeout;

@end

NS_ASSUME_NONNULL_END
