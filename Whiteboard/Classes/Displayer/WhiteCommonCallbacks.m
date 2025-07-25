//
//  WhiteBaseCallbacks.m
//  WhiteSDK
//
//  Created by yleaf on 2019/3/1.
//

#import "WhiteCommonCallbacks.h"
#import "WhiteConsts.h"
#import "WhiteObject.h"
#if __has_include(<NTLBridge/NTLDWKWebView.h>)
#import <NTLBridge/NTLDWKWebView.h>
#else
#import "NTLDWKWebView.h"
#endif

@implementation WhiteCommonCallbacks

- (NSString *)logger:(NSDictionary *)log
{
    if ([self.delegate respondsToSelector:@selector(logger:)]) {
        [self.delegate logger:log];
    } else {
        NSLog(@"[White]: %@", log);
    }
    return @"";
}

- (NSString *)throwError:(NSDictionary *)errInfo
{
    if ([self.delegate respondsToSelector:@selector(throwError:)]) {
        NSMutableDictionary *info = [errInfo mutableCopy];
        
        static NSString *kMessageKey = @"message";
        static NSString *kErrorKey = @"error";
        info[NSLocalizedDescriptionKey] = errInfo[kMessageKey];
        info[NSDebugDescriptionErrorKey] = errInfo[kErrorKey];
        info[kMessageKey] = nil;
        info[kErrorKey] = nil;
        
        NSError *error = [NSError errorWithDomain:WhiteConstErrorDomain code:NSIntegerMax userInfo:info];
        [self.delegate throwError:error];
    }
    return @"";
}

- (void)slideUrlInterrupter:(NSString *)url completionHandler:(JSCallback)completionHandler
{
    if ([self.slideDelegate respondsToSelector:@selector(slideUrlInterrupter:completionHandler:)]) {
        [self.slideDelegate slideUrlInterrupter:url completionHandler:^(NSString * _Nullable result) {
            completionHandler(result, YES);
        }];
    }
}

- (NSString *)slideOpenUrl:(NSString *)url
{
    if ([self.slideDelegate respondsToSelector:@selector(slideOpenUrl:)]) {
        [self.slideDelegate slideOpenUrl:url];
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

- (NSString *)onPPTMediaPlay:(NSDictionary *)dict
{
    if ([self.delegate respondsToSelector:@selector(pptMediaPlay)]) {
        [self.delegate pptMediaPlay];
    }
    return @"";
}


- (NSString *)onPPTMediaPause:(NSDictionary *)dict
{
    if ([self.delegate respondsToSelector:@selector(pptMediaPause)]) {
        [self.delegate pptMediaPause];
    }
    return @"";
}

- (NSString *)setupFail:(NSDictionary *)info
{
    if ([self.delegate respondsToSelector:@selector(sdkSetupFail:)]) {
        NSString *desc = info[@"message"] ? : @"";
        NSString *description = info[@"jsStack"] ? : @"";
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: desc, NSDebugDescriptionErrorKey: description};
        NSError *error = [NSError errorWithDomain:WhiteConstErrorDomain code:-400 userInfo:userInfo];
        [self.delegate sdkSetupFail:error];
    }
    
    return @"";
}

- (NSString *)postMessage:(NSString *)message
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (dict && [dict[@"name"] isEqualToString:@"pptImageLoadError"]) {
        NSString *name = dict[@"name"];
        NSString *notificationName = [NSString stringWithFormat:@"DynamicPpt-%@", name];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:dict userInfo:dict];
    }
    if (dict && dict[@"shapeId"] && dict[@"mediaType"]) {
        NSString *name = dict[@"action"];
        NSString *notificationName = [NSString stringWithFormat:@"DynamicPpt-%@", name];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:dict userInfo:dict];
    }
    if (dict && [dict[@"name"] isEqualToString:@"iframe"]) {
        NSString *name = dict[@"name"];
        /**
         必然存在 name: "iframe" 字段
         其他字段由 iframe 自行决定
        */
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:dict];
    }
    if (dict && [dict[@"type"] isEqualToString:@"@slide/_report_log_"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Slide-Log" object:nil userInfo:dict];
    }
    if (dict && [dict[@"type"] isEqualToString:@"@slide/_report_volume_"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Slide-Volume" object:nil userInfo:dict];
    }
    if (dict && [dict[@"type"] isEqualToString:@"@slide/_error_"]) {
        WhiteSlideErrorType errorType = dict[@"errorType"];
        NSString* errorMsg = dict[@"errorMsg"];
        NSString* slideId = dict[@"slideId"];
        NSInteger slideIndex = -1;
        NSNumber* slideIndexNumber = dict[@"slideIndex"];
        if (slideIndexNumber && [slideIndexNumber isKindOfClass:[NSNumber class]]) {
            NSInteger slideIndex = [slideIndexNumber integerValue];
        }
        if ([self.slideDelegate respondsToSelector:@selector(onSlideError:errorMessage:slideId:slideIndex:)]) {
            [self.slideDelegate onSlideError:errorType errorMessage:errorMsg slideId:slideId slideIndex:slideIndex];
            return @"";
        }
    }
    if (dict && [self.delegate respondsToSelector:@selector(customMessage:)]) {
        [self.delegate customMessage:dict];
    }
    return @"";
}

@end
