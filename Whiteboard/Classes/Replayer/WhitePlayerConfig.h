//
//  WhitePlayerConfig.h
//  WhiteSDK
//
//  Created by yleaf on 2019/3/1.
//

#import "WhiteObject.h"
#import "WhiteCameraBound.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhitePlayerConfig : WhiteObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRoom:(NSString *)roomUuid roomToken:(NSString *)roomToken;

/** 房间UUID，目前必须要有 */
@property (nonatomic, copy) NSString *room;

/** 房间token，目前必须要有 */
@property (nonatomic, copy) NSString *roomToken;

/** 分片 ID，可以跳转至特定的房间位置，目前可以不关心。 */
@property (nonatomic, copy, nullable) NSString *slice;

/** 传入对应的UTC 时间戳(秒)，如果正确，则会在对应的位置开始播放。 */
@property (nonatomic, strong, nullable) NSNumber *beginTimestamp;

/** 传入持续时间（秒），当播放到对应位置时，就不会再播放。如果不设置，则从开始时间，一直播放到房间结束。 */
@property (nonatomic, strong, nullable) NSNumber *duration;

/** m3u8地址，暂不支持显示视频画面。设置后，会与白板同步播放 */
@property (nonatomic, strong, nullable) NSString *audioUrl;

/** 视野范围 */
//@property (nonatomic, strong, nullable) WhiteCameraBound *cameraBound;

@end

NS_ASSUME_NONNULL_END
