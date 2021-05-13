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

/** 互动白板实时房间的工具状态（只读）。初始工具为pencil，无默认值。 */
@interface WhiteReadonlyMemberState : WhiteObject

/** 互动白板实时房间内当前使用的工具名称。初始工具为pencil，无默认值。 */
@property (nonatomic, copy, readonly) WhiteApplianceNameKey currentApplianceName;
/** 线条颜色，为 RGB 格式，例如，(0, 0, 255) 表示蓝色。 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *strokeColor;
/** 线条粗细。 */
@property (nonatomic, strong, readonly, nullable) NSNumber *strokeWidth;
/** 字体大小。 */
@property (nonatomic, strong, readonly, nullable) NSNumber *textSize;
/** 当教具为 `Shape` 时，所选定的 shape 图形。
 @since 2.12.24 */
@property (nonatomic, strong, readonly, nullable) WhiteApplianceShapeTypeKey shapeType;
@end

#pragma mark - MemberState

/** 互动白板实时房间的工具状态。初始工具为pencil，无默认值。 */
@interface WhiteMemberState : WhiteReadonlyMemberState
/** 互动白板实时房间内当前使用的工具名称。初始工具为pencil，无默认值。 */
@property (nonatomic, copy, readwrite, nullable) WhiteApplianceNameKey currentApplianceName;
/** 线条颜色，为 RGB 格式，例如，(0, 0, 255) 表示蓝色。 */
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *strokeColor;
/** 线条粗细。 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *strokeWidth;
/** 字体大小。 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *textSize;
@end

NS_ASSUME_NONNULL_END
