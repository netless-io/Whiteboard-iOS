//
//  ProjectorQueryResult.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/9.
//

#import "WhiteObject.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * ProjectorQueryResultStatus NS_STRING_ENUM;
FOUNDATION_EXPORT ProjectorQueryResultStatus const ProjectorQueryResultStatusWaiting;
FOUNDATION_EXPORT ProjectorQueryResultStatus const ProjectorQueryResultStatusConverting;
FOUNDATION_EXPORT ProjectorQueryResultStatus const ProjectorQueryResultStatusFinished;
FOUNDATION_EXPORT ProjectorQueryResultStatus const ProjectorQueryResultStatusFail;

@interface WhiteProjectorQueryResult : WhiteObject

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) NSInteger convertedPercentage;
@property (nonatomic, copy) ProjectorQueryResultStatus status;


@end

NS_ASSUME_NONNULL_END
