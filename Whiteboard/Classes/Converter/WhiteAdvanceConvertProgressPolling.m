//
//  AdvanceConverterProgressPolling.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/8.
//

#import "WhiteAdvanceConvertProgressPolling.h"
#import "WhiteProjectorPolling.h"
#import "WhiteConverterV5.h"

@interface WhiteAdvanceConvertProgressPolling ()
@property (nonatomic, strong) WhiteConverterV5 *v5Converter;
@property (nonatomic, strong) WhiteProjectorPolling *projector;
@end

@implementation WhiteAdvanceConvertProgressPolling

- (instancetype)init {
    return [self initWithPollingTimeinterval:15];
}

- (instancetype)initWithPollingTimeinterval:(NSTimeInterval)interval {
    if (self = [super init]) {
        if (interval < 0) {
            self.v5Converter = [[WhiteConverterV5 alloc] initWithPollingTimeinterval:1];
            self.projector = [[WhiteProjectorPolling alloc] initWithPollingTimeinterval:1];
        } else {
            self.v5Converter = [[WhiteConverterV5 alloc] initWithPollingTimeinterval:interval];
            self.projector = [[WhiteProjectorPolling alloc] initWithPollingTimeinterval:interval];
        }
    }
    return self;
}

// MARK: - Public
- (void)startPolling {
    [self.projector startPolling];
    [self.v5Converter startPolling];
}
- (void)pausePolling {
    [self.projector pausePolling];
    [self.v5Converter pausePolling];
}
- (void)endPolling {
    [self.projector endPolling];
    [self.v5Converter endPolling];
}
- (void)cancelPollingTaskWithTaskUUID:(NSString *)taskUUID {
    [self.projector cancelPollingTaskWithTaskUUID:taskUUID];
    [self.v5Converter cancelPollingTaskWithTaskUUID:taskUUID];
}

- (NSString *)insertV5PollingTaskWithTaskUUID:(NSString *)taskUUID token:(NSString *)token region:(WhiteRegionKey)region taskType:(WhiteConvertTypeV5)type progress:(ProgressHandler)progress result:(ConvertCompletionHandlerV5)result {
    return [self.v5Converter insertPollingTaskWithTaskUUID:taskUUID token:token region:region taskType:type progress:^(CGFloat p, WhiteConversionInfoV5 * _Nullable info) {
        progress(p);
    } result:result];
}

- (NSString *)insertProjectorPollingTaskWithTaskUUID:(NSString *)taskUUID
                                               token:(NSString *)token
                                              region:(WhiteRegionKey)region
                                            progress:(ProgressHandler)progress
                                              result:(ProjectorCompletionHandler _Nullable)result {
    return [self.projector insertPollingTaskWithTaskUUID:taskUUID token:token region:region progress:^(CGFloat p, WhiteProjectorQueryResult * _Nullable info) {
        progress(p);
    } result:result];
}


@end
