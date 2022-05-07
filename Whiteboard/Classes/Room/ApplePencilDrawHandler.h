//
//  PencilDrawHandler.h
//  Masonry
//
//  Created by xuyunshi on 2022/5/7.
//

#import "WhiteRoom.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApplePencilDrawHandler : NSObject

@property (nonatomic, assign) BOOL drawOnlyApplePencil;

- (instancetype)initWithRoom:(WhiteRoom *)room drawOnlyPencil:(BOOL)drawOnlyPencil;

- (void)roomApplianceDidUpdate;
- (void)recoverApplianceFromTempRemove;

@end

NS_ASSUME_NONNULL_END
