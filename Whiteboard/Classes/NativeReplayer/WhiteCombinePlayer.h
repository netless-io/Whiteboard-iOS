//
//  WhiteCombinePlayer.h
//  WhiteSDK
//
//  Created by yleaf on 2019/7/11.
//

#import <Foundation/Foundation.h>
#import "WhiteSDK+Replayer.h"
#import <AVFoundation/AVFoundation.h>
#import "WhiteVideoView.h"
#import "WhiteSliderView.h"

NS_ASSUME_NONNULL_BEGIN


/// TODO: native player 隔离，支持第三方 player
@protocol WhiteNativePlayerProtocol <NSObject>

- (void)play;
- (void)pause;
- (BOOL)desireToPlay;
- (BOOL)hasEnoughBuffer;
- (CMTime)itemDuration;

@end

@protocol WhiteCombineDelegate <NSObject>

@optional

/**
 进入缓冲状态，WhitePlayer，NativePlayer 任一进入缓冲，都会回调。
 */
- (void)combinePlayerStartBuffering;

/**
 结束缓冲状态，WhitePlayer，NativePlayer 全部完成缓冲，才会回调。
 */
- (void)combinePlayerEndBuffering;

/**
 NativePlayer 播放结束
 */
- (void)nativePlayerDidFinish;

/**
 NativePlayer 播放状态变化，由播放变停止，或者由暂停变播放

 @param isPlaying 是否正在播放
 */
- (void)combineVideoPlayStateChange:(BOOL)isPlaying;


/**
 videoPlayer 无法进行播放，需要重新创建 CombinePlayer 进行播放

 @param error 错误原因
 */
- (void)combineVideoPlayerError:(NSError *)error;

/**
 NativePlayer 缓冲进度更新

 @param loadedTimeRanges 数组内元素为 CMTimeRange，使用 CMTimeRangeValue 获取 CMTimeRange，是 video 已经加载了的缓存
 */
- (void)loadedTimeRangeChange:(NSArray<NSValue *> *)loadedTimeRanges;
@end


#pragma mark - WhiteCombinePlayer

/**
 同步系统 AVPlayer 与 WhitePlayer 的播放状态。某一个进入缓冲状态，另一个则暂停等待。
 */
@interface WhiteCombinePlayer : NSObject

@property (nonatomic, strong, readonly) AVPlayer *nativePlayer;
@property (nonatomic, strong, readonly) WhitePlayer *whitePlayer;

@property (nonatomic, weak) id<WhiteCombineDelegate> delegate;

- (instancetype)initWithNativePlayer:(AVPlayer *)player whitePlayer:(WhitePlayer *)replayer;
- (instancetype)initWithMediaUrl:(NSURL *)mediaUrl whitePlayer:(WhitePlayer *)replayer;

- (NSTimeInterval)videoDuration;

- (void)play;
- (void)pause;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 当 whiteplayer 连接缓冲状态发生变化，会主动调用 whiteplayer 的 WhitePlayerEventDelegate 中 - (void)phaseChanged:(WhitePlayerPhase)phase 方法，
 此时需要开发者主动调用该方法，将该状态同步给 WhiteCombinePlayer
 */
- (void)updateWhitePlayerPhase:(WhitePlayerPhase)phase;

@end

NS_ASSUME_NONNULL_END
