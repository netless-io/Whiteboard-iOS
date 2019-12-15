//
//  WhiteCombinePlayer.m
//  WhiteSDK
//
//  Created by yleaf on 2019/7/11.
//

#import "WhiteCombinePlayer.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_OPTIONS(NSUInteger, PauseReason) {
    //正常播放
    PauseReasonNone                    = 0,
    //暂停，暂停原因：白板缓冲
    PauseReasonWhitePlayerBuffering    = 1 << 0,
    //暂停，暂停原因：音视频缓冲
    PauseReasonNativePlayerBuffering   = 1 << 1,
    //暂停，暂停原因：主动暂停
    PauseReasonPlayerPause             = 1 << 2,
    //初始状态，暂停，全缓冲
    PauseReasonInit                    = PauseReasonWhitePlayerBuffering | PauseReasonNativePlayerBuffering | PauseReasonPlayerPause,
};

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define DLog(...)
#endif

@interface WhiteCombinePlayer ()
@property (nonatomic, strong, readwrite) AVPlayer *nativePlayer;
@property (nonatomic, strong, readwrite) WhitePlayer *whitePlayer;

@property (nonatomic, assign, getter=isRouteChangedWhilePlaying) BOOL routeChangedWhilePlaying;
@property (nonatomic, assign, getter=isInterruptedWhilePlaying) BOOL interruptedWhilePlaying;

@property (nonatomic, assign) NSUInteger pauseReason;

@end

@implementation WhiteCombinePlayer

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserverWithPlayItem:self.nativePlayer.currentItem];
}

- (instancetype)initWithNativePlayer:(AVPlayer *)player whitePlayer:(WhitePlayer *)whitePlayer
{
    if (self = [super init]) {
        _nativePlayer = player;
        _whitePlayer = whitePlayer;
        _pauseReason = PauseReasonInit;
    }
    [self setup];
    return self;
}

- (instancetype)initWithMediaUrl:(NSURL *)mediaUrl whitePlayer:(WhitePlayer *)whitePlayer
{
    AVPlayer *videoPlayer = [AVPlayer playerWithURL:mediaUrl];
    return [self initWithNativePlayer:videoPlayer whitePlayer:whitePlayer];
}

- (void)setup
{
    [self registerAudioSessionNotification];
    [self.nativePlayer addObserver:self forKeyPath:kRateKey options:0 context:nil];
    [self.nativePlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

#pragma mark - Private Methods

/**
 并非真正播放，包含缓冲可能性

 @return video 是否处于想要播放的状态
 */
- (BOOL)videoDesireToPlay
{
    return self.nativePlayer.rate != 0;
}

- (BOOL)isLoaded:(NSArray<NSValue *> *)timeranges
{
    if ([timeranges count] == 0) {
        return NO;
    }
    CMTimeRange timerange = [[timeranges firstObject] CMTimeRangeValue];
    CMTime bufferdTime = CMTimeAdd(timerange.start, timerange.duration);
    CMTime milestone = CMTimeAdd(self.nativePlayer.currentTime, CMTimeMakeWithSeconds(5.0f, timerange.duration.timescale));
    
    if (CMTIME_COMPARE_INLINE(bufferdTime , >, milestone) && self.nativePlayer.currentItem.status == AVPlayerItemStatusReadyToPlay && !self.isInterruptedWhilePlaying && !self.isRouteChangedWhilePlaying) {
        return YES;
    }
    return NO;
}

- (BOOL)hasEnoughNativeBuffer
{
    return self.nativePlayer.currentItem.isPlaybackLikelyToKeepUp;
}

- (CMTime)itemDuration
{
    NSError *err = nil;
    if ([self.nativePlayer.currentItem.asset statusOfValueForKey:@"duration" error:&err] == AVKeyValueStatusLoaded) {
        AVPlayerItem *playerItem = [self.nativePlayer currentItem];
        NSArray *loadedRanges = playerItem.seekableTimeRanges;
        if (loadedRanges.count > 0) {
            CMTimeRange range = [[loadedRanges firstObject] CMTimeRangeValue];
            return (range.duration);
        } else {
            return (kCMTimeInvalid);
        }
    } else {
        return (kCMTimeInvalid);
    }
}

#pragma mark - Notification

- (void)registerAudioSessionNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interruption:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routeChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
#endif
}

#pragma mark - Notification

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if (notification.object == self.nativePlayer.currentItem && [self.delegate respondsToSelector:@selector(nativePlayerDidFinish)]) {
        [self.delegate nativePlayerDidFinish];
    }
}

- (void)interruption:(NSNotification *)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interruptionType = [interuptionDict[AVAudioSessionInterruptionTypeKey] integerValue];
    
    if (interruptionType == AVAudioSessionInterruptionTypeBegan && [self videoDesireToPlay]) {
        self.interruptedWhilePlaying = YES;
        [self pause];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded && self.isInterruptedWhilePlaying) {
        self.interruptedWhilePlaying = NO;
        NSInteger resume = [interuptionDict[AVAudioSessionInterruptionOptionKey] integerValue];
        if (resume == AVAudioSessionInterruptionOptionShouldResume) {
            [self play];
        }
    }
}

- (void)routeChange:(NSNotification *)notification
{
    NSDictionary *routeChangeDict = notification.userInfo;
    NSInteger routeChangeType = [routeChangeDict[AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeType == AVAudioSessionRouteChangeReasonOldDeviceUnavailable && [self videoDesireToPlay]) {
        self.routeChangedWhilePlaying = YES;
        [self pause];
    } else if (routeChangeType == AVAudioSessionRouteChangeReasonNewDeviceAvailable && self.isRouteChangedWhilePlaying) {
        self.routeChangedWhilePlaying = NO;
        [self play];
    }
}

#pragma mark - KVO
static NSString * const kRateKey = @"rate";
static NSString * const kCurrentItemKey = @"currentItem";
static NSString * const kStatusKey = @"status";
static NSString * const kPlaybackBufferEmptyKey = @"playbackBufferEmpty";
static NSString * const kPlaybackLikelyToKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const kLoadedTimeRangesKey = @"loadedTimeRanges";

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {

    if (object != self.nativePlayer.currentItem && object != self.nativePlayer) {
        return;
    }
    
    if (object == self.nativePlayer && [keyPath isEqualToString:kStatusKey]) {
        if (self.nativePlayer.status == AVPlayerStatusFailed) {
            [self pause];
            if ([self.delegate respondsToSelector:@selector(combineVideoPlayerError:)]) {
                [self.delegate combineVideoPlayerError:self.nativePlayer.error];
            }
        }
    } else if (object == self.nativePlayer && [keyPath isEqualToString:kCurrentItemKey]) {
        // 防止主动替换 CurrentItem，理论上单个Video 不会进行替换
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        AVPlayerItem *lastPlayerItem = [change objectForKey:NSKeyValueChangeOldKey];
        if (lastPlayerItem != (id)[NSNull null]) {
            @try {
                [self removeObserverWithPlayItem:lastPlayerItem];
            } @catch(id anException) {
                //do nothing, obviously it wasn't attached because an exception was thrown
            }
        }
        if (newPlayerItem != (id)[NSNull null]) {
            [self addObserverWithPlayItem:newPlayerItem];
        }

    } else if ([keyPath isEqualToString:kRateKey]) {
        if ([self.delegate respondsToSelector:@selector(combineVideoPlayStateChange:)]) {
            [self.delegate combineVideoPlayStateChange:[self videoDesireToPlay]];
        }
    } else if ([keyPath isEqualToString:kStatusKey]) {
        if (self.nativePlayer.currentItem.status == AVPlayerItemStatusFailed) {
            [self pause];
            if ([self.delegate respondsToSelector:@selector(combineVideoPlayerError:)]) {
                [self.delegate combineVideoPlayerError:self.nativePlayer.currentItem.error];
            }
        }
    } else if ([keyPath isEqualToString:kPlaybackBufferEmptyKey]) {
        if (self.nativePlayer.currentItem.isPlaybackBufferEmpty) {
            [self startNativeBuffering];
        }
    } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUpKey]) {
        if (self.nativePlayer.currentItem.isPlaybackLikelyToKeepUp) {
            [self endNativeBuffering];
        }
    } else if ([keyPath isEqualToString:kLoadedTimeRangesKey]) {
        NSArray *timeRanges = (NSArray *)change[NSKeyValueChangeNewKey];
        if ([self.delegate respondsToSelector:@selector(loadedTimeRangeChange:)]) {
            [self.delegate loadedTimeRangeChange:timeRanges];
        }
    }
}

// 推荐使用 KVOController 做 KVO 监听
- (void)addObserverWithPlayItem:(AVPlayerItem *)item
{
    [item addObserver:self forKeyPath:kStatusKey options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:kLoadedTimeRangesKey options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:kPlaybackBufferEmptyKey options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverWithPlayItem:(AVPlayerItem *)item
{
    [item removeObserver:self forKeyPath:kStatusKey];
    [item removeObserver:self forKeyPath:kLoadedTimeRangesKey];
    [item removeObserver:self forKeyPath:kPlaybackBufferEmptyKey];
    [item removeObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey];
}

#pragma mark - NativePlayer Buffering
- (void)startNativeBuffering
{
    if ([self.delegate respondsToSelector:@selector(combinePlayerStartBuffering)]) {
        [self.delegate combinePlayerStartBuffering];
    }

    DLog(@"startNativeBuffering");
    
    //加上 native 缓冲标识
    self.pauseReason = self.pauseReason | PauseReasonNativePlayerBuffering;
    
    //whitePlayer 加载 buffering 的行为，一旦开始，不会停止。所以直接暂停播放即可。
    [self pauseWhitePlayer];
}

- (void)endNativeBuffering
{
    //移除 native 缓冲标识
    self.pauseReason = self.pauseReason & ~PauseReasonNativePlayerBuffering;
    
    // whitePlayer 也不缓冲了，则调用 endBuffering
    if (self.pauseReason & ~PauseReasonWhitePlayerBuffering) {
        DLog(@"pauseReason %ld", self.pauseReason);
        if ([self.delegate respondsToSelector:@selector(combinePlayerEndBuffering)]) {
            [self.delegate combinePlayerEndBuffering];
        }
    }
    
    DLog(@"endNativeBuffering");

    //如果 whitePlayer 不处于缓冲状态，又不是暂停，则直接播放。否则不作任何事情
    if (self.pauseReason == PauseReasonNone) {
        DLog(@"playWhitePlayer");
        [self playWhitePlayer];
    }
}

#pragma mark - white player buffering
- (void)pauseForWhitePlayerBuffing
{
    //直接暂停
    [self.nativePlayer pause];
    
    if ([self.delegate respondsToSelector:@selector(combinePlayerStartBuffering)]) {
        [self.delegate combinePlayerStartBuffering];
    }
}

- (void)whitePlayerReadyToPlay
{
    
    if (!(self.pauseReason & PauseReasonNativePlayerBuffering)) {
        DLog(@"pauseReason %ld", self.pauseReason);
        if ([self.delegate respondsToSelector:@selector(combinePlayerEndBuffering)]) {
            [self.delegate combinePlayerEndBuffering];
        }
    }
    
    /*
     1. 本身已经被主动暂停，不需要播放，不做操作
     2. nativePlayer 在缓冲，则暂停 whitePlayer 等待 nativePlayer
     3. nativePlayer 可以播放，一起播放
     */
    if ((self.pauseReason & PauseReasonPlayerPause) == PauseReasonPlayerPause) {
        DLog("%ld do nothing", (long)self.pauseReason)
    } else if ((self.pauseReason & PauseReasonNativePlayerBuffering) == PauseReasonNativePlayerBuffering) {
        [self pauseWhitePlayer];
    } else {
        [self.nativePlayer play];
    }
}

#pragma mark - Play Control

- (void)playWhitePlayer
{
    [self.whitePlayer play];
}

- (void)pauseWhitePlayer
{
    [self.whitePlayer pause];
}

#pragma mark - Public Methods
- (NSTimeInterval)videoDuration;
{
    CMTime itemDurationTime = [self itemDuration];
    NSTimeInterval duration = CMTimeGetSeconds(itemDurationTime);
    if (CMTIME_IS_INVALID(itemDurationTime) || !isfinite(duration)) {
        return 0.0f;
    } else {
        return duration;
    }
}

- (void)play
{
    self.pauseReason = self.pauseReason & ~PauseReasonPlayerPause;
    [self.nativePlayer play];
    self.interruptedWhilePlaying = NO;
    self.routeChangedWhilePlaying = NO;
    
    // video 将直接播放，whitePlayer 也直接播放
    if ([self hasEnoughNativeBuffer]) {
        DLog(@"play directly");
        [self.whitePlayer play];
    }
}

- (void)pause
{
    self.pauseReason = self.pauseReason | PauseReasonPlayerPause;
    [self.nativePlayer pause];
    [self.whitePlayer pause];
}

- (void)updateWhitePlayerPhase:(WhitePlayerPhase)phase
{
    DLog(@"first updateWhitePlayerPhase %ld pauseReason:%ld", phase, self.pauseReason);
    // WhitePlay 处于缓冲状态，pauseReson 加上 whitePlayerBuffering
    if (phase == WhitePlayerPhaseBuffering || phase == WhitePlayerPhaseWaitingFirstFrame) {
        self.pauseReason = self.pauseReason | PauseReasonWhitePlayerBuffering;
        [self pauseForWhitePlayerBuffing];
    }
    // 进入暂停状态，whitePlayer 已经完成缓冲，移除 whitePlayerBufferring
    else if (phase == WhitePlayerPhasePause || phase == WhitePlayerPhasePlaying) {
        self.pauseReason = self.pauseReason & ~PauseReasonWhitePlayerBuffering;
        [self whitePlayerReadyToPlay];
    }
    DLog(@"end updateWhitePlayerPhase %ld pauseReason:%ld", phase, self.pauseReason);
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler
{
    NSTimeInterval seekTime = CMTimeGetSeconds(time);
    [self.whitePlayer seekToScheduleTime:seekTime];
    DLog(@"seekTime: %f", seekTime);
    __weak typeof(self)weakSelf = self;
    [self.nativePlayer seekToTime:time completionHandler:^(BOOL finished) {
        NSTimeInterval realTime = CMTimeGetSeconds(weakSelf.nativePlayer.currentItem.currentTime);
        DLog(@"realTime: %f", realTime);
        // AVPlayer 的 seek 不完全准确, seek 完以后，根据 native 的真实时间，重新 seek
        [weakSelf.whitePlayer seekToScheduleTime:realTime];
        if (finished) {
            completionHandler(finished);
        }
    }];
}

@end
