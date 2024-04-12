//
//  ProjectorQueryResult.h
//  Whiteboard
//
//  Created by xuyunshi on 2022/6/9.
//

#import "WhiteObject.h"
#import "WhiteProjectorStaticImageInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * ProjectorConvertType NS_STRING_ENUM;
FOUNDATION_EXPORT ProjectorConvertType const ProjectorConvertTypeDynamic;
FOUNDATION_EXPORT ProjectorConvertType const ProjectorConvertTypeStatic;

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
@property (nonatomic, copy) ProjectorConvertType type;
// 转换后的文档预览图地址，每页对应一个预览图地址。该参数仅在发起文档转换时，请求包体中的 preview 设为 true ，且 type 设为 dynamic 时才生效。
@property (nonatomic, copy) NSDictionary<NSString*, NSString*> *previews;
// 文档转图片结果的地址，每页对应一张图片。该参数仅在该参数仅在发起文档转换时，请求包体中的 type 设为 static 时才生效。
@property (nonatomic, copy) NSDictionary<NSString*, WhiteProjectorStaticImageInfo*> *images;
@property (nonatomic, copy) NSString *errorCode;
@property (nonatomic, copy) NSString *errorMessage;

@end

NS_ASSUME_NONNULL_END
