//
//  WhiteSDK+Private.h
//  WhiteSDK
//
//  Created by yleaf on 2019/12/10.
//

#import "WhiteSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteSDK ()
@property (nonatomic, weak) WhiteBoardView *bridge;
@property (nonatomic, strong) WhiteSdkConfiguration *config;
@property (nonatomic, weak, nullable) id<WhiteCommonCallbackDelegate> commonCallbackDelegate;
- (void)whiteBindCommonCallback;
@end

NS_ASSUME_NONNULL_END
