//
//  WhiteAudioPcmDataDelegate.h
//  Whiteboard
//
//  Created by xuyunshi on 2024/9/30.
//

#import <Foundation/Foundation.h>
#import "WhiteBoardView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WhiteAudioPcmDataDelegate <NSObject>

- (void)pcmDataUpdate: (NSArray<NSNumber *> *)int16Array;

@end


@interface WhiteAudioPcmDataBrige : NSObject

- (instancetype)initWithBridge:(WhiteBoardView *)bridge delegate:(id<WhiteAudioPcmDataDelegate>)delegate;
    
- (void)pcmDataUpdate: (NSArray *)int16Array;

@end

NS_ASSUME_NONNULL_END
