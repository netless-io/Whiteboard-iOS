//
//  WhiteConverterV5.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/7.
//

#import "WhiteConverterV5.h"
#import "URLRequestPolling.h"

@interface WhiteConverterTaskV5 : NSObject

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) WhiteRegionKey region;
@property (nonatomic, copy) WhiteConvertTypeV5 type;
@property (nonatomic, copy) ConvertProgressHandlerV5 progressHandler;
@property (nonatomic, copy) ConvertCompletionHandlerV5 completionHandler;

- (instancetype)initWithToken:(NSString *)token
                       region:(WhiteRegionKey)region
                         type:(WhiteConvertTypeV5)type
              progressHandler:(ConvertProgressHandlerV5)progressHandler
            completionHandler:(ConvertCompletionHandlerV5)completionHandler;

@end

@implementation WhiteConverterTaskV5

- (instancetype)initWithToken:(NSString *)token region:(WhiteRegionKey)region type:(WhiteConvertTypeV5)type progressHandler:(ConvertProgressHandlerV5)progressHandler completionHandler:(ConvertCompletionHandlerV5)completionHandler
{
    if (self = [super init]) {
        self.token = token;
        self.region = region;
        self.type = type;
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
    }
    return self;
}

@end

static NSString* const ConverterApiOriginV5 = @"https://api.netless.link/v5";
static NSString* const FallbackConverterApiOriginV5 = @"https://api.whiteboard.agora.io/v5";
static NSString* const kHttpCode = @"httpCode";
static NSString* const kErrorCode = @"errorCode";
static NSString* const kErrorDomain = @"errorDomain";
static NSString* currentApiOrigin = ConverterApiOriginV5;

@interface WhiteConverterV5 ()<URLRequestPollingDelegate>

@property (nonatomic, strong) URLRequestPolling *polling;
@property (nonatomic, copy) NSMutableDictionary<NSString*, WhiteConverterTaskV5*> *pollingTasks;

@end

@implementation WhiteConverterV5

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
                                   taskType:(WhiteConvertTypeV5)type
                                   progress:(ConvertProgressHandlerV5)progress
                                     result:(ConvertCompletionHandlerV5)result
{
    WhiteConverterTaskV5 *task = self.pollingTasks[taskUUID];
    if (!task) {
        WhiteConverterTaskV5 *newTask = [[WhiteConverterTaskV5 alloc] initWithToken:token region:region type: type progressHandler:progress completionHandler:result];
        self.pollingTasks[taskUUID] = newTask;
    } else {
        task.progressHandler = progress;
        task.completionHandler = result;
    }
    
    [self.polling insertPollingTask:^NSURLRequest *{
        return [WhiteConverterV5 createRequestWithTaskUUID:taskUUID taskType:type region:region token:token];
    } identifier:taskUUID];
    
    return taskUUID;
}

+ (NSURLSessionTask *)checkProgressWithTaskUUID:(NSString *)taskUUID
                                          token:(NSString *)token
                                         region:(WhiteRegionKey)region
                                       taskType:(WhiteConvertTypeV5)type
                                         result:(void (^)(WhiteConversionInfoV5 * _Nullable, NSError * _Nullable))result
{
    NSURLRequest *request = [self createRequestWithTaskUUID:taskUUID taskType:type region:region token:token];
    NSURLSessionTask *sessionTask = [querySession() dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // Task canceled
        if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == -999)) {
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            if (request.URL.host == FallbackConverterApiOriginV5) {
                result(nil, error);
            } else {
                currentApiOrigin = FallbackConverterApiOriginV5;
                [self checkProgressWithTaskUUID:taskUUID token:token region:region taskType:type result:result];
            }
        } else if (httpResponse.statusCode == 200) {
            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            WhiteConversionInfoV5 *info = [WhiteConversionInfoV5 _white_yy_modelWithJSON:responseObject];
            if ([info.status isEqualToString:WhiteConvertStatusV5Fail]) {
                result(info, error);
            } else if ([info.status isEqualToString:WhiteConvertStatusV5Finished]) {
                result(info, nil);
            } else {
                result(info, error);
            }
        } else {
            NSMutableDictionary *responseObject = [([NSJSONSerialization JSONObjectWithData:data options:0 error:nil] ? : @{}) mutableCopy];
            responseObject[kHttpCode] = @(httpResponse.statusCode);
            NSError *error = [NSError errorWithDomain:WhiteConstConvertDomain code:ConverterErrorCodeV5CheckFail userInfo:responseObject];
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
    WhiteConverterTaskV5 *task = self.pollingTasks[identifier];
    if (!task) { return; }
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error) {
        if (error.code != -1004) {
            task.completionHandler(NO, nil, error);
            [self cancelPollingTaskWithTaskUUID:identifier];
            return;
        }
        NSURL* failingUrl = error.userInfo[NSURLErrorFailingURLErrorKey];
        if ([FallbackConverterApiOriginV5 containsString:failingUrl.host]) {
            task.completionHandler(NO, nil, error);
            [self cancelPollingTaskWithTaskUUID:identifier];
            return;
        }
        currentApiOrigin = FallbackConverterApiOriginV5;
        [self cancelPollingTaskWithTaskUUID:identifier];
        [self insertPollingTaskWithTaskUUID:identifier token:task.token region:task.region taskType:task.type progress:task.progressHandler result:task.completionHandler];
    } else if (httpResponse.statusCode == 200) {
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        WhiteConversionInfoV5 *info = [WhiteConversionInfoV5 _white_yy_modelWithJSON:responseObject];
        if ([info.status isEqualToString:WhiteConvertStatusV5Fail]) {
            task.completionHandler(NO, info, error);
            [self cancelPollingTaskWithTaskUUID:identifier];
        } else if ([info.status isEqualToString:WhiteConvertStatusV5Finished]) {
            task.completionHandler(YES, info, nil);
            [self cancelPollingTaskWithTaskUUID:identifier];
        } else {
            task.progressHandler(info.progress.convertedPercentage, info);
        }
    } else {
        NSMutableDictionary *responseObject = [([NSJSONSerialization JSONObjectWithData:data options:0 error:nil] ? : @{}) mutableCopy];
        responseObject[kHttpCode] = @(httpResponse.statusCode);
        NSError *error = [NSError errorWithDomain:WhiteConstConvertDomain code:ConverterErrorCodeV5CheckFail userInfo:responseObject];
        task.completionHandler(NO, nil, error);
        [self cancelPollingTaskWithTaskUUID:identifier];
    }
}

// MARK: - Private
+ (NSURLRequest *)createRequestWithTaskUUID:(NSString *)taskUUID
                                   taskType:(WhiteConvertTypeV5)type
                                     region:(WhiteRegionKey)region
                                      token:(NSString *)token
{
    NSString *questUrl = [currentApiOrigin stringByAppendingString:[NSString stringWithFormat:@"/services/conversion/tasks/%@?type=%@", taskUUID, type]];
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
