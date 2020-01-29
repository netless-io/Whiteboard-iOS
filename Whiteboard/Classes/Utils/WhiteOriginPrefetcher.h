//
//  OriginPrefetcher.h
//  Whiteboard
//
//  Created by yleaf on 2020/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FetchConfigFailBlock)(NSError *err);
typedef void(^FetchConfigSuccessBlock)(NSDictionary *dict);

typedef void(^PrefetchFinishBlock)(NSDictionary *result);

@protocol WhiteOriginPrefetcherDelegate <NSObject>

- (void)originPrefetcherFetchOriginConfigsFail:(NSError *)error;
- (void)originPrefetcherFetchOriginConfigsSuccess:(NSDictionary *)dict;

/**
 预加载结束，排序结果。
 */
- (void)originPrefetcherFinishPrefetch:(NSDictionary *)result;

@end

@interface WhiteOriginPrefetcher : NSObject

@property (nonatomic, nullable, copy) NSString *strategy;
@property (nonatomic, nullable, weak) id<WhiteOriginPrefetcherDelegate> prefetchDelgate;

@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, NSDictionary *> *configDict;
@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, NSDictionary *> *resultDict;
@property (nonatomic, nullable, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *respondingSpeedDict;
@property (nonatomic, nullable, copy, readonly) NSSet<NSString *> *domains;

@property (nonatomic, nullable, copy) FetchConfigFailBlock fetchConfigFailBlock;
@property (nonatomic, nullable, copy) FetchConfigSuccessBlock fetchConfigSuccessBlock;
@property (nonatomic, nullable, copy) PrefetchFinishBlock prefetchFinishBlock;

+ (instancetype)shareInstance;

- (void)fetchOriginConfigs;
- (void)prefetchOrigins;

/**
 just for unit testing
 */
- (NSDictionary *)sortedDomainConfigFrom:(NSDictionary *)config;
- (NSArray *)sortDomains:(NSArray *)domains by:(NSDictionary *)speedDict;

@end

NS_ASSUME_NONNULL_END
