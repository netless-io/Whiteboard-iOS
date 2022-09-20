//
//  PencilDrawHandler.h
//  Masonry
//
//  Created by xuyunshi on 2022/5/7.
//

#import "WhiteRoom.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApplePencilDrawHandler : NSObject

// 设置该值之后，如果有一些被临时切换的 appliance 都会被设置回去
@property (nonatomic, assign) BOOL drawOnlyApplePencil;

- (instancetype)initWithRoom:(WhiteRoom *)room drawOnlyPencil:(BOOL)drawOnlyPencil;

- (void)roomApplianceDidManualUpdate;
- (void)recoverApplianceFromTempRemove;

@end

NS_ASSUME_NONNULL_END
