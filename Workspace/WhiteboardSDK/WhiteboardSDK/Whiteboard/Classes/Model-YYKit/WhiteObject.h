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
 Provide some data-model method for NSArray.
 */
@interface NSArray (YYModel)

/**
 Creates and returns an array from a json-array.
 This method is thread-safe.
 
 @param cls  The instance's class in array.
 @param json  A json array of `NSArray`, `NSString` or `NSData`.
              Example: [{"name":"Mary"},{name:"Joe"}]
 
 @return A array, or nil if an error occurs.
 */
+ (nullable NSArray *)yy_modelArrayWithClass:(Class _Nullable)cls json:(id _Nullable)json;

@end



/**
 Provide some data-model method for NSDictionary.
 */
@interface NSDictionary (YYModel)

/**
 Creates and returns a dictionary from a json.
 This method is thread-safe.
 
 @param cls  The value instance's class in dictionary.
 @param json  A json dictionary of `NSDictionary`, `NSString` or `NSData`.
              Example: {"user1":{"name","Mary"}, "user2": {name:"Joe"}}
 
 @return A dictionary, or nil if an error occurs.
 */
+ (nullable NSDictionary *)yy_modelDictionaryWithClass:(Class _Nullable )cls json:(id  _Nullable)json;

@end

@interface WhiteObject : NSObject

+ (instancetype)modelWithJSON:(id)json;
- (NSString *)jsonString;
- (NSDictionary *)jsonDict;

@end

NS_ASSUME_NONNULL_END


