//
//  ProjectorPolling.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/2/22.
//

#import "WhiteConsts.h"
#import "WhiteProjectorQueryResult.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ProjectorCompletionHandler)(BOOL success, WhiteProjectorQueryResult * _Nullable info, NSError * _Nullable error);
typedef void(^ProjectorProgressHandler)(CGFloat progress, WhiteProjectorQueryResult * _Nullable info);

typedef NS_ENUM(NSInteger, ProjectorQueryErrorCode) {
    /** 查询时出错，一般是网络问题，请重启查询服务 */
    ProjectorQueryErrorCheckFail   = 50004,
};

/**
 Projector版本的转码查询工具
 */
@interface WhiteProjectorPolling : NSObject

/** 默认初始的轮询时间为15S */
- (instancetype)init;

/** 指定轮询时间 */
- (instancetype)initWithPollingTimeinterval:(NSTimeInterval)interval;

/** 启动轮询 */
- (void)startPolling;

/** 暂停轮询*/
- (void)pausePolling;

/** 停止轮询并且删除所有轮询任务 */
- (void)endPolling;

/**
 取消特定的一个轮询任务
 @param taskUUID 任务id
 */
- (void)cancelPollingTaskWithTaskUUID:(NSString *)taskUUID;

/**
 插入一个任务查询的轮询任务
 该任务会在转码失败或者成功之后被移出轮询队列
 
 @param taskUUID 转码id
 @param token 转码token
 @param region 转码Region
 @param progress 进度回调
 @param result 转码成功或者失败回调
 @return 任务id
 */
- (NSString *)insertPollingTaskWithTaskUUID:(NSString *)taskUUID
                                      token:(NSString *)token
                                     region:(WhiteRegionKey)region
                                   progress:(_Nullable ProjectorProgressHandler)progress
                                     result:(_Nullable ProjectorCompletionHandler)result;

/**
 单次查询一个特定的转码任务进度
 @param taskUUID 转码id
 @param token 转码token
 @param region 转码Region
 @param result 转码进度回调
 */
+ (NSURLSessionTask *)checkProgressWithTaskUUID:(NSString *)taskUUID
                                          token:(NSString *)token
                                         region:(WhiteRegionKey)region
                                         result:(void (^)(WhiteProjectorQueryResult * _Nullable info, NSError * _Nullable error))result;

@end

NS_ASSUME_NONNULL_END
