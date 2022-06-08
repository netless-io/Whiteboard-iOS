//
//  URLRequestPolling.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/7.
//

#import <Foundation/Foundation.h>

@protocol URLRequestPollingDelegate <NSObject>

- (void)URLRequestPollingDidCompleteRequest:(NSString *)identifier response:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error;

@end

typedef NSURLRequest* (^URLRequestMaker)(void);

NS_ASSUME_NONNULL_BEGIN

static NSURLSession* querySession() {
    static NSURLSession* session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                delegate:nil
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    return session;
}

@interface URLRequestPolling : NSObject

@property (nonatomic, weak, nullable) id<URLRequestPollingDelegate> delegate;

- (instancetype)init;
- (instancetype)initWithPollingTimeinterval:(NSTimeInterval)interval;

- (void)startPolling;
- (void)pausePolling;
- (void)endPolling;

- (void)cancelPollingTaskWithIdentifier:(NSString *)identifier;
- (void)insertPollingTask:(URLRequestMaker)maker identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
