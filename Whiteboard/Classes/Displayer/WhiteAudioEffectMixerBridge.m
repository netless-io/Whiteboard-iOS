//
//  WhiteAudioEffectMixerBridge.m
//  Whiteboard
//
//  Created by xuyunshi on 2023/11/8.
//

#import "WhiteAudioEffectMixerBridge.h"
#import <AVFoundation/AVAudioSession.h>

typedef void (^JSNumberCallback)(NSNumber * _Nullable result,BOOL complete);

@interface WhiteAudioEffectMixerBridge ()

@property (nonatomic, weak) WhiteBoardView *bridge;
@property (nonatomic, weak, nullable) id<WhiteAudioEffectMixerBridgeDelegate> delegate;

@end

@implementation WhiteAudioEffectMixerBridge
{
  BOOL _debugLog;
  
}

- (instancetype)initWithBridge:(WhiteBoardView *)bridge delegate:(id<WhiteAudioEffectMixerBridgeDelegate>)delegate {
    if (self = [super init]) {
        self.bridge = bridge;
        self.delegate = delegate;
        _debugLog = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRouteChangedNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
    return self;
}

- (void)setEffectFinished:(NSInteger)soundId {
    [self.bridge callHandler:@"rtc.setEffectFinished" arguments:@[@(soundId)]];
}

- (void)setEffectSoundId:(NSInteger)soundId stateChanged:(NSInteger)state {
    [self.bridge callHandler:@"rtc.audioEffectCallback" arguments:@[@(soundId), @(state)]];
}

- (void)setEffectDurationUpdate:(NSString *)filePath duration:(NSInteger)duration {
    [self.bridge callHandler:@"rtc.effectDurationCallback" arguments:@[filePath, @(duration)]];
}

- (void)receiveRouteChangedNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    if (userInfo) {
        int reason = [userInfo[AVAudioSessionRouteChangeReasonKey] intValue];
        if (reason == AVAudioSessionRouteChangeReasonCategoryChange) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(resumeAllAudioInterruptByAudioSessionChanged) object:nil];
                    [weakSelf performSelector:@selector(resumeAllAudioInterruptByAudioSessionChanged) withObject:nil afterDelay:0.5];
                }
            });
        }
    }
}

- (void)resumeAllAudioInterruptByAudioSessionChanged {
    [self.bridge evaluateJavaScript:@"window.postMessage({name: 'resumeAllAudioInterruptByAudioSessionChanged'})" completionHandler:^(id _Nullable r, NSError * _Nullable error) {}];
}

// Returns volume.
- (void)getEffectsVolume:(id)args completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(getEffectsVolume)]) {
        double res = [self.delegate getEffectsVolume];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)setEffectsVolume:(NSNumber *)volume completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(setEffectsVolume:)]) {
        int res = [self.delegate setEffectsVolume:[volume doubleValue]];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)setVolumeOfEffect:(NSDictionary *)params completionHandler:(JSNumberCallback)completionHandler {
    NSNumber *soundId = params[@"soundId"];
    NSNumber *volume = params[@"volume"];
    if ([self.delegate respondsToSelector:@selector(setVolumeOfEffect:withVolume:)]) {
        int res = [self.delegate setVolumeOfEffect:[soundId intValue] withVolume:[volume doubleValue]];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)playEffect:(NSDictionary *)params completionHandler:(JSNumberCallback)completionHandler {
    NSNumber *soundId = params[@"soundId"];
    NSString *filePath = params[@"filePath"];
    NSNumber *loopCount = params[@"loopCount"];
    NSNumber *pitch = params[@"pitch"];
    NSNumber *pan = params[@"pan"];
    NSNumber *gain = params[@"gain"];
    BOOL publish = [params[@"publish"] boolValue];
    NSNumber *startPos = params[@"startPos"];
    NSString *identifier = params[@"identifier"];
    
    if ([self.delegate respondsToSelector:@selector(playEffect:filePath:loopCount:pitch:pan:gain:publish:startPos:identifier:)]) {
        int res = [self.delegate playEffect:[soundId intValue] filePath:filePath loopCount:[loopCount intValue] pitch:[pitch doubleValue] pan:[pan doubleValue] gain:[gain doubleValue] publish:publish startPos:[startPos intValue] identifier:identifier];
        if (_debugLog) {
            NSLog(@"play effect res %d, soundId %d, filePath: %@, loopCount: %d, startPos: %d, identifier: %@", res, [soundId intValue], filePath, [loopCount intValue], [startPos intValue], identifier);
        }
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)stopEffect:(NSNumber *)soundId completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(stopEffect:)]) {
        int res = [self.delegate stopEffect:[soundId intValue]];
        if (_debugLog) {
            NSLog(@"stop effect res %d, soundId %d", res, [soundId intValue]);
        }
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)stopAllEffects:(id)useLessArgs completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(stopAllEffects)]) {
        int res = [self.delegate stopAllEffects];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)preloadEffect:(NSDictionary *)params completionHandler:(JSNumberCallback)completionHandler {
    NSNumber *soundId = params[@"soundId"];
    NSString *filePath = params[@"filePath"];
//    NSNumber *startPos = params[@"startPos"]; // Agora rtc 3.7.2 not supported.
    if ([self.delegate respondsToSelector:@selector(preloadEffect:filePath:)]) {
        int res = [self.delegate preloadEffect:[soundId intValue] filePath:filePath];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)unloadEffect:(NSNumber *)soundId completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(unloadEffect:)]) {
        int res = [self.delegate unloadEffect:[soundId intValue]];
        if (_debugLog) {
            NSLog(@"unload effect res %d, soundId %d", res, [soundId intValue]);
        }
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)pauseEffect:(NSNumber *)soundId completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(pauseEffect:)]) {
        int res = [self.delegate pauseEffect:[soundId intValue]];
        if (_debugLog) {
            NSLog(@"pause effect res %d, soundId %d", res, [soundId intValue]);
        }
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)pauseAllEffects:(id)useLessArgs completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(pauseAllEffects)]) {
        int res = [self.delegate pauseAllEffects];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}
- (void)resumeEffect:(NSNumber *)soundId completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(resumeEffect:)]) {
        int res = [self.delegate resumeEffect:[soundId intValue]];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)resumeAllEffects:(id)useLessArgs completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(resumeAllEffects)]) {
        int res = [self.delegate resumeAllEffects];
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)setEffectPosition:(NSDictionary *)params completionHandler:(JSNumberCallback)completionHandler {
    NSNumber *soundId = params[@"soundId"];
    NSNumber *pos = params[@"pos"];
    if ([self.delegate respondsToSelector:@selector(setEffectPosition:pos:)]) {
        int res = [self.delegate setEffectPosition:[soundId intValue] pos:[pos integerValue]];
        if (_debugLog) {
            NSLog(@"setEffectPosition res %d, soundId %d, pos:%d", res, [soundId intValue], [pos intValue]);
        }
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)getEffectCurrentPosition:(NSNumber *)soundId completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(getEffectCurrentPosition:)]) {
        int res = [self.delegate getEffectCurrentPosition:[soundId intValue]];
//        if (_debugLog) {
//            NSLog(@"getEffectCurrentPosition res %d, soundId %d", res, [soundId intValue]);
//        }
        completionHandler(@(res), YES);
    } else {
        completionHandler(@(-999), YES);
    }
}

- (void)getEffectDuration:(NSString *)filePath completionHandler:(JSNumberCallback)completionHandler {
    if ([self.delegate respondsToSelector:@selector(getEffectDuration:)]) {
        int res = [self.delegate getEffectDuration:filePath];
        if (_debugLog) {
            NSLog(@"getEffectDuration res %d, sound %@", res, filePath);
        }
        completionHandler(@(res), YES);
        return;
    } else {
        completionHandler(@(-999), YES);
    }
}

@end
