//
//  WhiteCameraState.h
//  Whiteboard
//
//  Created by yleaf on 2021/1/20.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/**
 描述白板内部坐标系,内部坐标系，坐标原点为初始位置的中点，X 轴正方向向右，Y 轴正方向向上。
 @since 2.11.12
 */
@interface WhiteCameraState : WhiteObject

//@property (nonatomic, strong) NSNumber *width;
//@property (nonatomic, strong) NSNumber *height;

/**
 如果房间中没有主播，第一次进入房间，初始位置应为 0
 当前 whiteboardView 中点，在 白板内部 坐标系中的坐标
 */
@property (nonatomic, strong) NSNumber *centerX;

/**
 如果房间中没有主播，第一次进入房间，初始位置应为 0
 当前 whiteboardView 中点，在 白板内部 坐标系中的坐标
 */
@property (nonatomic, strong) NSNumber *centerY;

/** 白板缩放比例，代表白板中内容被放大缩小的比例（大于 1 时，为放大；小于 1 时，为缩小） */
@property (nonatomic, strong) NSNumber *scale;

@end

NS_ASSUME_NONNULL_END
