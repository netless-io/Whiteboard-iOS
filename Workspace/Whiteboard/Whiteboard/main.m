//
//  main.m
//  Whiteboard
//
//  Created by LM on 2021/4/30.
//

#import <UIKit/UIKit.h>
#import "NETAppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([NETAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
