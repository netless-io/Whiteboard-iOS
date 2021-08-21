//
//  WhiteAppParam.h
//
//  Created by yleaf on 2021/8/21.
//

#import "WhiteObject.h"
#import "WhiteScene.h"

NS_ASSUME_NONNULL_BEGIN

@interface WhiteAppOptions : WhiteObject

@property (nonatomic, nullable, copy) NSString *scenePath;
@property (nonatomic, nullable, copy) NSString *title;
@property (nonatomic, nullable, strong) NSArray<WhiteScene *> *scenes;

@end


@interface WhiteAppParam : WhiteObject

@property (nonatomic, copy, readonly) NSString *kind;
@property (nonatomic, strong, readonly) WhiteAppOptions *options;
@property (nonatomic, copy, readonly) NSDictionary *attrs;

+ (instancetype)createDocsViewerApp:(NSString *)dir scenes:(NSArray <WhiteScene *>*)scenes title:(NSString *)title;
+ (instancetype)createMediaPlayerApp:(NSString *)src title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
