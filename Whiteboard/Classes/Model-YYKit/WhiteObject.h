//
//  WhiteObject.h
//  Whiteboard
//
//  Created by yleaf on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import <YYKit/YYKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (YYModel)


+ (nullable instancetype)yy_modelWithJSON:(id _Nullable)json;

+ (nullable instancetype)yy_modelWithDictionary:(NSDictionary * _Nullable)dictionary;

- (BOOL)yy_modelSetWithJSON:(id _Nullable)json;

- (BOOL)yy_modelSetWithDictionary:(NSDictionary * _Nullable)dic;

- (nullable id)yy_modelToJSONObject;

- (nullable NSData *)yy_modelToJSONData;

- (nullable NSString *)yy_modelToJSONString;

- (nullable id)yy_modelCopy;

- (void)yy_modelEncodeWithCoder:(NSCoder * _Nullable)aCoder;

- (nullable id)yy_modelInitWithCoder:(NSCoder * _Nullable)aDecoder;

- (NSUInteger)yy_modelHash;

- (BOOL)yy_modelIsEqual:(id _Nullable)model;

- (NSString * _Nullable)yy_modelDescription;

@end

/**
 为 NSArray 提供一些数据模型方法。
 */
@interface NSArray (YYModel)

/**
 从 JSON Array 创建并返回一个数组。
 
 @param cls  数组中实例的类。
 @param json  `NSArray`，`NSString` 或 `NSData` 的 JSON 数组。
              例如： `[{"name":"Mary"},{name:"Joe"}]`。
 
 @return 一个数组，如果发生错误，则返回 `nil`。
 */
+ (nullable NSArray *)yy_modelArrayWithClass:(Class _Nullable)cls json:(id _Nullable)json;

@end



/**
 为 NSDictionary 提供一些数据模型方法。
 */
@interface NSDictionary (YYModel)

/**
 从 JSON 创建并返回字典。
 
 @param cls  值实例在字典中的类。
 @param json  `NSArray`，`NSString` 或 `NSData` 的 JSON 字典。
              例如： `{"user1":{"name","Mary"}, "user2": {name:"Joe"}}`。
 
 @return 字典，如果发生错误，则为 `nil`。
 */
+ (nullable NSDictionary *)yy_modelDictionaryWithClass:(Class _Nullable )cls json:(id  _Nullable)json;

@end

@interface WhiteObject : NSObject

+ (instancetype)modelWithJSON:(id)json;
- (NSString *)jsonString;
- (NSDictionary *)jsonDict;

@end

NS_ASSUME_NONNULL_END