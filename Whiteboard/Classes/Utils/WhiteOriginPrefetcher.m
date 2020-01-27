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
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *configDict;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *resultDict;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSNumber *> *respondingSpeedDict;
@property (nonatomic, copy, readwrite) NSSet<NSString *> *domains;

@end

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
        config.timeoutIntervalForRequest = 30;
        config.HTTPAdditionalHeaders = @{@"platform": @"ios", @"version": [WhiteSDK version]};
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return _session;
}

#pragma mark - Public

- (void)fetchOriginConfigs
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
                    self.configDict = responseObject[@"msg"];
                    [self getDomains];
                    if ([self.prefetchDelgate respondsToSelector:@selector(originPrefetcherFetchOriginConfigsSuccess:)]) {
                        [self.prefetchDelgate originPrefetcherFetchOriginConfigsSuccess:self.configDict];
                    }
                    if (self.fetchConfigSuccessBlock) {
                        self.fetchConfigSuccessBlock(self.configDict);
                    }
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

        dispatch_semaphore_t signal = dispatch_semaphore_create(1);
        dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC);

        [self.domains enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            dispatch_semaphore_wait(signal, overTime);
            
            [self pingHost:obj completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                dispatch_semaphore_signal(signal);
            }];
        }];
        
        self.resultDict = [self sortedDomainConfigFrom:self.configDict];
        if ([self.prefetchDelgate respondsToSelector:@selector(originPrefetcherFinishPrefetch:)]) {
            [self.prefetchDelgate originPrefetcherFinishPrefetch:self.resultDict];
        }
        if (self.prefetchFinishBlock) {
            self.prefetchFinishBlock(self.resultDict);
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
            NSLog(@"%@ can not get response. statusCode:%ld response:%@ error:%@", host, (long)httpResponse.statusCode, response, [error localizedDescription]);
        }
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    }];
    [task resume];
}

#pragma mark - Handle Configs

- (void)getDomains {
    NSMutableSet *set = [NSMutableSet set];
    [self.configDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!self.strategy || [key isEqualToString:self.strategy]) {
            [set unionSet:[self getDomainsFromConfig:obj]];
        }
    }];
    self.domains = [set copy];
}

- (NSDictionary *)sortedDomainConfigFrom:(NSDictionary *)config {
    
    NSMutableDictionary *dict = [config mutableCopy];
    
    [config enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull subObj, BOOL * _Nonnull stop) {
        NSMutableDictionary *mutableDict = [subObj mutableCopy];
        [subObj enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSArray class]] && [obj count] > 1) {
                NSArray *sort = [self sortDomains:obj by:self.respondingSpeedDict];
                mutableDict[key] = sort;
            }
        }];
        dict[key] = mutableDict;
    }];
    
    return [dict copy];
}

- (NSArray *)sortDomains:(nonnull NSArray *)domains by:(NSDictionary *)speedDict;
{
    NSSet *keySet = [NSSet setWithArray:speedDict.allKeys];
    
    BOOL needReplaceSchemeForSort = NO;
    NSString *originScheme = kSchemePrefix;
    if ([[domains firstObject] isKindOfClass:[NSString class]]) {
        NSString *firstDomain = (NSString *)[domains firstObject];
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:firstDomain];
        if (![components.scheme isEqualToString:kSchemePrefix]) {
            needReplaceSchemeForSort = YES;
            originScheme = components.scheme;
        }
    }
    
    if (needReplaceSchemeForSort) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:domains.count];
        [domains enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *str = (NSString *)obj;
                obj = [str stringByReplacingOccurrencesOfString:originScheme withString:kSchemePrefix];
            }
            [array addObject:obj];
        }];
        domains = [array copy];
    }
    
    NSMutableSet *insertSet = [NSMutableSet setWithArray:domains];
    [insertSet intersectSet:keySet];
        
    NSArray *sortedArray = [insertSet.allObjects sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id  _Nonnull obj2) {
        
        NSNumber *speed1 = speedDict[obj1];
        NSNumber *speed2 = speedDict[obj2];
        return [speed1 compare:speed2];
    }];
    

    NSMutableSet *minusSet = [NSMutableSet setWithArray:domains];
    [minusSet minusSet:keySet];

    NSArray *result = [sortedArray arrayByAddingObjectsFromArray:minusSet.allObjects];
    if (needReplaceSchemeForSort) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:result.count];
        [result enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *str = (NSString *)obj;
                obj = [str stringByReplacingOccurrencesOfString:kSchemePrefix withString:originScheme];
            }
            [array addObject:obj];
        }];
        result = [array copy];
    }
    return result;
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
