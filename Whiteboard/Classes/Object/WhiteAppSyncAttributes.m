//
//  WhiteAppSyncAttributes.m
//  Whiteboard
//
//  Created by xuyunshi on 2023/8/23.
//

#import "WhiteAppSyncAttributes.h"

@interface WhiteAppSyncAttributes ()
@property (nonatomic, copy, readwrite) NSString *kind;
@property (nonatomic, copy, readwrite) NSDictionary *options;
@property (nonatomic, copy, readwrite, nullable) NSString *src;
@property (nonatomic, copy, readwrite) NSDictionary *state;
@end

@implementation WhiteAppSyncAttributes

- (NSString *)title {
    return self.options[@"title"];
}

@end
