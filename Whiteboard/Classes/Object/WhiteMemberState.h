//
//  MemberState.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/14.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ApplianceName

typedef NSString * WhiteApplianceNameKey NS_STRING_ENUM;

extern WhiteApplianceNameKey const AppliancePencil;
extern WhiteApplianceNameKey const ApplianceSelector;
extern WhiteApplianceNameKey const ApplianceText;
extern WhiteApplianceNameKey const ApplianceEllipse;
extern WhiteApplianceNameKey const ApplianceRectangle;
extern WhiteApplianceNameKey const ApplianceEraser;
/** 直线工具 */
extern WhiteApplianceNameKey const ApplianceStraight;
/** 箭头工具 */
extern WhiteApplianceNameKey const ApplianceArrow;
/** 抓手工具 */
extern WhiteApplianceNameKey const ApplianceHand;
/** 激光笔工具 */
extern WhiteApplianceNameKey const ApplianceLaserPointer;
/** 图形工具，需要指定 WhiteMemberState 中的 ShapeType 属性；如果不指定，iOS 端，会默认设置为三角形 @since 2.12.24 */
extern WhiteApplianceNameKey const ApplianceShape;

#pragma mark - ShapeKey

typedef NSString * WhiteApplianceShapeTypeKey NS_STRING_ENUM;
/** Shape 图形性状：三角形 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypeTriangle;
/** Shape 图形性状：菱形 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypeRhombus;
/** Shape 图形性状：五角星 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypePentagram;
/** Shape 图形性状：说话泡泡 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypeSpeechBalloon;

#pragma mark - ReadonlyMemberState

@interface WhiteReadonlyMemberState : WhiteObject

/** 教具，初始教具为pencil */
@property (nonatomic, copy, readonly) WhiteApplianceNameKey currentApplianceName;
/** 传入格式为[@(0-255),@(0-255),@(0-255)]的RGB */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *strokeColor;
/** 画笔粗细 */
@property (nonatomic, strong, readonly, nullable) NSNumber *strokeWidth;
/** 字体大小 */
@property (nonatomic, strong, readonly, nullable) NSNumber *textSize;
/** 当教具为 Shape 时，所选定的 shape 图形 @since 2.12.24 */
@property (nonatomic, strong, readonly, nullable) WhiteApplianceShapeTypeKey shapeType;
@end

#pragma mark - MemberState

/** 修改用户 WhiteMemberState 时，所用的类；不需要修改的部分，不进行设置即可 */
@interface WhiteMemberState : WhiteReadonlyMemberState

/** 教具，初始教具为pencil，不修改时，可以不填 */
@property (nonatomic, copy, readwrite, nullable) WhiteApplianceNameKey currentApplianceName;
/** 传入格式为[@(0-255),@(0-255),@(0-255)]的RGB，均为整型。 */
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *strokeColor;
/** 画笔粗细 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *strokeWidth;
/** 字体大小 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *textSize;
/**
 当 currentApplianceName 为 Shape 时，所选定的 shape 图形；
 如果只设置 currentApplianceName 为 shape，iOS 端会默认设置为三角形
 @since 2.12.24
 */
@property (nonatomic, strong, readwrite, nullable) WhiteApplianceShapeTypeKey shapeType;

@end

NS_ASSUME_NONNULL_END
