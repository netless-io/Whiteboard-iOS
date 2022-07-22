//
//  WhiteCallBridgeCommand.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/7/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WhiteCallBridgeCommand : NSObject

@property (nonatomic, copy) NSString* method;
@property (nonatomic, copy) NSArray* args;
@property (nonatomic, assign) BOOL await;

@end

NS_ASSUME_NONNULL_END
