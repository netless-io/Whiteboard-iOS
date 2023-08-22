//
//  WhiteAppSyncAttributes.h
//  Whiteboard
//
//  Created by xuyunshi on 2023/8/23.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

/** 多窗口模式下，插件属性*/
@interface WhiteAppSyncAttributes : WhiteObject

/** 插件类型 */
@property (nonatomic, copy, readonly) NSString *kind;
/** 插件标题 */
@property (nonatomic, copy, readonly) NSString *title;
/** 插件参数 */
@property (nonatomic, copy, readonly) NSDictionary *options;
/** 插件可选数据源 */
@property (nonatomic, copy, readonly, nullable) NSString *src;
/** 插件可选状态 */
@property (nonatomic, copy, readonly) NSDictionary *state;


@end

NS_ASSUME_NONNULL_END
