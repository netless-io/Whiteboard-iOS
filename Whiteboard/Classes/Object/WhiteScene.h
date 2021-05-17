//
//  WhiteScene.h
//  WhiteSDK
//
//  Created by yleaf on 2019/1/11.
//

#import "WhiteObject.h"
#import "WhitePptPage.h"
NS_ASSUME_NONNULL_BEGIN

@interface WhiteScene : WhiteObject

- (instancetype)init;
- (instancetype)initWithName:(nullable NSString *)name ppt:(nullable WhitePptPage *)ppt;

/** 通过 WhiteRoom 的 moveScene API 才可以改名。 */
@property (nonatomic, copy, readonly) NSString *name;
/**
 
 */
@property (nonatomic, assign, readonly) NSInteger componentsCount __deprecated_msg("this property is always 0");
@property (nonatomic, strong, readonly, nullable) WhitePptPage *ppt;
@end

NS_ASSUME_NONNULL_END
