//
//  ProjectorQueryResult.m
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/9.
//

#import "WhiteProjectorQueryResult.h"

ProjectorConvertType const ProjectorConvertTypeDynamic = @"dynamic";
ProjectorConvertType const ProjectorConvertTypeStatic = @"static";

ProjectorQueryResultStatus const ProjectorQueryResultStatusWaiting = @"Waiting";
ProjectorQueryResultStatus const ProjectorQueryResultStatusConverting = @"Converting";
ProjectorQueryResultStatus const ProjectorQueryResultStatusFinished = @"Finished";
ProjectorQueryResultStatus const ProjectorQueryResultStatusFail = @"Fail";

@implementation WhiteProjectorQueryResult

+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass
{
    return @{@"images": @"WhiteProjectorStaticImageInfo"};
}

@end
