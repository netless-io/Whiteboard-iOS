"""Run production callback methods and Slide JSON serialization on Foundation.

This boundary probe is not an iOS/WKWebView device test.
"""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
classes = repo / 'Whiteboard/Classes'
sdk = (classes / 'SDK/WhiteSDK.m').read_text()
methods = sdk[sdk.index('- (void)whiteObservePreload'):sdk.index('- (void)whiteBindCommonCallback')]
header = (classes / 'Displayer/WhiteCommonCallbacks.h').read_text()
dto_header = header[header.index('@interface WhitePreloadResult'):header.index('@interface WhiteBackgroundImageLoadEvent')]
source = (classes / 'Displayer/WhiteCommonCallbacks.m').read_text()
dto = source[source.index('@implementation WhitePreloadResult'):source.index('@implementation WhiteBackgroundImageLoadEvent')]
prefix = r'''
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "WhiteSlideAppParams.h"
'''
fixture = r'''
@protocol WhiteCommonCallbackDelegate <NSObject>
- (void)onPreloadStateChange:(WhitePreloadResult *)result;
@end
@interface CommonCallbacks : NSObject
@property (weak) id delegate;
@end
@implementation CommonCallbacks
@end
@interface WhiteBoardView : NSObject
@property (weak) id whiteCallbackOwner;
@property NSUInteger revision;
@property (strong) CommonCallbacks *commonCallbacks;
@property (copy) void (^reply)(id);
- (NSUInteger)whitePreparationRevision;
- (void)callHandler:(NSString *)method arguments:(NSArray *)args completionHandler:(void (^)(id))completion;
@end
@implementation WhiteBoardView
- (NSUInteger)whitePreparationRevision { return self.revision; }
- (void)callHandler:(NSString *)method arguments:(NSArray *)args completionHandler:(void (^)(id))completion { self.reply=completion; }
@end
@interface Listener : NSObject <WhiteCommonCallbackDelegate>
@property NSUInteger calls;
@property (strong) WhitePreloadResult *result;
@end
@implementation Listener
- (void)onPreloadStateChange:(WhitePreloadResult *)result {
 NSCAssert(NSThread.isMainThread,@"must deliver on main thread");self.calls++;self.result=result;
}
@end
@interface WhiteSDK : NSObject
@property (strong) WhiteBoardView *bridge;
@property (copy) NSDictionary *initializationConfiguration,*preparationInfo;
@property (strong) WhitePreloadResult *preloadResult;
@property (copy) NSString *preloadDocument;
@property NSUInteger preloadRevision;
@property BOOL preloadObserved,preloadDelivered;
@property (nonatomic, weak) id<WhiteCommonCallbackDelegate> commonCallbackDelegate;
- (void)whiteObservePreload;
- (void)whiteDeliverPreloadResult;
@end
@implementation WhiteSDK
'''
main = r'''
@end
static void drain(void) { CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.02,false); }
static WhiteSDK *make(void) {
 WhiteSDK *sdk=[WhiteSDK new];sdk.bridge=[WhiteBoardView new];sdk.bridge.whiteCallbackOwner=sdk;
 sdk.bridge.commonCallbacks=[CommonCallbacks new];sdk.initializationConfiguration=@{};
 sdk.preparationInfo=@{@"ready":@YES,@"documentId":@"document"};return sdk;
}
int main(void) { @autoreleasepool {
 WhiteSlideAppParams *slide=[WhiteSlideAppParams new];
 NSCAssert([slide.jsonDict[@"enableSharedMediaVolume"] isEqual:@NO],@"actual Slide JSON default false");
 slide.enableSharedMediaVolume=YES;
 NSDictionary *wire=[NSJSONSerialization JSONObjectWithData:[slide.jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
 NSCAssert([wire[@"enableSharedMediaVolume"] isEqual:@YES],@"actual Slide JSON preserves true");
 slide.enableSharedMediaVolume=NO;NSCAssert([slide.jsonDict[@"enableSharedMediaVolume"] isEqual:@NO],@"explicit false preserved");
 NSCAssert((![[WhitePreloadResult alloc]initWithDictionary:@{@"state":@"warn",@"message":@""}]),@"invalid warn rejected");
 Listener *a=[Listener new],*b=[Listener new];WhiteSDK *sdk=make();[sdk whiteObservePreload];
 sdk.bridge.reply(@"{\"state\":\"warn\",\"message\":\"Slide failed\"}");drain();
 NSCAssert(a.calls==0,@"buffer until subscribed");sdk.commonCallbackDelegate=a;drain();
 NSCAssert(a.calls==1&&[a.result.state isEqual:@"warn"],@"late warn delivered once");
 sdk.commonCallbackDelegate=b;sdk.bridge.reply(@"{\"state\":\"success\",\"message\":\"\"}");drain();
 NSCAssert(a.calls==1&&b.calls==0,@"normal retry/listener replacement does not redeliver");
 for(NSUInteger mode=0;mode<3;mode++) {
  WhiteSDK *old=make();Listener *listener=[Listener new];old.commonCallbackDelegate=listener;[old whiteObservePreload];
  if(mode==0)old.bridge.revision++;
  if(mode==1)old.bridge.whiteCallbackOwner=nil;
  if(mode==2)old.preparationInfo=@{@"ready":@YES,@"documentId":@"new-document"};
  old.bridge.reply(@"{\"state\":\"success\",\"message\":\"\"}");drain();
  NSCAssert(listener.calls==0,@"cancelled/replaced/document-stale completion dropped");
 }
 puts("PASS actual Objective-C preload callback buffering, once-only delivery, stale owner/revision/document and Slide boolean JSON");
} return 0; }
'''
with tempfile.TemporaryDirectory(prefix='whiteboard-ios-preload-') as directory:
    test = Path(directory) / 'test.m'
    test.write_text(prefix + dto_header + dto + fixture + methods + main)
    vendor = repo / 'Example/Pods/White_YYModel/White_YYModel'
    binary = Path(directory) / 'test'
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-Wno-incompatible-pointer-types',
                    '-framework', 'Foundation', '-framework', 'CoreFoundation',
                    '-I', str(classes / 'Model'), '-I', str(classes / 'SDK'), '-I', str(vendor),
                    str(test), str(classes / 'Model/WhiteObject.m'), str(classes / 'SDK/WhiteSlideAppParams.m'),
                    str(vendor / 'NSObject+White_YYModel.m'), str(vendor / 'White_YYClassInfo.m'),
                    '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
