//
//  AdvanceConverterProgressPolling.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/8.
//

#import "WhiteConsts.h"
#import "WhiteConverterV5.h"
#import "WhiteProjectorPolling.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ProgressHandler)(CGFloat progress);

/**
 转码查询工具
 提供转码进度查询
 同时支持V5和Projector版本
 */
@interface WhiteAdvanceConvertProgressPolling : NSObject

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
 插入一个V5任务查询的轮询任务
 该任务会在转码失败或者成功之后被移出轮询队列
 
 @param taskUUID 转码id
 @param token 转码token
 @param region 转码Region
 @param type 转码类型, WhiteConvertTypeDynamic或者WhiteConvertTypeStatic
 @param progress 进度回调
 @param result 转码成功或者失败回调
 @return 任务id
 */
- (NSString *)insertV5PollingTaskWithTaskUUID:(NSString *)taskUUID
                                      token:(NSString *)token
                                     region:(WhiteRegionKey)region
                                   taskType:(WhiteConvertTypeV5)type
                                   progress:(_Nullable ProgressHandler)progress
                                     result:(_Nullable ConvertCompletionHandlerV5)result;

/**
 插入一个Projector任务查询的轮询任务
 该任务会在转码失败或者成功之后被移出轮询队列
 
 @param taskUUID 转码id
 @param token 转码token
 @param region 转码Region
 @param progress 进度回调
 @param result 转码成功或者失败回调
 @return 任务id
 */
- (NSString *)insertProjectorPollingTaskWithTaskUUID:(NSString *)taskUUID
                                               token:(NSString *)token
                                              region:(WhiteRegionKey)region
                                            progress:(_Nullable ProgressHandler)progress
                                              result:(_Nullable ProjectorCompletionHandler)result;

@end

NS_ASSUME_NONNULL_END
