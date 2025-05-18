//
//  WhiteAudioPcmDataDelegate.m
//  Whiteboard
//
//  Created by xuyunshi on 2024/9/30.
//

#import "WhiteAudioPcmDataDelegate.h"

@interface WhiteAudioPcmDataBrige ()

@property (nonatomic, weak) WhiteBoardView *bridge;
@property (nonatomic, weak, nullable) id<WhiteAudioPcmDataDelegate> delegate;

@end

@implementation WhiteAudioPcmDataBrige
- (instancetype)initWithBridge:(WhiteBoardView *)bridge delegate:(id<WhiteAudioPcmDataDelegate>)delegate {
    if (self = [super init]) {
        self.bridge = bridge;
        self.delegate = delegate;
    }
    return self;
}

- (void)pcmDataUpdate:(NSArray *)int16Array {
    if ([self.delegate respondsToSelector:@selector(pcmDataUpdate:)]) {
        [self.delegate pcmDataUpdate:int16Array];
    }
}

@end
