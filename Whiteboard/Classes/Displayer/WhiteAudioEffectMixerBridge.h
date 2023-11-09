//
//  WhiteAudioEffectMixerBridge.h
//  Whiteboard
//
//  Created by xuyunshi on 2023/11/8.
//

#import <Foundation/Foundation.h>
#import "WhiteBoardView.h"

NS_ASSUME_NONNULL_BEGIN

/*
* volume: 0-100.
* pos: The playback position (ms) of the audio effect file.
* All returns without other declare means:
     * @return * 0: Success.
     * < 0: Failure.
 */
@protocol WhiteAudioEffectMixerBridgeDelegate <NSObject>

// Returns volume.
- (double)getEffectsVolume;

- (int)setEffectsVolume:(double)volume;

- (int)setVolumeOfEffect:(int)soundId withVolume:(double)volume;

- (int)playEffect:(int)soundId filePath:(NSString * _Nullable)filePath loopCount:(int)loopCount pitch:(double)pitch pan:(double)pan gain:(double)gain publish:(BOOL)publish startPos:(int)startPos;

- (int)stopEffect:(int)soundId;

- (int)stopAllEffects;

- (int)preloadEffect:(int)soundId filePath:(NSString * _Nullable)filePath;

- (int)unloadEffect:(int)soundId;

- (int)pauseEffect:(int)soundId;

- (int)pauseAllEffects;

- (int)resumeEffect:(int)soundId;

- (int)resumeAllEffects;

- (int)setEffectPosition:(int)soundId pos:(NSInteger)pos;

// Returns pos.
- (int)getEffectCurrentPosition:(int)soundId;

@end

@interface WhiteAudioEffectMixerBridge : NSObject

- (instancetype)initWithBridge:(WhiteBoardView *)bridge delegate:(id<WhiteAudioEffectMixerBridgeDelegate>)delegate;

- (void)setEffectFinished:(NSInteger)soundId;

@end

NS_ASSUME_NONNULL_END
