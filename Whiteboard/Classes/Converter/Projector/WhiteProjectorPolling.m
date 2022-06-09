//
//  ProjectorPolling.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/7.
//

#import "WhiteProjectorPolling.h"
#import "URLRequestPolling.h"

@interface ProjectorTask : NSObject

@property (nonatomic, copy) ProjectorProgressHandler progressHandler;
@property (nonatomic, copy) ProjectorCompletionHandler completionHandler;

- (instancetype)initWithProgressHandler:(ProjectorProgressHandler)progressHandler
               completionHandler:(ProjectorCompletionHandler)completionHandler;

@end

@implementation ProjectorTask

- (instancetype)initWithProgressHandler:(ProjectorProgressHandler)progressHandler
               completionHandler:(ProjectorCompletionHandler)completionHandler
{
    if (self = [super init]) {
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
    }
    return self;
}

@end

static NSString * const ProjectorApiOrigin = @"https://api.netless.link/v5/projector";
static NSString * const kHttpCode = @"httpCode";
static NSString * const kErrorCode = @"errorCode";
static NSString * const kErrorDomain = @"errorDomain";

@interface WhiteProjectorPolling ()<URLRequestPollingDelegate>

@property (nonatomic, strong) URLRequestPolling *polling;
@property (nonatomic, copy) NSMutableDictionary<NSString*, ProjectorTask*> *pollingTasks;

@end

@implementation WhiteProjectorPolling

- (instancetype)init
{
    return [self initWithPollingTimeinterval:15];
}

- (instancetype)initWithPollingTimeinterval:(NSTimeInterval)interval
{
    if (self = [super init]) {
        if (interval < 0) {
            self.polling = [[URLRequestPolling alloc] initWithPollingTimeinterval:1];
        } else {
            self.polling = [[URLRequestPolling alloc] initWithPollingTimeinterval:interval];
        }
        self.polling.delegate = self;
    }
    return self;
}

// MARK: Public
- (void)startPolling { [self.polling startPolling]; }
- (void)pausePolling { [self.polling pausePolling]; }
- (void)endPolling { [self.polling endPolling]; }
- (void)cancelPollingTaskWithTaskUUID:(NSString *)taskUUID
{
    [self.pollingTasks removeObjectForKey:taskUUID];
    [self.polling cancelPollingTaskWithIdentifier:taskUUID];
}

- (NSString *)insertPollingTaskWithTaskUUID:(NSString *)taskUUID
                                      token:(NSString *)token
                                     region:(WhiteRegionKey)region
                                   progress:(ProjectorProgressHandler)progress
                                     result:(ProjectorCompletionHandler)result
{
    ProjectorTask *task = self.pollingTasks[taskUUID];
    if (!task) {
        ProjectorTask *newTask = [[ProjectorTask alloc] initWithProgressHandler:progress
                                                                            completionHandler:result];
        self.pollingTasks[taskUUID] = newTask;
    } else {
        task.progressHandler = progress;
        task.completionHandler = result;
    }
    
    [self.polling insertPollingTask:^NSURLRequest *{
        return [WhiteProjectorPolling createRequestWithTaskUUID:taskUUID region:region token:token];
    } identifier:taskUUID];
    
    return taskUUID;
}

+ (NSURLSessionTask *)checkProgressWithTaskUUID:(NSString *)taskUUID
                                          token:(NSString *)token
                                         region:(WhiteRegionKey)region
                                         result:(void (^)(WhiteProjectorQueryResult * _Nullable, NSError * _Nullable))result
{
    NSURLRequest *request = [self createRequestWithTaskUUID:taskUUID region:region token:token];
    NSURLSessionTask *sessionTask = [querySession() dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // Task canceled
        if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == -999)) {
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            result(nil, error);
        } else if (httpResponse.statusCode == 200) {
            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            WhiteProjectorQueryResult *info = [WhiteProjectorQueryResult modelWithJSON:responseObject];
            if ([info.status isEqualToString:ProjectorQueryResultStatusFail]) {
                result(info, error);
            } else if ([info.status isEqualToString:ProjectorQueryResultStatusFinished]) {
                result(info, nil);
            } else {
                result(info, error);
            }
        } else {
            NSMutableDictionary *responseObject = [([NSJSONSerialization JSONObjectWithData:data options:0 error:nil] ? : @{}) mutableCopy];
            responseObject[kHttpCode] = @(httpResponse.statusCode);
            NSError *error = [NSError errorWithDomain:WhiteConstConvertDomain code:ProjectorQueryErrorCheckFail userInfo:responseObject];
            result(nil, error);
        }
    }];
    [sessionTask resume];
    return sessionTask;
}

// MARK: - Delegate
- (void)URLRequestPollingDidCompleteRequest:(NSString *)identifier
                                   response:(NSURLResponse *)response
                                       data:(NSData *)data
                                      error:(NSError *)error
{
    ProjectorTask *task = self.pollingTasks[identifier];
    if (!task) { return; }
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error) {
        task.completionHandler(NO, nil, error);
        [self cancelPollingTaskWithTaskUUID:identifier];
    } else if (httpResponse.statusCode == 200) {
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        WhiteProjectorQueryResult *info = [WhiteProjectorQueryResult modelWithJSON:responseObject];
        if ([info.status isEqualToString:ProjectorQueryResultStatusFail]) {
            task.completionHandler(NO, info, error);
            [self cancelPollingTaskWithTaskUUID:identifier];
        } else if ([info.status isEqualToString:ProjectorQueryResultStatusFinished]) {
            task.completionHandler(YES, info, nil);
            [self cancelPollingTaskWithTaskUUID:identifier];
        } else {
            task.progressHandler((CGFloat)info.convertedPercentage, info);
        }
    } else {
        NSMutableDictionary *responseObject = [([NSJSONSerialization JSONObjectWithData:data options:0 error:nil] ? : @{}) mutableCopy];
        responseObject[kHttpCode] = @(httpResponse.statusCode);
        NSError *error = [NSError errorWithDomain:WhiteConstConvertDomain code:ProjectorQueryErrorCheckFail userInfo:responseObject];
        task.completionHandler(NO, nil, error);
        [self cancelPollingTaskWithTaskUUID:identifier];
    }
}

// MARK: - Private
+ (NSURLRequest *)createRequestWithTaskUUID:(NSString *)taskUUID
                                     region:(WhiteRegionKey)region
                                      token:(NSString *)token
{
    NSString *questUrl = [ProjectorApiOrigin stringByAppendingString:[NSString stringWithFormat:@"/tasks/%@", taskUUID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:questUrl]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:region forHTTPHeaderField:@"region"];
    [request addValue:token forHTTPHeaderField:@"token"];
    return request;
}

// MARK: - Lazy
- (NSMutableDictionary *)pollingTasks
{
    if (!_pollingTasks) {
        _pollingTasks = [NSMutableDictionary dictionary];
    }
    return _pollingTasks;
}
@end
