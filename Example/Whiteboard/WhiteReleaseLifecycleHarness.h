// DEBUG Demo control channel for physical-device lifecycle tests. Not an SDK API.
#if DEBUG
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <unistd.h>
#import "Whiteboard.h"
#import "WhiteSDK+Room.h"

typedef void (^WhiteLifecycleReply)(id);
@interface WhiteReleaseLifecycleHost : NSObject <WhiteCommonCallbackDelegate>
@property (nonatomic, strong) WhiteBoardView *view;
@property (nonatomic, strong) WhiteSDK *sdk;
@property (nonatomic, strong) WhiteRoom *room;
@property (weak) WhiteBoardView *releasedView;
@property (weak) WhiteSDK *releasedSdk;
@property BOOL preloaded;
@property NSUInteger preloadCallbacks;
@property (nonatomic, strong) NSMutableArray *leaveLogs;
@property (nonatomic, strong) NSDictionary *preload;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableDictionary *> *jobs;
@end
@implementation WhiteReleaseLifecycleHost
- (void)logger:(NSDictionary *)log {
    if ([log[@"funName"] isEqual:@"leaveRoomFailed"]) [self.leaveLogs addObject:@{@"at":@(NSDate.date.timeIntervalSince1970*1000),@"message":log[@"message"] ?: @"",@"replacementPolicy":log[@"replacementPolicy"] ?: @""}];
}
- (void)onPreloadStateChange:(WhitePreloadResult *)result {
    self.preloadCallbacks++;
    self.preload=@{@"state":result.state ?: @"",@"message":result.message ?: @""};
}
@end

@interface WhiteReleaseLifecycleHarness : NSObject
@property (weak) UIView *container;
@property (nonatomic, strong) NSDictionary *fixture;
@property (nonatomic, strong) NSMutableDictionary<NSString *,WhiteReleaseLifecycleHost *> *hosts;
- (void)handle:(NSDictionary *)request reply:(WhiteLifecycleReply)reply;
@end
@implementation WhiteReleaseLifecycleHarness
- (NSDictionary *)error:(NSError *)error {
    return error ? @{@"message":error.localizedDescription ?: @"",@"code":@(error.code),@"domain":error.domain ?: @""} : nil;
}
- (void)newSDK:(WhiteReleaseLifecycleHost *)host {
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:self.fixture[@"appIdentifier"]];
    config.useMultiViews=YES;
    if([self.fixture[@"apiHosts"] isKindOfClass:NSArray.class])config.apiHosts=self.fixture[@"apiHosts"];
    if(host.preloaded){config.enableModelPreload=YES;config.preloadBuiltinApps=@[@"Slide",@"Presentation"];}
    host.sdk=[[WhiteSDK alloc] initWithWhiteBoardView:host.view config:config commonCallbackDelegate:host];
}
- (NSMutableDictionary *)job:(WhiteReleaseLifecycleHost *)host kind:(NSString *)kind {
    NSString *key=NSUUID.UUID.UUIDString;
    NSMutableDictionary *job=[@{@"id":key,@"kind":kind,@"callbacks":@0,@"done":@NO,@"started":@(NSDate.date.timeIntervalSince1970*1000)} mutableCopy];
    host.jobs[key]=job;return job;
}
- (void)complete:(NSMutableDictionary *)job success:(BOOL)success error:(NSError *)error {
    job[@"callbacks"]=@([job[@"callbacks"] unsignedIntegerValue]+1);
    job[@"done"]=@YES;job[@"success"]=@(success);job[@"error"]=[self error:error] ?: NSNull.null;
    job[@"ended"]=@(NSDate.date.timeIntervalSince1970*1000);
}
- (NSDictionary *)status:(WhiteReleaseLifecycleHost *)host {
    NSMutableDictionary *jobs=[NSMutableDictionary dictionary];
    for(NSString *key in host.jobs)jobs[key]=[host.jobs[key] copy];
    return @{@"pid":@(getpid()),@"view":[NSString stringWithFormat:@"%p",host.view],
             @"sdk":[NSString stringWithFormat:@"%p",host.sdk],@"room":[NSString stringWithFormat:@"%p",host.room],
             @"viewAlive":@(host.view!=nil),@"sdkAlive":@(host.sdk!=nil),
             @"releasedViewAlive":@(host.releasedView!=nil),@"releasedSdkAlive":@(host.releasedSdk!=nil),
             @"document":[host.view valueForKey:@"whiteDocument"] ?: NSNull.null,
             @"generation":[host.view valueForKey:@"whiteGeneration"] ?: NSNull.null,
             @"preloaded":@(host.preloaded),@"preloadCallbacks":@(host.preloadCallbacks),
             @"preload":host.preload ?: NSNull.null,@"leaveLogs":host.leaveLogs.copy ?: @[],@"jobs":jobs};
}
- (void)handle:(NSDictionary *)request reply:(WhiteLifecycleReply)reply {
    if(!self.hosts)self.hosts=[NSMutableDictionary dictionary];
    NSString *command=request[@"command"],*key=request[@"host"];
    if([command isEqual:@"reset"]){
        for(WhiteReleaseLifecycleHost *host in self.hosts.allValues){[host.view removeFromSuperview];host.view=nil;}
        [self.hosts removeAllObjects];reply(@{@"reset":@YES});return;
    }
    if([command isEqual:@"create"]){
        if(!key.length||self.hosts[key]){reply(@{@"error":@"Host key missing or already exists"});return;}
        WhiteReleaseLifecycleHost *host=[WhiteReleaseLifecycleHost new];host.jobs=[NSMutableDictionary dictionary];host.leaveLogs=[NSMutableArray array];host.preloaded=[request[@"preloaded"] boolValue];
        WKWebViewConfiguration *web=[WKWebViewConfiguration new];
        NSString *wire=@"(function(){var Original=window.WebSocket,w=window.__lifecycleWire={sockets:[],events:[]};function Wrapped(url,protocols){var s=protocols===undefined?new Original(url):new Original(url,protocols),id=w.sockets.push(s);w.events.push({at:Date.now(),type:'construct',id:id});s.addEventListener('open',function(){w.events.push({at:Date.now(),type:'open',id:id})});s.addEventListener('close',function(e){w.events.push({at:Date.now(),type:'close',id:id,code:e.code})});var close=s.close.bind(s);s.close=function(){w.events.push({at:Date.now(),type:'closing',id:id});return close.apply(null,arguments)};return s}Wrapped.prototype=Original.prototype;Object.setPrototypeOf(Wrapped,Original);window.WebSocket=Wrapped})()";
        [web.userContentController addUserScript:[[WKUserScript alloc] initWithSource:wire injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
        host.view=[[WhiteBoardView alloc] initWithFrame:self.container.bounds configuration:web];
        host.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.container addSubview:host.view];self.hosts[key]=host;[self newSDK:host];
        reply([self status:host]);return;
    }
    WhiteReleaseLifecycleHost *host=self.hosts[key];
    if(!host){reply(@{@"error":@"Unknown lifecycle host"});return;}
    if([command isEqual:@"status"]){reply([self status:host]);return;}
    if([command isEqual:@"eval"]){
        if(!host.view){reply(@{@"error":@"Host view released"});return;}
        NSData *data=[NSJSONSerialization dataWithJSONObject:request[@"expression"] ?: @"null" options:NSJSONWritingFragmentsAllowed error:nil];
        NSString *quoted=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *source=[NSString stringWithFormat:@"JSON.stringify((function(){var v=(0,eval)(%@);return v===undefined?null:v})())",quoted];
        [host.view evaluateJavaScript:source completionHandler:^(id value,NSError *error){reply(error?@{@"error":error.localizedDescription}:@{@"json":value ?: @"null"});}];return;
    }
    if([command isEqual:@"removeView"]){[host.view removeFromSuperview];reply([self status:host]);return;}
    if([command isEqual:@"destroy"]){host.releasedView=host.view;[host.view removeFromSuperview];host.view=nil;reply([self status:host]);return;}
    if([command isEqual:@"dropSDK"]){host.releasedSdk=host.sdk;host.sdk=nil;reply([self status:host]);return;}
    if([command isEqual:@"newSDK"]){
        if(host.sdk||!host.view){reply(@{@"error":@"Release the old Native SDK and retain its View before newSDK"});return;}
        [self newSDK:host];reply([self status:host]);return;
    }
    BOOL roomDisconnect=[command isEqual:@"disconnect"];
    if(!host.sdk&&!roomDisconnect){reply(@{@"error":@"Host Native SDK released"});return;}
    if(roomDisconnect&&!host.room){reply(@{@"error":@"Host Native Room unavailable"});return;}
    NSMutableDictionary *job=[self job:host kind:command];
    if([command isEqual:@"join"]){
        BOOL other=[request[@"otherRoom"] boolValue];
        WhiteRoomConfig *config=[[WhiteRoomConfig alloc] initWithUUID:self.fixture[other?@"otherUuid":@"uuid"] roomToken:self.fixture[other?@"otherRoomToken":@"roomToken"] uid:request[@"uid"]];
        config.region=WhiteRegionCN;config.isWritable=NO;config.windowParams=[WhiteWindowParams new];
        [host.sdk joinRoomWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){host.room=room;[self complete:job success:success error:error];}];
    }else if([command isEqual:@"prepare"]){
        [host.sdk prepareWithTimeout:45 completionHandler:^(NSError *error){[self complete:job success:error==nil error:error];}];
    }else if([command isEqual:@"leave"]){
        [host.sdk leaveRoomWithCompletionHandler:^(NSError *error){[self complete:job success:error==nil error:error];}];
    }else if(roomDisconnect){
        [host.room disconnect:^{[self complete:job success:YES error:nil];}];
    }else{[host.jobs removeObjectForKey:job[@"id"]];reply(@{@"error":@"Unknown lifecycle command"});return;}
    reply(@{@"job":job[@"id"]});
}
@end
#endif
