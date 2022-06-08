//
//  URLRequestPolling.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/7.
//

#import "URLRequestPolling.h"

@interface URLRequestPolling ()

@property (nonatomic, assign) NSTimeInterval pollingInterval;
/// identifier: maker
@property (nonatomic, copy) NSMutableDictionary<NSString*, URLRequestMaker> *taskMakers;
/// identifier: url
@property (nonatomic, copy) NSMutableDictionary<NSString*, NSURLSessionTask*> *pollingTasks;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation URLRequestPolling

- (instancetype)init
{
    if (self = [super init]) {
        self.pollingInterval = 15;
    }
    return self;
}

- (instancetype)initWithPollingTimeinterval:(NSTimeInterval)interval
{
    if (self = [self init]) {
        if (interval < 0) {
            self.pollingInterval = 1;
        } else {
            self.pollingInterval = interval;
        }
    }
    return self;
}

- (void)startPolling
{
    if (self.timer) {
        [self endTimer];
    }
    self.timer = [NSTimer timerWithTimeInterval:self.pollingInterval target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    [self onTimer];
}

- (void)pausePolling
{
    if (self.timer) {
        [self endTimer];
    }
}

- (void)endPolling
{
    [self.pollingTasks enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSURLSessionTask * _Nonnull task, BOOL * _Nonnull stop) {
        [self cancelPollingTaskWithIdentifier:key];
    }];
    [self endTimer];
}

- (void)onTimer
{
    [self.taskMakers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, URLRequestMaker  _Nonnull maker, BOOL * _Nonnull stop) {
        NSURLRequest *request = maker();
        __weak typeof(self) weakSelf = self;
        NSURLSessionTask *task = [querySession() dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            // Task canceled
            if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == -999)) {
                return;
            }
            [weakSelf.delegate URLRequestPollingDidCompleteRequest:key response:response data:data error:error];
        }];
        [task resume];
        self.pollingTasks[key] = task;
    }];
}

- (void)endTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)cancelPollingTaskWithIdentifier:(NSString *)identifier
{
    NSURLSessionTask *task = self.pollingTasks[identifier];
    if (task) {
        [task cancel];
        [self.pollingTasks removeObjectForKey:identifier];
    }
    URLRequestMaker maker = self.taskMakers[identifier];
    if (maker) {
        [self.taskMakers removeObjectForKey:identifier];
    }
    if (self.pollingTasks.count == 0) {
        [self endPolling];
    }
}

- (void)insertPollingTask:(URLRequestMaker)maker identifier:(NSString *)identifier {
    self.taskMakers[identifier] = maker;
    if (!self.timer) {
        [self startPolling];
    }
}

// MARK: - Lazy
- (NSMutableDictionary<NSString *,NSURLSessionTask *> *)pollingTasks {
    if (!_pollingTasks) {
        _pollingTasks = [NSMutableDictionary dictionary];
    }
    return _pollingTasks;
}

- (NSMutableDictionary<NSString *,URLRequestMaker> *)taskMakers {
    if (!_taskMakers) {
        _taskMakers = [NSMutableDictionary dictionary];
    }
    return _taskMakers;
}

@end
