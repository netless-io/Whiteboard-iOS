//
//  NSObject+YY.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/4/21.
//

#import "NSObject+YY.h"

@implementation NSObject (YY)

+ (instancetype)modelWithJSON:(id)json
{
    return [self yy_modelWithJSON:json];
}

@end
