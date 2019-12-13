//
//  WhiteImageInformation.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/15.
//

#import "WhiteObject.h"
#import <UIKit/UIKit.h>


@interface WhiteImageInformation : WhiteObject

@property (nonatomic, copy) NSString *uuid;
/** 图片中点，在白板上的坐标，白板坐标原点为初始状态下，WhiteboardView 中点。 */
@property (nonatomic, assign) CGFloat centerX;
/** 图片中点，在白板上的坐标，白板坐标原点为初始状态下，WhiteboardView 中点。*/
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end
