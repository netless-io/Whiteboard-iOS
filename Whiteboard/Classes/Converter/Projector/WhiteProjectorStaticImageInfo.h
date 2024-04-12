//
//  WhiteProjectorStaticImageInfo.h
//  Whiteboard
//
//  Created by xuyunshi on 2024/4/12.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteProjectorStaticImageInfo : WhiteObject

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END
