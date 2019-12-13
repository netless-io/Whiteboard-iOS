//
//  WhiteRoomConfig.m
//  WhiteSDK
//
//  Created by yleaf on 2019/3/30.
//

#import "WhiteRoomConfig.h"

@implementation WhiteRoomConfig

- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken
{
    return [self initWithUuid:uuid roomToken:roomToken userPayload:nil];
}

- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken memberInfo:(WhiteMemberInformation *)memberInfo
{
    if (self = [super init]) {
        _uuid = uuid;
        _roomToken = roomToken;
        _memberInfo = memberInfo;
    }
    return self;
}

- (instancetype)initWithUuid:(NSString *)uuid roomToken:(NSString *)roomToken userPayload:(id)userPayload
{
    if (self = [super init]) {
        _uuid = uuid;
        _roomToken = roomToken;
        _userPayload = userPayload;
        
        //TODO: 提前校验数据合法性
        if (_userPayload) {
            NSDictionary *dict = @{@"key": _userPayload};
            if (![NSJSONSerialization isValidJSONObject:dict]) {
                
            }
        }
    }
    return self;
}

@end
