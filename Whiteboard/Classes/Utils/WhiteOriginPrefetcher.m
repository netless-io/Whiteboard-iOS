//
//  OriginPrefetcher.m
//  Whiteboard
//
//  Created by yleaf on 2020/1/19.
//

#import "WhiteOriginPrefetcher.h"
#import "WhiteSDK.h"

NSString * const kHost = @"https://cloudcapiv4.herewhite.com";

@interface WhiteOriginPrefetcher ()

@property (nonatomic, strong) NSURLSession *session;

/**
 {
    [strategy: NSString]: {
        version: NSString,
        [server-name: NSString]: NSArray<NSString *>
    }
 }
 */
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *serverConfig;

/**
 转换服务器数据结构，为后续 sdk 初始化时，需要的结构做准备

 {
    [strategy: NSString]: {
        version: NSString,
        origins: {
            [server-name: NSString]: NSArray<NSString *>
        }
    }
 }
 */
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *sdkStructConfig;

/**
sdk 最终需要的数据格式，添加了服务器连接信息
{
   [strategy: NSString]: {
       version: NSString,
       origins: {
           [server-name: NSString]: NSArray<NSDictionary *> [{
               origin: string
               ping: number
               valid: boolean
           }]
       }
   }
}
*/
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *sdkStrategyConfig;

@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSNumber *> *respondingSpeedDict;

@property (nonatomic, copy, readwrite) NSSet<NSString *> *domains;

@end

static NSString *const kOriginsKey = @"origins";

static NSString *const kHostInfoOriginKey = @"origin";
static NSString *const kHostInfoPingKey = @"ping";
static NSString *const kHostInfoValidKey = @"valid";

@implementation WhiteOriginPrefetcher

+ (instancetype)shareInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self session];
        self.respondingSpeedDict = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - properties
- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        config.timeoutIntervalForRequest = 3;
        config.HTTPAdditionalHeaders = @{@"platform": @"ios", @"version": [WhiteSDK version]};
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return _session;
}

- (void)generateSdkOriginConfigFrom:(NSDictionary *)serverConfig
{
    NSMutableDictionary *convertedDict = [NSMutableDictionary dictionary];
    [serverConfig enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull subDict, BOOL * _Nonnull stop) {
        NSMutableDictionary *strategyConfig = [NSMutableDictionary dictionary];
        NSMutableDictionary *originConfig = [NSMutableDictionary dictionary];
        [subDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull subKey, id _Nonnull subObj, BOOL * _Nonnull stop) {
            if ([subObj isKindOfClass:[NSString class]] || [subObj isKindOfClass:[NSNumber class]]) {
                strategyConfig[subKey] = subObj;
            } else {
                originConfig[subKey] = subObj;
            }
        }];
        strategyConfig[kOriginsKey] = originConfig;
        convertedDict[key] = strategyConfig;
    }];
    self.sdkStructConfig = [convertedDict copy];
}

#pragma mark - Public

- (void)fetchConfigAndPrefetchDomains
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[kHost stringByAppendingPathComponent:@"configs/origin"]]];
    
    NSMutableURLRequest *modifyRequest = [request mutableCopy];
    [modifyRequest setHTTPMethod:@"GET"];
    
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [modifyRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:modifyRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([responseObject[@"code"] integerValue] == 200) {
                    self.serverConfig = responseObject[@"msg"];
                    [self generateSdkOriginConfigFrom:self.serverConfig];
                    [self collectDomains];
                    if ([self.prefetchDelgate respondsToSelector:@selector(originPrefetcherFetchOriginConfigsSuccess:)]) {
                        [self.prefetchDelgate originPrefetcherFetchOriginConfigsSuccess:self.serverConfig];
                    }
                    if (self.fetchConfigSuccessBlock) {
                        self.fetchConfigSuccessBlock(self.serverConfig);
                    }
                    [self prefetchOrigins];
                } else {
                    NSInteger code = [responseObject[@"code"] integerValue];
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:responseObject];

                    if ([self.prefetchDelgate respondsToSelector:@selector(originPrefetcherFetchOriginConfigsFail:)]) {
                        [self.prefetchDelgate originPrefetcherFetchOriginConfigsFail:error];
                    }
                    if (self.fetchConfigFailBlock) {
                        self.fetchConfigFailBlock(error);
                    }
                }
            } else {
                NSError *prefetchError;
                if (error) {
                    prefetchError = error;
                } else {
                    prefetchError = [NSError errorWithDomain:NSURLErrorDomain code:httpResponse.statusCode userInfo:nil];
                }
                
                if ([self.prefetchDelgate respondsToSelector:@selector(originPrefetcherFetchOriginConfigsFail:)]) {
                    [self.prefetchDelgate originPrefetcherFetchOriginConfigsFail:error];
                }
                if (self.fetchConfigFailBlock) {
                    self.fetchConfigFailBlock(error);
                }
            }
        });
    }];
    [task resume];
}

static NSString *kSchemePrefix = @"https";

- (void)prefetchOrigins {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
        [self.domains enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [self pingHost:obj completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                dispatch_semaphore_signal(signal);
            }];
            dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        }];
        self.sdkStrategyConfig = [self generatePingInfoConfig:self.sdkStructConfig];
        if ([self.prefetchDelgate respondsToSelector:@selector(originPrefetcherFinishPrefetch:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.prefetchDelgate originPrefetcherFinishPrefetch:self.sdkStrategyConfig];
            });
        }
        if (self.prefetchFinishBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.prefetchFinishBlock(self.sdkStrategyConfig);
            });
        }
    });
}

#pragma mark - Private

- (void)pingHost:(NSString *)host completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:host];
    components.scheme = kSchemePrefix;
    components.path = @"/ping";
    NSURLRequest *request = [NSURLRequest requestWithURL:components.URL];
    
    NSDate *beginDate = [NSDate date];
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode <= 300 && httpResponse.statusCode >= 200 ) {
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:beginDate];
            self.respondingSpeedDict[host] = @(interval);
        } else {
//            NSLog(@"%@ can not get response. statusCode:%ld response:%@ error:%@", host, (long)httpResponse.statusCode, response, [error localizedDescription]);
        }
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    }];
    [task resume];
}

#pragma mark - Handle Configs

- (void)collectDomains {
    NSMutableSet *set = [NSMutableSet set];
    [self.serverConfig enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!self.strategy || [key isEqualToString:self.strategy]) {
            [set unionSet:[self getDomainsFromConfig:obj]];
        }
    }];
    self.domains = [set copy];
}

- (NSDictionary *)generatePingInfoConfig:(NSDictionary <NSString *, NSDictionary *>*)config {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [config enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableDictionary *subConfig = [obj mutableCopy];
        NSDictionary *origins = obj[kOriginsKey];
        
        NSMutableDictionary *mutableOrigins = [origins mutableCopy];
        [origins enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray<NSDictionary *> *pingInfo = [self pingInfoFor:obj];
                mutableOrigins[key] = pingInfo;
            }
        }];
        subConfig[kOriginsKey] = mutableOrigins;
        dict[key] = subConfig;
    }];
    return [dict copy];
}

- (NSArray<NSDictionary *> *)pingInfoFor:(NSArray<NSString *> *)hosts {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:hosts.count];
    for (NSString *host in hosts) {
        NSMutableDictionary *dict = [@{kHostInfoOriginKey: host} mutableCopy];
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:host];
        components.scheme = kSchemePrefix;
        NSString *httpsHost = components.URL.absoluteString;
        NSNumber *speed = self.respondingSpeedDict[httpsHost];
        if (speed) {
            dict[kHostInfoPingKey] = speed;
            dict[kHostInfoValidKey] = @(YES);
        } else {
            dict[kHostInfoPingKey] = @(100000);
            dict[kHostInfoValidKey] = @(NO);
        }
        [array addObject:dict];
    }
    return [array copy];
}

- (NSSet *)getDomainsFromConfig:(NSDictionary *)config {
    NSMutableSet<NSString *> *set = [NSMutableSet set];

    [config enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSURLComponents *components = [NSURLComponents componentsWithString:obj];

            if (components && components.host) {
                //移除 scheme，方便后续对比 ws
                components.scheme = kSchemePrefix;
                components.fragment = nil;
                components.query = nil;
                components.path = nil;
                //暂时不移除端口号
//                components.port = nil;
                [set addObject:components.URL.absoluteString];
            }
        } else if ([obj isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)obj;
            [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)idx];
                [set unionSet:[self getDomainsFromConfig:@{key: obj}]];
            }];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            [set unionSet:[self getDomainsFromConfig:obj]];
        }
    }];
    
    return set;
}

@end
