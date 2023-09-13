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

/**
 是否可以通过点击 ppt 画面执行下一步功能, (默认 YES)。
*/
@property (nonatomic, assign) BOOL enableGlobalClick;

@end

NS_ASSUME_NONNULL_END
