//
//  WhiteTeleBoxManagerThemeConfig.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/20.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteTeleBoxManagerThemeConfig : WhiteObject

@property (nonatomic, copy) NSString *managerContainerBackground;
@property (nonatomic, copy) NSString *managerStageBackground;
@property (nonatomic, copy) NSString *managerStageShadow;
@property (nonatomic, copy) NSString *boxContainerBackground;
@property (nonatomic, copy) NSString *boxStageBackground;
@property (nonatomic, copy) NSString *boxStageShadow;
@property (nonatomic, copy) NSString *boxColor;
@property (nonatomic, copy) NSString *boxBorder;
@property (nonatomic, copy) NSString *boxShadow;
@property (nonatomic, copy) NSString *boxFooterColor;
@property (nonatomic, copy) NSString *boxFooterBackground;
@property (nonatomic, copy) NSString *titlebarColor;
@property (nonatomic, copy) NSString *titlebarBackground;
@property (nonatomic, copy) NSString *titlebarBorderBottom;
@property (nonatomic, copy) NSString *titlebarTabColor;
@property (nonatomic, copy) NSString *titlebarTabFocusColor;
@property (nonatomic, copy) NSString *titlebarTabBackground;
@property (nonatomic, copy) NSString *titlebarTabDividerColor;
@property (nonatomic, copy) NSString *collectorBackground;
@property (nonatomic, copy) NSString *collectorShadow;
@property (nonatomic, copy) NSString *titlebarIconMinimize;
@property (nonatomic, copy) NSString *titlebarIconMaximize;
@property (nonatomic, copy) NSString *titlebarIconMaximizeActive;
@property (nonatomic, copy) NSString *titlebarIconClose;

@end

NS_ASSUME_NONNULL_END
