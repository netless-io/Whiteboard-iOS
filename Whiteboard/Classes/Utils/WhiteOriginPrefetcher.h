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

/** 从服务器获取配置列表失败 */
- (void)originPrefetcherFetchOriginConfigsFail:(NSError *)error;
/** 成功从服务器获取配置列表，开始对服务器域名进行连接性测试 */
- (void)originPrefetcherFetchOriginConfigsSuccess:(NSDictionary *)dict;

/**
 服务器连接性测试完成
 */
- (void)originPrefetcherFinishPrefetch:(NSDictionary *)result;

@end

@interface WhiteOriginPrefetcher : NSObject

/** 当前用户的策略组，目前不开放 */
@property (nonatomic, nullable, copy) NSString *strategy;

@property (nonatomic, nullable, weak) id<WhiteOriginPrefetcherDelegate> prefetchDelgate;

@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, NSDictionary *> *serverConfig;
@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, NSDictionary *> *sdkStructConfig;
/** 对服务器返回的配置信息的结构进行转换，同时，加上连接可用性信息 */
@property (nonatomic, nullable, copy, readonly) NSDictionary<NSString *, NSDictionary *> *sdkStrategyConfig;
@property (nonatomic, nullable, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *respondingSpeedDict;
@property (nonatomic, nullable, copy, readonly) NSSet<NSString *> *domains;

@property (nonatomic, nullable, copy) FetchConfigFailBlock fetchConfigFailBlock;
@property (nonatomic, nullable, copy) FetchConfigSuccessBlock fetchConfigSuccessBlock;
@property (nonatomic, nullable, copy) PrefetchFinishBlock prefetchFinishBlock;

+ (instancetype)shareInstance;

/** 获取服务器配置列表。如果成功，紧接着连接性测试 */
- (void)fetchConfigAndPrefetchDomains;

@end

NS_ASSUME_NONNULL_END
