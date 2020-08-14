//
//  AudioMixerBridge.h
//  Whiteboard
//
//  Created by yleaf on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import <WhiteBoardView.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WhiteAudioMixerBridgeDelegate <NSObject>

- (void)startAudioMixing:(NSString *)filePath loopback:(BOOL)loopback replace:(BOOL)replace cycle:(NSInteger)cycle;

- (void)stopAudioMixing;

- (void)setAudioMixingPosition:(NSInteger)position;

@end

@interface WhiteAudioMixerBridge : NSObject

- (instancetype)initWithBridge:(WhiteBoardView *)bridge deletegate:(id<WhiteAudioMixerBridgeDelegate>)delegate;

- (void)setMediaState:(NSInteger)stateCode errorCode:(NSInteger)errorCode;

@end

NS_ASSUME_NONNULL_END
