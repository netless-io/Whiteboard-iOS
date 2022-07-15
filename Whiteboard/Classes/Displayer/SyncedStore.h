//
//  SyncedStore.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SyncedStoreUpdateCallBackDelegate <NSObject>
/**
 * SyncedStore 数据发生变更的时候该回调会被触发
 
 @param name 房间内的唯一标识
 @param partialValue 发生变更的数据
 结构为 {"key": {"oldValue": "xxx", "newValue": "xxx"}}
 举例 {"name": {"oldValue": "jack", "newValue": "rose"}}
 
 注意： 如果只有 oldValue 没有 newValue 。说明该 key 被删除。反之则是新增了一个 key。
 */
- (void)syncedStoreDidUpdateStoreName:(NSString *)name partialValue:(NSDictionary *)partialValue;
@end

@interface SyncedStore : NSObject

/**
 数据变更回调
 */
@property (weak, nonatomic) id<SyncedStoreUpdateCallBackDelegate> delegate;

/**
 * 创建一个 SyncedStore 连接
 * 该功能用于白板同步多端自定义状态值，并且可回放
 * 每一个 name 都代表一个独立的 store, 可以创建多个 store

 @param name 房间内唯一标识
 @param defaultValue 默认值
 @param completionHandler 回调，连接成功时返回store值，失败返回error
 */
- (void)connectSyncedStoreStorage:(NSString *)name defaultValue:(NSDictionary *)defaultValue completionHandler:(void (^) (NSDictionary * _Nullable dict, NSError * _Nullable error))completionHandler;

/**
 * 获取指定 Store 的当前状态
 * 创建连接成功之后才可以调用本方法获取状态
 
 @param name 房间内唯一标志
 @param completionHandler 回调，最新状态
 */
- (void)getStorageState:(NSString *)name completionHandler:(void (^) (NSDictionary * _Nullable dict))completionHandler;

/**
 * 断开指定 Store 的连接，不会删除 Store 的数据
 
 @param name 房间内唯一标志
 */
- (void)disconnectStorage:(NSString *)name;

/**
 * 删除指定 Store 的数据并且断开连接
 
 @param name 房间内唯一标志
 */
- (void)deleteStorage:(NSString *)name;

/**
 * 重置指定 Store 的数据到初始化状态
 
 @param name 房间内唯一标志
 */
- (void)resetState:(NSString *)name;

/**
 * 更新指定 Store 的部分数据
 
 @param name 房间内唯一标志
 @param partialState 需要更新的数据
 */
- (void)setStorageState:(NSString *)name partialState:(NSDictionary *)partialState;

@end

NS_ASSUME_NONNULL_END
