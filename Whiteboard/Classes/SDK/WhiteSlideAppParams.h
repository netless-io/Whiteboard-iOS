//
//  WhiteSlideAppParams.h
//  Whiteboard
//
//  Created by xuyunshi on 2023/3/2.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteSlideAppParams : WhiteObject

/**
 是否显示 Slide 中的错误提示
 
 - `YES`：显示。
 - `NO`：不显示 (默认)。
 */
@property (nonatomic, assign) BOOL showRenderError;

/**
 是否开启 Debug 模式 (默认 NO)。
*/
@property (nonatomic, assign) BOOL debug;

@end

NS_ASSUME_NONNULL_END
