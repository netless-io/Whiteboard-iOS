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

- (int)playEffect:(int)soundId filePath:(NSString * _Nullable)filePath loopCount:(int)loopCount pitch:(double)pitch pan:(double)pan gain:(double)gain publish:(BOOL)publish startPos:(int)startPos identifier:(NSString *)identifier;

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

// Returns nothing. Callback with `rtcEngine:didRequest:error`.
- (int)getEffectDuration:(NSString *)filePath;

@end

/**
 用 Agora RTC SDK 的 `PlayEffect` 方法和白板 SDK 进行混音。

 当用户同时使用音视频功能和互动白板，且在互动白板中展示的动态 PPT 包含音频文件时，可能遇到以下问题：

 - 播放 PPT 内的音频时声音很小。
 - 播放 PPT 内的音频时有回声。

 为解决上述问题，你可以使用该类以调用 RTC SDK 的 `PlayEffect` 方法播放动态 PPT 中的音频文件。

 **Note:** 该类基于 Agora RTC SDK 的 `PlayEffect` 方法设计，如果你使用的实时音视频 SDK 不是 Agora RTC SDK，但也具有 `PlayEffect` 接口和 `PlayEffect` 状态回调，你也可以调用该类。
 */
@interface WhiteAudioEffectMixerBridge : NSObject

- (instancetype)initWithBridge:(WhiteBoardView *)bridge delegate:(id<WhiteAudioEffectMixerBridgeDelegate>)delegate;

/**
 设置音乐播放结束
 
 @param soundId 播放的音乐 id；
 */
- (void)setEffectFinished:(NSInteger)soundId;

/**
 设置音乐文件播放状态。

 你需要在 Agora RTC SDK 触发的 `rtcEngineDidAudioEffectStateChanged` 回调中调用该方法，将音乐文件播放状态传递给白板中的 PPT。

 PPT 根据收到的音频播放状态判断是否显示画面，以确保音画同步。

 **Note:** 如果你使用的实时音视频 SDK 没有该状态回调方法，会导致播放的 PPT 音画不同步。

 @param soundId 播放的音乐 id；
 @param state 音乐文件播放状态：

 - 810: 开始播放音乐。
 - 811: 音乐被暂停。
 - 813: 音乐被停止。
 - 814: 音乐播放失败。
*/
- (void)setEffectSoundId:(NSInteger)soundId stateChanged:(NSInteger)state;

/**
 更新 AudioEffect Duration.
 
 @param filePath 音乐地址；
 @param duration 音乐长度；
 */
- (void)setEffectDurationUpdate:(NSString *)filePath duration:(NSInteger)duration;

@end

NS_ASSUME_NONNULL_END
