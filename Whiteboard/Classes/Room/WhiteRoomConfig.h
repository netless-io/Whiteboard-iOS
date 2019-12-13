//
//  WhiteRoomConfig.h
//  WhiteSDK
//
//  Created by yleaf on 2019/3/30.
//

#import "WhiteObject.h"
#import "WhiteMemberInformation.h"
#import "WhiteCameraBound.h"
NS_ASSUME_NONNULL_BEGIN

@interface WhiteRoomConfig : WhiteObject

- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken;
- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken memberInfo:(WhiteMemberInformation * _Nullable)memberInfo  __attribute__((deprecated("memberInfo is deprecated, please use userPayload")));;
- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken userPayload:(id _Nullable)userPayload;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *roomToken;

/**
 禁止教具响应用户输入，默认 NO，即允许。
 */
@property (nonatomic, assign) BOOL disableDeviceInputs;

/**
 禁止贝塞尔曲线优化，默认 NO，即允许。
 */
@property (nonatomic, assign) BOOL disableBezier;

/**
 禁止白板响应用户操作，默认 NO，即允许。
 */
@property (nonatomic, assign) BOOL disableOperations;

/**
 禁止橡皮擦擦除所有图片，默认 NO，即允许橡皮擦擦除图片。
 */
@property (nonatomic, assign) BOOL disableEraseImage;

/**
 视野范围限制
 */
//@property (nonatomic, strong, nullable) WhiteCameraBound *cameraBound;

/**
 加入房间时，允许带入用户数据（限制：允许转换为 JSON，或者单纯的 NSString，数字 NSNumber）。
 推荐为字典
 */
@property (nonatomic, copy) id userPayload;
@property (nonatomic, copy, nullable) WhiteMemberInformation *memberInfo __attribute__((deprecated("memberInfo is deprecated, please use userPayload")));

@end

NS_ASSUME_NONNULL_END
