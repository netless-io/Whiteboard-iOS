//
//  WhiteBaseCallbacks.m
//  WhiteSDK
//
//  Created by yleaf on 2019/3/1.
//

#import "WhiteCommonCallbacks.h"
#import "WhiteConsts.h"
#import <YYModel/YYModel.h>

@implementation WhiteCommonCallbacks

- (NSString *)logger:(id)log
{
    NSLog(@"%@", log);
    return @"";
}

- (NSString *)throwError:(id)error
{
    if ([self.delegate respondsToSelector:@selector(throwError:)]) {
        NSDictionary *dict = [NSDictionary yy_modelWithJSON:error];
        NSError *error = [NSError errorWithDomain:WhiteConstsErrorDomain code:NSIntegerMax userInfo:dict];
        [self.delegate throwError:error];
    }
    return @"";
}

- (NSString *)urlInterrupter:(NSString *)url
{
    if ([self.delegate respondsToSelector:@selector(urlInterrupter:)]) {
        return [self.delegate urlInterrupter:url];
    }
    return url;
}

@end
