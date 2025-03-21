//
//  MemberState.m
//  WhiteSDK
//
//  Created by leavesster on 2018/8/14.
//

#import "WhiteMemberState.h"

WhiteStrokeType const WhiteStrokeTypeNormal = @"Normal";
WhiteStrokeType const WhiteStrokeTypeStroke = @"Stroke";
WhiteStrokeType const WhiteStrokeTypeDotted = @"Dotted";
WhiteStrokeType const WhiteStrokeTypeLongDotted = @"LongDotted";

WhiteApplianceNameKey const ApplianceClicker = @"clicker";
WhiteApplianceNameKey const AppliancePencil = @"pencil";
WhiteApplianceNameKey const ApplianceSelector = @"selector";
WhiteApplianceNameKey const ApplianceText = @"text";
WhiteApplianceNameKey const ApplianceEllipse = @"ellipse";
WhiteApplianceNameKey const ApplianceRectangle = @"rectangle";
WhiteApplianceNameKey const ApplianceEraser = @"eraser";
WhiteApplianceNameKey const AppliancePencilEraser = @"pencilEraser";
WhiteApplianceNameKey const ApplianceStraight = @"straight";
WhiteApplianceNameKey const ApplianceArrow = @"arrow";
WhiteApplianceNameKey const ApplianceHand = @"hand";
WhiteApplianceNameKey const ApplianceLaserPointer = @"laserPointer";
WhiteApplianceNameKey const ApplianceShape = @"shape";
WhiteApplianceNameKey const ApplianceLaserPen = @"laserPen";

WhiteApplianceShapeTypeKey const ApplianceShapeTypeTriangle = @"triangle";
/** Shape 图形性状：菱形 */
WhiteApplianceShapeTypeKey const ApplianceShapeTypeRhombus = @"rhombus";
/** Shape 图形性状：五角星 */
WhiteApplianceShapeTypeKey const ApplianceShapeTypePentagram = @"pentagram";
/** Shape 图形性状：说话泡泡 */
WhiteApplianceShapeTypeKey const ApplianceShapeTypeSpeechBalloon = @"speechBalloon";


@interface WhiteReadonlyMemberState ()
@property (nonatomic, copy) WhiteApplianceNameKey currentApplianceName;
@property (nonatomic, copy) WhiteStrokeType strokeType;
@property (nonatomic, copy) NSArray<NSNumber *> *strokeColor;
@property (nonatomic, strong) NSNumber *strokeWidth;
@property (nonatomic, copy) NSArray<NSNumber *> *textColor;
@property (nonatomic, strong) NSNumber *textSize;
@property (nonatomic, strong) NSNumber *pencilEraserSize;
@property (nonatomic, strong) WhiteApplianceShapeTypeKey shapeType;

@property (nonatomic, strong) NSNumber *strokeOpacity;
@property (nonatomic, copy) NSArray<NSNumber *> *fillColor;
@property (nonatomic, strong) NSNumber *fillOpacity;
@end

@implementation WhiteReadonlyMemberState

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"strokeColor" : [NSNumber class], @"textColor" : [NSNumber class]};
}

- (void)setStrokeColor:(NSArray<NSNumber *> *)newColor
{
    NSMutableArray *IntArray = [NSMutableArray arrayWithCapacity:newColor.count];
    for (NSNumber *n in newColor) {
        //fix issue: iOS 10 rgb css don's support float
        [IntArray addObject:[NSNumber numberWithInteger:[n integerValue]]];
    }
    _strokeColor = [IntArray copy];
}

- (void)setTextColor:(NSArray<NSNumber *> *)textColor {
  NSMutableArray *IntArray = [NSMutableArray arrayWithCapacity:textColor.count];
  for (NSNumber *n in textColor) {
      //fix issue: iOS 10 rgb css don's support float
      [IntArray addObject:[NSNumber numberWithInteger:[n integerValue]]];
  }
  _textColor = [IntArray copy];
}

@end

@implementation WhiteMemberState
@dynamic currentApplianceName;
@dynamic strokeType;
@dynamic strokeColor;
@dynamic textColor;
@dynamic strokeWidth;
@dynamic textSize;
@dynamic shapeType;
@dynamic pencilEraserSize;

@dynamic strokeOpacity;
@dynamic fillColor;
@dynamic fillOpacity;

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"strokeColor" : [NSNumber class], @"textColor" : [NSNumber class]};
}

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic
{
    // 当用户设置为 shape 时，必须存在 shapeType，如果不存在，web 端会进入异常流程。
    // 在传给 webView 时，检查该情况，
    if ([dic[@"currentApplianceName"] isEqualToString:ApplianceShape] && !dic[@"shapeType"]) {
        dic[@"shapeType"] = ApplianceShapeTypeTriangle;
    }
    return YES;
}

@end
