//
//  WhitePanEvent.h
//  WhiteSDK
//
//  Created by yleaf on 2019/1/28.
//

#import "WhiteObject.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 白板点坐标。 */
@interface WhitePanEvent : WhiteObject

/** 白板上点的 X 坐标。 */
@property (nonatomic, assign) CGFloat x;
/** 白板上点的 Y 坐标。 */
@property (nonatomic, assign) CGFloat y;

@end

NS_ASSUME_NONNULL_END
