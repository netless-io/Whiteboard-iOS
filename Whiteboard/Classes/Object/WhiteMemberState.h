//
//  MemberState.h
//  WhiteSDK
//
//  Created by leavesster on 2018/8/14.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ApplianceName

typedef NSString * WhiteStrokeType NS_STRING_ENUM;

extern WhiteStrokeType const WhiteStrokeTypeNormal;
extern WhiteStrokeType const WhiteStrokeTypeStroke;
extern WhiteStrokeType const WhiteStrokeTypeDotted;
extern WhiteStrokeType const WhiteStrokeTypeLongDotted;

/** 白板绘图工具。 */
typedef NSString * WhiteApplianceNameKey NS_STRING_ENUM;
/** 点击工具，无任何作用。 */
extern WhiteApplianceNameKey const ApplianceClicker;
/** 铅笔。 */
extern WhiteApplianceNameKey const AppliancePencil;
/** 选择工具。 */
extern WhiteApplianceNameKey const ApplianceSelector;
/** 文字工具。 */
extern WhiteApplianceNameKey const ApplianceText;
/** 椭圆工具。 */
extern WhiteApplianceNameKey const ApplianceEllipse;
/** 矩形工具。 */
extern WhiteApplianceNameKey const ApplianceRectangle;
/** 橡皮工具。 */
extern WhiteApplianceNameKey const ApplianceEraser;
/** 橡皮工具（用来擦除铅笔笔迹的局部）该工具只对 NewPencil 有效*/
extern WhiteApplianceNameKey const AppliancePencilEraser;
/** 直线工具。 */
extern WhiteApplianceNameKey const ApplianceStraight;
/** 箭头工具。 */
extern WhiteApplianceNameKey const ApplianceArrow;
/** 抓手工具。 */
extern WhiteApplianceNameKey const ApplianceHand;
/** 激光笔工具。 */
extern WhiteApplianceNameKey const ApplianceLaserPointer;
/** 激光画笔工具，该教具仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时可用。 */
extern WhiteApplianceNameKey const ApplianceLaserPen;
/** 图形工具，需要设置 `ShapeType` 属性，如果不设置，则默认设置为三角形。
 @since 2.12.24 */
extern WhiteApplianceNameKey const ApplianceShape;

#pragma mark - ShapeKey

/** 图形形状。 */
typedef NSString * WhiteApplianceShapeTypeKey NS_STRING_ENUM;
/** 三角形。
 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypeTriangle;
/** 菱形。
 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypeRhombus;
/** 五角星。
 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypePentagram;
/** 对话气泡。
 @since 2.12.24  */
extern WhiteApplianceShapeTypeKey const ApplianceShapeTypeSpeechBalloon;

#pragma mark - ReadonlyMemberState

/** 互动白板实时房间的工具状态（只读）。初始工具为pencil，无默认值。 */
@interface WhiteReadonlyMemberState : WhiteObject

/** 互动白板实时房间内当前使用的工具名称。初始工具为pencil，无默认值。 */
@property (nonatomic, copy, readonly) WhiteApplianceNameKey currentApplianceName;
@property (nonatomic, copy, readonly) WhiteStrokeType strokeType;
/** 线条颜色，为 RGB 格式，例如，(0, 0, 255) 表示蓝色。 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *strokeColor;
/** 线条粗细。 */
@property (nonatomic, strong, readonly, nullable) NSNumber *strokeWidth;
/** 文本颜色，为 RGB 格式，例如，(0, 0, 255) 表示蓝色。 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *textColor;
/** 字体大小。 */
@property (nonatomic, strong, readonly, nullable) NSNumber *textSize;
/** 局部橡皮擦大小。 取值范围 1-3  */
@property (nonatomic, strong, readonly, nullable) NSNumber *pencilEraserSize;
/** 当教具为 `Shape` 时，所选定的 shape 图形。
 @since 2.12.24 */
@property (nonatomic, strong, readonly, nullable) WhiteApplianceShapeTypeKey shapeType;

/** 线框透明度，仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时有效。*/
@property (nonatomic, strong, readonly, nullable) NSNumber *strokeOpacity;
/** 填充样式 ，仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时有效。*/
@property (nonatomic, copy, readonly, nullable) NSArray<NSNumber *> *fillColor;
/** 填充透明度，仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时有效。*/
@property (nonatomic, strong, readonly, nullable) NSNumber *fillOpacity;
@end

#pragma mark - MemberState

/** 互动白板实时房间的工具状态。初始工具为pencil，无默认值。 */
@interface WhiteMemberState : WhiteReadonlyMemberState
/** 互动白板实时房间内当前使用的工具名称。初始工具为pencil，无默认值。 */
@property (nonatomic, copy, readwrite, nullable) WhiteApplianceNameKey currentApplianceName;
@property (nonatomic, copy, readwrite, nullable) WhiteStrokeType strokeType;
/** 线条颜色，为 RGB 格式，例如，(0, 0, 255) 表示蓝色。 */
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *strokeColor;
/** 线条粗细。 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *strokeWidth;
/** 文本颜色，为 RGB 格式，例如，(0, 0, 255) 表示蓝色。 */
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *textColor;
/** 字体大小。 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *textSize;
/** 局部橡皮擦大小。 取值范围 1-3  */
@property (nonatomic, strong, readwrite, nullable) NSNumber *pencilEraserSize;
/**
 开启后可以在文字教具下直接选择编辑文字。NSNumber取值为 bool 类型。
 默认为 NO 。
 */
@property (nonatomic, assign, readwrite, nullable) NSNumber *textCanSelectText;
/**
 开启后可以在画笔教具下画虚线。NSNumber取值为 bool 类型。
 该功能要求设置 `disableNewPencil` 为 NO。
 默认为 NO 。
 */
@property (nonatomic, assign, readwrite, nullable) NSNumber *dottedLine;
/**
 当 currentApplianceName 为 Shape 时，所选定的 shape 图形；
 如果只设置 currentApplianceName 为 shape，iOS 端会默认设置为三角形
 @since 2.12.24
 */
@property (nonatomic, strong, readwrite, nullable) WhiteApplianceShapeTypeKey shapeType;

/** 线框透明度 ，仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时有效。*/
@property (nonatomic, assign, readwrite, nullable) NSNumber *strokeOpacity;
/** 填充样式 ，仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时有效。*/
@property (nonatomic, copy, readwrite, nullable) NSArray<NSNumber *> *fillColor;
/** 填充透明度 ，仅在 WhiteSdkConfiguration.enableAppliancePlugin 启用时有效。*/
@property (nonatomic, assign, readwrite, nullable) NSNumber *fillOpacity;

@end

NS_ASSUME_NONNULL_END
