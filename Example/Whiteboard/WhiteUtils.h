//
//  WhiteUtils.h
//  WhiteSDKPrivate_Example
//
//  Created by yleaf on 2019/3/4.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WhiteUtils : NSObject

+ (NSString *)appIdentifier;

+ (NSString *)sdkToken;

+ (void)createRoomWithAccessKey:(NSString *)accessKey lifespan:(NSUInteger)lifespan role:(NSString *)role completionHandler:(void (^) (NSString * _Nullable uuid, NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler;

+ (void)getRoomTokenWithUuid:(NSString *)uuid completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler;

+ (void)getRoomInfoWithUuid:(NSString *)uuid completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler;

+ (void)getRoomsListWithUuid:(NSString *)uuid limit:(NSUInteger)limit completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler;

+ (void)banRoomWithUuid:(NSString *)uuid isBan:(BOOL)isBan completionHandler:(void (^)(NSString * _Nullable roomToken, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
