"""Run actual preparation method bodies against Foundation state/transport stubs.

No repository source or iOS app is modified; this is a macOS Objective-C
boundary probe, not a WKWebView or iOS device test.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]

source = (root / 'repos/Whiteboard-iOS/Whiteboard/Classes/Displayer/WhiteBoardView.m').read_text()
methods = source[source.index('- (void)whiteFinishPreparation:'):source.index('- (void)setupWebSDKWithConfig:')]
sdk_source = (root / 'repos/Whiteboard-iOS/Whiteboard/Classes/SDK/WhiteSDK.m').read_text()
public_method = sdk_source[sdk_source.index('- (void)prepareWithTimeout:'):sdk_source.index('- (void)cancelPreparation')]

prefix = r'''
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#include <math.h>
#define dispatch_main_async_safe(block) if ([NSThread isMainThread]) { block(); } else { dispatch_async(dispatch_get_main_queue(), block); }
static NSError *WhiteLifecycleError(NSString *message) {
    return [NSError errorWithDomain:@"WhiteLifecycle" code:-1100 userInfo:@{NSLocalizedDescriptionKey:message}];
}
@interface WhiteBoardView : NSObject
@property BOOL whiteInvalid, whitePrepared;
@property NSUInteger whitePreparationEpoch, whiteSetupCount;
@property NSTimeInterval whitePreparationElapsed, whitePreparationStarted;
@property (copy) NSDictionary *whitePreparationConfiguration;
@property (strong) NSMutableArray *whitePreparationWaiters;
@property (strong) NSMutableArray *whiteReady, *setups, *setupCallbacks;
@property (copy) NSString *whiteState, *whiteDocument;
- (void)whitePrepareConfiguration:(NSDictionary *)configuration timeout:(NSTimeInterval)timeout completion:(void (^)(NSError *))completion;
- (void)whitePrepareConfiguration:(NSDictionary *)configuration timeout:(NSTimeInterval)timeout admitted:(BOOL)admitted completion:(void (^)(NSError *))completion;
- (void)whiteCancelPreparation;
@end
@implementation WhiteBoardView
- (instancetype)init {
    if ((self = [super init])) {
        self.whiteState = @"idle"; self.whiteDocument = @"document";
        self.whiteReady = [NSMutableArray new]; self.setups = [NSMutableArray new]; self.setupCallbacks = [NSMutableArray new];
    }
    return self;
}
- (void)whiteLogPreload:(NSString *)event {}
- (void)whiteCall:(NSString *)method arguments:(NSArray *)args generation:(NSNumber *)generation completion:(void (^)(id))completion {
    [self.setups addObject:args.firstObject];
    [self.setupCallbacks addObject:[completion copy]];
}
'''
suffix = r'''
@end
@interface WhiteSDK : NSObject
@property (strong) WhiteBoardView *bridge;
@property (copy) NSDictionary *initializationConfiguration;
- (void)prepareWithTimeout:(NSTimeInterval)timeout completionHandler:(void (^)(NSError *))completion;
@end
@implementation WhiteSDK
'''
main = r'''
@end
int main(void) {
 @autoreleasepool {
  NSDictionary *aConfig = @{@"appIdentifier":@"app", @"enableModelPreload":@NO};
  NSDictionary *bConfig = @{@"appIdentifier":@"app", @"enableModelPreload":@YES};
  for (NSUInteger mode=0;mode<4;mode++) {
   WhiteBoardView *view=[WhiteBoardView new];
   WhiteSDK *a=[WhiteSDK new];a.bridge=view;a.initializationConfiguration=aConfig;
   WhiteSDK *b=[WhiteSDK new];b.bridge=view;b.initializationConfiguration=bConfig;
   __block NSUInteger bSuccess=0,bCancelled=0,retrySuccess=0;
   [a prepareWithTimeout:15 completionHandler:^(NSError *error) {
    NSCAssert([error.localizedDescription isEqualToString:@"Cancelled"], @"old A must be cancelled");
    if(mode==0) [a prepareWithTimeout:15 completionHandler:^(NSError *e){if(!e)retrySuccess++;}];
    if(mode==1) [b prepareWithTimeout:15 completionHandler:^(NSError *e){if(!e)retrySuccess++;}];
    if(mode==2) [view whiteCancelPreparation];
    if(mode==3) {view.whiteInvalid=YES;[view whiteCancelPreparation];}
   }];
   void (^late)(id)=view.setupCallbacks.firstObject;
   [b prepareWithTimeout:15 completionHandler:^(NSError *e){if(!e)bSuccess++;else if([e.localizedDescription isEqualToString:@"Cancelled"])bCancelled++;}];
   late(@"{}");
   NSCAssert(bSuccess==0, @"late setup must never report B ready");
   NSCAssert(view.setups.count==(mode<2?2:1), @"only current attempt may dispatch setup");
   if(mode<2) {void (^complete)(id)=view.setupCallbacks.lastObject;complete(@"{}");}
   NSCAssert(bSuccess==(mode==1?1:0), @"B can succeed only when its configuration was actually set up");
   NSCAssert(bCancelled==(mode==1?0:1), @"superseded B must be cancelled exactly once");
   NSCAssert(retrySuccess==(mode<2?1:0), @"reentrant callers complete once");
   if(mode<2) {
    NSCAssert([view.whitePreparationConfiguration isEqual:mode==0?aConfig:bConfig], @"actual configuration must match successful caller");
    __block BOOL cached=NO;WhiteSDK *current=mode==0?a:b;
    [current prepareWithTimeout:15 completionHandler:^(NSError *e){cached=!e;}];
    NSCAssert(cached && view.setups.count==2, @"same configuration must reuse ready setup");
   }
  }
  puts("4 actual Objective-C public prepare reentry/cancellation cases passed, including late responses and ready cache");
 }
 return 0;
}
'''
with tempfile.TemporaryDirectory(prefix='whiteboard-ios-prepare-regression-') as build_dir:
 fixture=Path(build_dir)/'test.m'
 fixture.write_text(prefix+methods+suffix+public_method+main)
 binary=Path(build_dir)/'test'
 subprocess.run(['xcrun','clang','-fobjc-arc','-fblocks','-Wno-incompatible-pointer-types','-framework','Foundation',str(fixture),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
