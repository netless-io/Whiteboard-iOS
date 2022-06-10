//
//  Hook.m
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/6/2.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "WhitePlayerEvent.h"

@interface PlayEventHook : NSObject<WhitePlayerEventDelegate>
@end

@implementation PlayEventHook

+ (void)load {
    Method originMethod = class_getInstanceMethod([WhitePlayerEvent class], @selector(setDelegate:));
    Method targetMethod = class_getInstanceMethod([WhitePlayerEvent class], @selector(hook_setDelegate:));
    method_exchangeImplementations(originMethod, targetMethod);
}

@end
