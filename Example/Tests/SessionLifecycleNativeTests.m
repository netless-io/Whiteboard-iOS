#import <XCTest/XCTest.h>
#import "Whiteboard.h"
#import "WhiteSDK+Room.h"
#import "SessionLifecycleProbe.h"
#import "../../Whiteboard/Classes/Displayer/WhiteBoardView+Private.h"
#import "../../Whiteboard/Classes/SDK/WhiteSDK+Private.h"
#import "../../Whiteboard/Classes/Displayer/WhiteCommonCallbacks.h"
#if __has_include("SessionLifecycleConfig.local.h")
#import "SessionLifecycleConfig.local.h"
#else
static NSString * const SessionAppIdentifier = @"";
static NSString * const SessionRoomUuid = @"";
static NSString * const SessionRoomToken = @"";
#endif

@interface LifecycleCommonCounter : NSObject <WhiteCommonCallbackDelegate>
@property NSUInteger pauses;
@end
@implementation LifecycleCommonCounter
- (void)pptMediaPause { self.pauses++; }
@end

@interface SessionLifecycleNativeTests : XCTestCase
@property WhiteBoardView *board;
@property WhiteSDK *sdk;
@property WhiteRoom *room;
@property NSMutableDictionary *evidence;
@property NSString *uid;
@property BOOL expectBlocked;
@end
@implementation SessionLifecycleNativeTests
- (id)js:(NSString *)source {
    XCTestExpectation *done = [self expectationWithDescription:@"js"];
    __block id value;
    [self.board evaluateJavaScript:source completionHandler:^(id result, NSError *error) { XCTAssertNil(error); value=result; [done fulfill]; }];
    [self waitForExpectations:@[done] timeout:15]; return value;
}
- (void)pause:(NSTimeInterval)seconds {
    XCTestExpectation *done = [self expectationWithDescription:@"observe"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{[done fulfill];});
    [self waitForExpectations:@[done] timeout:seconds+5];
}
- (NSDictionary *)snapshot:(NSString *)name {
    NSString *json=[self js:@"JSON.stringify(window.__lifecycleProbe.snapshot())"];
    NSDictionary *data=[NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqual([data[@"sensorErrors"] count],0); self.evidence[name]=data; return data;
}
- (NSUInteger)open:(NSDictionary *)snapshot {
    NSUInteger count=0; for (NSDictionary *socket in snapshot[@"sockets"]) if ([socket[@"state"] integerValue]==1) count++; return count;
}
- (WhiteRoomConfig *)config {
    WhiteRoomConfig *config=[[WhiteRoomConfig alloc] initWithUUID:SessionRoomUuid roomToken:SessionRoomToken uid:self.uid];
    config.region=WhiteRegionCN; config.isWritable=NO; config.windowParams=[[WhiteWindowParams alloc] init]; return config;
}
- (void)join {
    XCTestExpectation *done=[self expectationWithDescription:@"join"];
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertNil(error);XCTAssertTrue(success);self.room=room;[done fulfill];}];
    [self waitForExpectations:@[done] timeout:60];
}
- (void)rejectDuplicate {
    XCTestExpectation *done=[self expectationWithDescription:@"reject duplicate"];
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertFalse(success);XCTAssertNotNil(error);NSError *closeError=[self.board valueForKey:@"whiteCloseError"];XCTAssertEqualObjects(error.localizedDescription,closeError.localizedDescription ?: @"StaleScope");[done fulfill];}];
    [self waitForExpectations:@[done] timeout:5];
}
- (void)leave {
    XCTestExpectation *done=[self expectationWithDescription:@"leave"];
    [self.sdk leaveRoomWithCompletionHandler:^(NSError *error){XCTAssertNil(error);[done fulfill];}];
    [self waitForExpectations:@[done] timeout:25];
}
- (void)setUp {
    [super setUp]; self.continueAfterFailure=NO;
    XCTAssertTrue(SessionRoomToken.length>0,@"Local test credentials are required");
    self.evidence=[NSMutableDictionary dictionary]; self.uid=[@"ios-lifecycle-candidate-" stringByAppendingString:NSUUID.UUID.UUIDString];
    WKWebViewConfiguration *web=[[WKWebViewConfiguration alloc] init];
    NSString *relay=@"(function(){var Original=window.WebSocket;function Routed(url,protocols){if(/^wss:\\/\\//.test(url))url='ws://127.0.0.1:18765/relay?group=ios&target='+encodeURIComponent(url);return protocols===undefined?new Original(url):new Original(url,protocols)}Routed.prototype=Original.prototype;['CONNECTING','OPEN','CLOSING','CLOSED'].forEach(function(k){Routed[k]=Original[k]});window.WebSocket=Routed})()";
    [web.userContentController addUserScript:[[WKUserScript alloc] initWithSource:relay injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
    self.board=[[WhiteBoardView alloc] initWithFrame:UIScreen.mainScreen.bounds configuration:web];
    [UIApplication.sharedApplication.keyWindow.rootViewController.view addSubview:self.board];
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:SessionAppIdentifier];config.useMultiViews=YES;config.enableAppliancePlugin=YES;
    self.sdk=[[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:40];
    while(![[self js:SessionLifecycleProbeJS] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
}
- (void)tearDown {
    self.continueAfterFailure=YES;
    [self gate:NO];
    if(self.sdk && !self.expectBlocked) [self leave];
    if(self.board){[self pause:.3];if([[self js:@"!!window.__lifecycleProbe"] boolValue])[self snapshot:@"final"];else self.evidence[@"documentDiscarded"]=@YES;NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"session-candidate-%@.json",self.name]];
        [[NSJSONSerialization dataWithJSONObject:self.evidence options:NSJSONWritingPrettyPrinted error:nil] writeToFile:path atomically:YES];NSLog(@"SESSION_CANDIDATE_EVIDENCE %@",path);[self.board removeFromSuperview];}
    self.sdk=nil;self.board=nil;[super tearDown];
}
- (void)testMutableParametersSnapshot {
    WhiteRoomConfig *config=[self config];NSString *expectedUid=config.uid;
    XCTestExpectation *done=[self expectationWithDescription:@"captured join"];
    [self.sdk joinRoomWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertNil(error);XCTAssertTrue(success);self.room=room;[done fulfill];}];
    config.timeout=@.001;config.isWritable=YES;
    [self waitForExpectations:@[done] timeout:60];
    NSDictionary *data=[self snapshot:@"capturedParameters"];XCTAssertEqualObjects(data[@"rooms"][0][@"uid"],expectedUid);XCTAssertEqual([self open:data],1);[self leave];
}
- (void)testDelayedSetupUsesConfiguredDeadlineAndRejectsPlayer {
    [self js:@"var f=window.bridge.getFunction('sdk.newWhiteSdk').function;window.bridge.registerAsync('sdk.newWhiteSdk',function(){var a=[].slice.call(arguments),reply=a.pop();a.push(function(v){setTimeout(function(){reply(v)},1800)});return f.apply(null,a)});true"];
    WhiteRoomConfig *config=[self config];config.timeout=@.6;
    XCTestExpectation *done=[self expectationWithDescription:@"configured timeout"];__block NSUInteger calls=0;
    [self.sdk joinRoomWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){calls++;XCTAssertFalse(success);XCTAssertEqualObjects(error.localizedDescription,@"JoinTimeout");[done fulfill];}];
    [self pause:.2];XCTAssertNil([self.board whiteBeginWithCancellation:^(NSError *error){}]);
    [self waitForExpectations:@[done] timeout:3];[self pause:2];XCTAssertEqual(calls,1);XCTAssertEqual([[self snapshot:@"lateSetupNoJoin"][@"joinStarts"] integerValue],0);[self leave];
}
- (void)testReleaseDuplicateLeaveAndRejoin {
    [self join];WhiteRoom *old=self.room;NSString *previous=[self snapshot:@"joined"][@"rooms"][0][@"session"];
    self.board.room=nil;id callbacks=[self.board valueForKey:@"roomCallbacks"];[callbacks setValue:nil forKey:@"room"];[callbacks setValue:nil forKey:@"delegate"];
    [self join];XCTAssertNotEqual(old,self.room);NSDictionary *replaced=[self snapshot:@"afterReplacement"];
    XCTAssertEqual([replaced[@"joinStarts"] integerValue],2);XCTAssertEqual([self open:replaced],1);
    XCTAssertNotEqualObjects(previous,replaced[@"rooms"][1][@"session"]);XCTAssertNotEqual([replaced[@"sockets"][0][@"state"] integerValue],1);
    [self pause:31];XCTAssertEqual([self open:[self snapshot:@"replacementAfter31s"]],1);
    [old setGlobalState:(WhiteGlobalState *)@{@"staleHandleMustNotWrite":@YES}];[self pause:.3];
    XCTAssertFalse([[[self js:@"window.room.state.globalState"] objectForKey:@"staleHandleMustNotWrite"] boolValue]);[self leave];
}
- (void)testCancelLateSuccessCompletesOnce {
    [self js:@"window.__originalJoin=window.sdk.joinRoom;window.sdk.joinRoom=function(p,c){return window.__originalJoin(p,c).then(function(r){return new Promise(function(done){setTimeout(function(){done(r)},4000)})})};true"];
    XCTestExpectation *cancel=[self expectationWithDescription:@"cancelled"];
    __block NSUInteger callbacks=0;
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){callbacks++;XCTAssertFalse(success);XCTAssertEqualObjects(error.localizedDescription,@"Cancelled");[cancel fulfill];}];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:25];
    while(![[self snapshot:@"pending"][@"rooms"] count]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
    XCTestExpectation *left=[self expectationWithDescription:@"left"];
    [self.sdk leaveRoomWithCompletionHandler:^(NSError *error){XCTAssertNil(error);[left fulfill];}];
    [self waitForExpectations:@[cancel] timeout:5];[self waitForExpectations:@[left] timeout:20];
    [self pause:.5];XCTAssertEqual(callbacks,1);NSDictionary *final=[self snapshot:@"lateCleanup"];XCTAssertEqual([final[@"joinStarts"] integerValue],1);XCTAssertEqual([self open:final],0);
}
- (void)testSecondFacadeReplacesRoomOnSameView {
    [self join];WhiteRoom *old=self.room;
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:SessionAppIdentifier];config.useMultiViews=YES;config.enableAppliancePlugin=YES;
    self.sdk=[[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config];XCTAssertNotNil(self.sdk);
    [self join];XCTAssertNotEqual(old,self.room);NSDictionary *data=[self snapshot:@"secondFacadeReplacement"];
    XCTAssertEqual([data[@"joinStarts"] integerValue],2);XCTAssertEqual([self open:data],1);[self leave];
}
- (void)testNewWebViewReplacesDetachedOldHost {
    [self join];WhiteBoardView *oldBoard=self.board;WhiteRoom *oldRoom=self.room;
    [oldBoard removeFromSuperview];oldBoard.room=nil;
    WKWebViewConfiguration *web=[WKWebViewConfiguration new];
    for(WKUserScript *script in oldBoard.configuration.userContentController.userScripts) if([script.source containsString:@"/relay?group=ios"]) [web.userContentController addUserScript:script];
    self.board=[[WhiteBoardView alloc] initWithFrame:UIScreen.mainScreen.bounds configuration:web];
    [UIApplication.sharedApplication.keyWindow.rootViewController.view addSubview:self.board];
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:SessionAppIdentifier];config.useMultiViews=YES;config.enableAppliancePlugin=YES;
    self.sdk=[[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:40];while(![[self js:SessionLifecycleProbeJS] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
    [self join];XCTAssertNotEqual(oldRoom,self.room);NSDictionary *fresh=[self snapshot:@"newHost"];
    XCTAssertEqual([fresh[@"joinStarts"] integerValue],1);XCTAssertEqual([self open:fresh],1);
    WhiteBoardView *newBoard=self.board;self.board=oldBoard;NSDictionary *closed=[self snapshot:@"oldHost"];self.board=newBoard;
    XCTAssertEqual([self open:closed],0);XCTAssertEqual([closed[@"joinStarts"] integerValue],1);[self leave];
}
- (void)testConcurrentIdentitySwitchDoesNotDisconnectOtherUid {
    [self join];WhiteBoardView *aBoard=self.board;WhiteSDK *aSDK=self.sdk;NSString *k1=self.uid;
    WKWebViewConfiguration *web=[WKWebViewConfiguration new];
    for(WKUserScript *script in aBoard.configuration.userContentController.userScripts) if([script.source containsString:@"/relay?group=ios"]) [web.userContentController addUserScript:script];
    WhiteBoardView *bBoard=[[WhiteBoardView alloc] initWithFrame:UIScreen.mainScreen.bounds configuration:web];
    [UIApplication.sharedApplication.keyWindow.rootViewController.view addSubview:bBoard];self.board=bBoard;
    WhiteSdkConfiguration *sdkConfig=[[WhiteSdkConfiguration alloc] initWithApp:SessionAppIdentifier];sdkConfig.useMultiViews=YES;sdkConfig.enableAppliancePlugin=YES;
    WhiteSDK *bSDK=[[WhiteSDK alloc] initWithWhiteBoardView:bBoard config:sdkConfig];self.sdk=bSDK;self.uid=[k1 stringByAppendingString:@"-B"];
    @try {
        NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:40];while(![[self js:SessionLifecycleProbeJS] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}[self join];[self snapshot:@"B-before"];
        [self js:@"var f=window.bridge.getFunction('sdk.leaveRoom').function;window.bridge.registerAsync('sdk.leaveRoom',function(){window.bridge.registerAsync('sdk.leaveRoom',f);var a=[].slice.call(arguments),reply=a.pop();a.push(function(v){window.__heldLeave=function(){reply(v)}});return f.apply(null,a)});true"];
        self.uid=k1;XCTestExpectation *joined=[self expectationWithDescription:@"B target join"];
        [bSDK joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertTrue(success);XCTAssertNil(error);[joined fulfill];}];
        deadline=[NSDate dateWithTimeIntervalSinceNow:15];while(![[self js:@"typeof window.__heldLeave==='function'"] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
        XCTAssertEqual([self open:[self snapshot:@"B-local-closed-receipt-held"]],0);
        self.board=aBoard;self.sdk=aSDK;self.uid=[k1 stringByAppendingString:@"-C"];[self join];NSDictionary *before=[self snapshot:@"A-new-uid-before-B-resume"];
        self.board=bBoard;self.sdk=bSDK;[self js:@"window.__heldLeave();true"];[self waitForExpectations:@[joined] timeout:60];
        NSDictionary *bJoined=[self snapshot:@"B-target-joined"];XCTAssertEqual([bJoined[@"joinStarts"] integerValue],2);XCTAssertEqual([self open:bJoined],1);XCTAssertEqualObjects(bJoined[@"rooms"][1][@"uid"],k1);
        self.board=aBoard;self.sdk=aSDK;[self pause:2];NSDictionary *after=[self snapshot:@"A-new-uid-still-connected"];
        XCTAssertEqual([after[@"joinStarts"] integerValue],2);XCTAssertEqual([self open:after],1);XCTAssertEqualObjects(after[@"rooms"][1][@"phase"],@"connected");XCTAssertEqualObjects(before[@"rooms"][1][@"connectionSession"],after[@"rooms"][1][@"connectionSession"]);
    } @finally {
        self.board=bBoard;self.sdk=bSDK;[self js:@"if(window.__heldLeave)window.__heldLeave();true"];[self leave];[self snapshot:@"B-cleanup"];[bBoard removeFromSuperview];self.board=aBoard;self.sdk=aSDK;self.uid=[k1 stringByAppendingString:@"-C"];
    }
    [self leave];
}
- (void)commonPause {
    NSDictionary *scope=@{@"documentId":[self.board valueForKey:@"whiteDocument"],@"generation":[self.board valueForKey:@"whiteGeneration"]};
    NSString *json=[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:scope options:0 error:nil] encoding:NSUTF8StringEncoding];
    [self js:[NSString stringWithFormat:@"window.bridge.call('sdk.onPPTMediaPause',{scope:%@,value:{}});true",json]];[self pause:.15];
}
- (void)testCommonCallbackFollowsLastJoiningFacade {
    LifecycleCommonCounter *ca=[LifecycleCommonCounter new],*cb=[LifecycleCommonCounter new],*changed=[LifecycleCommonCounter new];
    WhiteSDK *a=self.sdk;[a setCommonCallbackDelegate:ca];[self join];[self commonPause];XCTAssertEqual(ca.pauses,1);
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:SessionAppIdentifier];config.useMultiViews=YES;config.enableAppliancePlugin=YES;
    WhiteSDK *b=[[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config commonCallbackDelegate:cb];
    [self commonPause];XCTAssertEqual(ca.pauses,2);XCTAssertEqual(cb.pauses,0);
    self.sdk=b;[self join];[self commonPause];XCTAssertEqual(cb.pauses,1);
    self.sdk=a;[self join];[self commonPause];XCTAssertEqual(ca.pauses,3);XCTAssertEqual(cb.pauses,1);
    [b setCommonCallbackDelegate:nil];[self commonPause];XCTAssertEqual(ca.pauses,4);
    self.sdk=b;[self join];[self commonPause];XCTAssertNil(self.board.commonCallbacks.delegate);XCTAssertEqual(ca.pauses,4);XCTAssertEqual(cb.pauses,1);
    self.sdk=a;[self join];[a setCommonCallbackDelegate:changed];[self commonPause];XCTAssertEqual(changed.pauses,1);
    NSDictionary *data=[self snapshot:@"commonCallbacksABA"];XCTAssertEqual([data[@"joinStarts"] integerValue],5);XCTAssertEqual([self open:data],1);
    self.evidence[@"callbackCounts"]=@{@"A":@(ca.pauses),@"B":@(cb.pauses),@"updatedA":@(changed.pauses)};[self leave];
}
- (void)testPendingReplacementCancelsOldAndActuallyJoinsAgain {
    [self js:@"var original=window.sdk.joinRoom;window.sdk.joinRoom=function(p,c){return original.call(this,p,c).then(function(r){return new Promise(function(done){setTimeout(function(){done(r)},4000)})})};true"];
    XCTestExpectation *oldDone=[self expectationWithDescription:@"old cancelled"];__block NSUInteger calls=0;
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){calls++;XCTAssertFalse(success);XCTAssertEqualObjects(error.localizedDescription,@"Cancelled");[oldDone fulfill];}];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:25];while(![[self snapshot:@"firstPending"][@"rooms"] count]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
    [self join];[self waitForExpectations:@[oldDone] timeout:2];XCTAssertEqual(calls,1);
    NSDictionary *final=[self snapshot:@"pendingReplaced"];XCTAssertEqual([final[@"joinStarts"] integerValue],2);XCTAssertEqual([self open:final],1);XCTAssertNotEqual([final[@"sockets"][0][@"state"] integerValue],1);[self leave];
}
- (void)testQueuedJoinThenLeaveCancelsReplacement {
    [self join];XCTestExpectation *cancelled=[self expectationWithDescription:@"queued cancelled"];
    XCTestExpectation *left=[self expectationWithDescription:@"queued left"];
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertFalse(success);XCTAssertEqualObjects(error.localizedDescription,@"Cancelled");[cancelled fulfill];}];
    [self.sdk leaveRoomWithCompletionHandler:^(NSError *error){XCTAssertNil(error);[left fulfill];}];
    [self waitForExpectations:@[cancelled,left] timeout:25];NSDictionary *result=[self snapshot:@"queuedJoinThenLeave"];
    XCTAssertEqual([result[@"joinStarts"] integerValue],1);XCTAssertEqual([self open:result],0);
}
- (void)testLastQueuedRequestWins {
    [self join];NSMutableArray<XCTestExpectation *> *done=[NSMutableArray array];__block NSUInteger cancelled=0;
    for(NSUInteger index=0;index<3;index++) {
        XCTestExpectation *result=[self expectationWithDescription:[NSString stringWithFormat:@"request %lu",(unsigned long)index]];[done addObject:result];
        [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){if(index<2){XCTAssertFalse(success);XCTAssertEqualObjects(error.localizedDescription,@"Cancelled");cancelled++;}else{XCTAssertTrue(success);XCTAssertNil(error);self.room=room;}[result fulfill];}];
    }
    [self waitForExpectations:done timeout:40];XCTAssertEqual(cancelled,2);NSDictionary *data=[self snapshot:@"latestOnly"];XCTAssertEqual([data[@"joinStarts"] integerValue],2);XCTAssertEqual([self open:data],1);[self leave];
}

- (void)gate:(BOOL)blocked {
    NSString *url=[NSString stringWithFormat:@"http://127.0.0.1:18765/control?group=ios&block=%d",blocked];
    XCTestExpectation *done=[self expectationWithDescription:@"relay gate"];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data,NSURLResponse *response,NSError *error){XCTAssertNil(error);[done fulfill];}] resume];
    [self waitForExpectations:@[done] timeout:10];
}
- (void)phase:(NSString *)phase timeout:(NSTimeInterval)seconds {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:seconds];
    while(![[self snapshot:[@"phase-" stringByAppendingString:phase]][@"rooms"][0][@"phase"] isEqualToString:phase]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.25];}
}
- (void)testAutomaticReconnect {
    [self join];[self gate:YES];[self js:@"window.__lifecycleProbe.closeTransport(0)"];[self phase:@"reconnecting" timeout:10];
    [self pause:8];NSDictionary *held=[self snapshot:@"reconnectingAfter8s"];XCTAssertEqualObjects(held[@"rooms"][0][@"phase"],@"reconnecting");XCTAssertEqual([held[@"joinStarts"] integerValue],1);
    [self gate:NO];[self phase:@"connected" timeout:60];XCTAssertEqual([self open:[self snapshot:@"recovered"]],1);XCTAssertEqual([[self snapshot:@"onePublicJoin"][@"joinStarts"] integerValue],1);[self leave];
}
- (void)testReconnectingLeaveTerminalBlocksRejoin {
    [self join];[self gate:YES];[self js:@"window.__lifecycleProbe.closeTransport(0)"];[self phase:@"reconnecting" timeout:10];
    XCTestExpectation *done=[self expectationWithDescription:@"uncertain leave"];
    [self.sdk leaveRoomWithCompletionHandler:^(NSError *error){XCTAssertEqualObjects(error.localizedDescription,@"CloseUnconfirmed");self.expectBlocked=YES;[done fulfill];}];
    [self waitForExpectations:@[done] timeout:25];[self phase:@"disconnected" timeout:10];[self rejectDuplicate];[self gate:NO];[self pause:3];XCTAssertEqual([[self snapshot:@"terminalRetryRejected"][@"joinStarts"] integerValue],1);
}
- (void)testInitialTimeoutAndLateSuccessCleanup {
    [self js:@"window.__originalJoin=window.sdk.joinRoom;window.sdk.joinRoom=function(p,c){return window.__originalJoin(p,c).then(function(r){return new Promise(function(done){setTimeout(function(){done(r)},48000)})})};true"];
    XCTestExpectation *done=[self expectationWithDescription:@"timeout"];__block NSUInteger callbacks=0;
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){callbacks++;XCTAssertFalse(success);XCTAssertEqualObjects(error.localizedDescription,@"JoinTimeout");[done fulfill];}];
    [self pause:30.5];XCTAssertEqual([[self snapshot:@"oneJoinAt30s"][@"joinStarts"] integerValue],1);[self waitForExpectations:@[done] timeout:20];[self leave];[self pause:.5];
    NSDictionary *final=[self snapshot:@"timeoutLateCleanup"];XCTAssertEqual(callbacks,1);XCTAssertEqual([final[@"joinStarts"] integerValue],1);XCTAssertEqual([self open:final],0);
}
- (void)testDisconnectAndLeaveShareOneExit {
    [self join];[self js:@"window.__disconnectCount=0;var r=window.room,original=r.disconnect.bind(r);r.disconnect=function(){window.__disconnectCount++;return original()};true"];
    XCTestExpectation *disconnect=[self expectationWithDescription:@"disconnect"],*left=[self expectationWithDescription:@"leave"];
    [self.room disconnect:^{[disconnect fulfill];}];[self.sdk leaveRoomWithCompletionHandler:^(NSError *error){XCTAssertNil(error);[left fulfill];}];
    [self waitForExpectations:@[disconnect,left] timeout:25];XCTAssertEqualObjects([self js:@"window.__disconnectCount"],@1);[self join];[self leave];
}
- (void)configuredPlayer {
    WhitePlayerConfig *config=[[WhitePlayerConfig alloc] initWithRoom:SessionRoomUuid roomToken:SessionRoomToken];config.region=WhiteRegionCN;config.windowParams=[[WhiteWindowParams alloc] init];
    XCTestExpectation *created=[self expectationWithDescription:@"configured replay"];__block WhitePlayer *player;
    [self.sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL ok,WhitePlayer *p,NSError *e){XCTAssertTrue(ok);XCTAssertNil(e);player=p;[created fulfill];}];
    [self waitForExpectations:@[created] timeout:60];[player seekToScheduleTime:MAX(0,[[self js:@"window.player.timeDuration"] doubleValue]-1000)/1000.0];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];while(![[self js:@"window.player.phase"] isEqualToString:@"pause"]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.2];}
}
- (void)testPlayerFacadeConfigurationFollowsSelectedFacade {
    WhiteRoomConfig *seed=[self config];seed.isWritable=YES;XCTestExpectation *joined=[self expectationWithDescription:@"seed"];
    [self.sdk joinRoomWithConfig:seed callbacks:nil completionHandler:^(BOOL ok,WhiteRoom *room,NSError *e){XCTAssertTrue(ok);XCTAssertNil(e);self.room=room;[joined fulfill];}];[self waitForExpectations:@[joined] timeout:60];
    [self js:@"window.room.setGlobalState({candidateReplaySeed:Date.now()});true"];[self pause:3];WhiteSDK *a=self.sdk;
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:SessionAppIdentifier];config.useMultiViews=NO;
    WhiteSDK *b=[[WhiteSDK alloc] initWithWhiteBoardView:self.board config:config];XCTAssertEqualObjects([self js:@"window.room.useMultiViews"],@YES);[self leave];[self pause:2];
    self.sdk=b;[self configuredPlayer];XCTAssertEqualObjects([self js:@"window.player.useMultiViews"],@NO);XCTAssertEqualObjects([self js:@"!!window.manager"],@NO);
    self.evidence[@"selectedB"]=[self js:@"({useMultiViews:window.player.useMultiViews,phase:window.player.phase,hasManager:!!window.manager})"];[self leave];
    self.sdk=a;[self configuredPlayer];XCTAssertEqualObjects([self js:@"window.player.useMultiViews"],@YES);
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];while(![[self js:@"!!window.manager"] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.2];}
    self.evidence[@"selectedA"]=[self js:@"({useMultiViews:window.player.useMultiViews,phase:window.player.phase,hasManager:!!window.manager})"];XCTAssertEqual([self open:[self snapshot:@"oldRoomClosedDuringReplays"]],0);[self leave];
}
- (void)testCancelledPlayerSetupCannotStartLateReplay {
    [self js:@"window.__holdPlayerSetup=true;window.__actualReplayStarts=0;var init=window.bridge.getFunction('sdk.newWhiteSdk').function,replay=window.bridge.getFunction('sdk.replayRoom').function;window.bridge.registerAsync('sdk.newWhiteSdk',function(){var a=[].slice.call(arguments),reply=a.pop();a.push(function(v){if(window.__holdPlayerSetup)window.__latePlayerSetup=function(){reply(v)};else reply(v)});return init.apply(null,a)});window.bridge.registerAsync('sdk.replayRoom',function(){window.__actualReplayStarts++;return replay.apply(null,arguments)});true"];
    __block NSUInteger calls=0;[self.sdk createReplayerWithConfig:[[WhitePlayerConfig alloc] initWithRoom:SessionRoomUuid roomToken:SessionRoomToken] callbacks:nil completionHandler:^(BOOL ok,WhitePlayer *p,NSError *e){calls++;XCTAssertFalse(ok);XCTAssertEqualObjects(e.localizedDescription,@"Cancelled");}];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:15];while(![[self js:@"!!window.__latePlayerSetup"] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
    XCTAssertEqual(calls,0);XCTAssertEqualObjects([self js:@"window.__actualReplayStarts"],@0);[self leave];[self js:@"window.__holdPlayerSetup=false;true"];[self configuredPlayer];[self js:@"window.__latePlayerSetup();true"];[self pause:.3];
    XCTAssertEqual(calls,1);XCTAssertEqualObjects([self js:@"window.__actualReplayStarts"],@1);XCTAssertEqualObjects([self js:@"window.player.phase"],@"pause");
    self.evidence[@"cancelledSetup"]=[self js:@"({actualReplayStarts:window.__actualReplayStarts,phase:window.player.phase})"];[self leave];
}
- (void)testPlayerStopAndLeaveShareOneExit {
    WhiteRoomConfig *seed=[self config];seed.isWritable=YES;
    XCTestExpectation *seeded=[self expectationWithDescription:@"seed recorded frame"];
    [self.sdk joinRoomWithConfig:seed callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertNil(error);self.room=room;[seeded fulfill];}];
    [self waitForExpectations:@[seeded] timeout:60];
    [self js:@"window.room.setGlobalState({candidateReplaySeed:Date.now()});true"];
    [self pause:3];[self leave];[self pause:2];
    WhitePlayerConfig *config=[[WhitePlayerConfig alloc] initWithRoom:SessionRoomUuid roomToken:SessionRoomToken];config.region=WhiteRegionCN;config.windowParams=[[WhiteWindowParams alloc] init];
    XCTestExpectation *created=[self expectationWithDescription:@"replay"];__block WhitePlayer *player;
    [self.sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *value,NSError *error){XCTAssertNil(error);XCTAssertTrue(success);player=value;[created fulfill];}];
    [self waitForExpectations:@[created] timeout:60];
    [player seekToScheduleTime:MAX(0,[[self js:@"window.player.timeDuration"] doubleValue]-1000)/1000.0];
    self.evidence[@"playerImmediatelyCreated"]=[self js:@"({phase:window.player.phase,isPlayable:window.player.isPlayable,framesCount:window.player.framesCount,timeDuration:window.player.timeDuration,hasViews:!!window.player.viewsHubProxy.owner})"];NSLog(@"PLAYER_CREATE_PROBE %@",self.evidence[@"playerImmediatelyCreated"]);
    NSDate *readyDeadline=[NSDate dateWithTimeIntervalSinceNow:30];
    while(![[self js:@"window.player.phase"] isEqualToString:@"pause"]){XCTAssertGreaterThan(readyDeadline.timeIntervalSinceNow,0);[self pause:.2];}
    while(![[self js:@"!!window.manager"] boolValue]){XCTAssertGreaterThan(readyDeadline.timeIntervalSinceNow,0);[self pause:.2];}
    self.evidence[@"playerBeforeStop"]=[self js:@"({phase:window.player.phase,isPlayable:window.player.isPlayable,timeDuration:window.player.timeDuration,hasViews:!!window.player.viewsHubProxy.owner})"];
    [self js:@"window.__stopCount=0;var p=window.player,original=p.stop.bind(p);p.stop=function(){window.__stopCount++;return original()};true"];
    [player stop];[self leave];XCTAssertEqualObjects([self js:@"window.__stopCount"],@1);[self join];[self leave];
    [self.sdk createReplayerWithConfig:config callbacks:nil completionHandler:nil];
    [self pause:3];XCTAssertEqualObjects([self.board valueForKey:@"whiteState"],@"active");
    [self js:@"window.player.seekToProgressTime(Math.max(0,window.player.timeDuration-1000));true"];
    readyDeadline=[NSDate dateWithTimeIntervalSinceNow:30];
    while(![[self js:@"window.player.phase"] isEqualToString:@"pause"] || ![[self js:@"!!window.manager"] boolValue]){XCTAssertGreaterThan(readyDeadline.timeIntervalSinceNow,0);[self pause:.2];}
    [self leave];
}
- (void)testExternalWatchdogCancelsSlowPlayerBeforeCreatingNext {
    WhiteRoomConfig *seed=[self config];seed.isWritable=YES;
    XCTestExpectation *seeded=[self expectationWithDescription:@"seed replay"];
    [self.sdk joinRoomWithConfig:seed callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertNil(error);self.room=room;[seeded fulfill];}];
    [self waitForExpectations:@[seeded] timeout:60];[self js:@"window.room.setGlobalState({candidateReplaySeed:Date.now()});true"];[self pause:3];[self leave];[self pause:2];
    [self js:@"window.__playerStarts=0;window.__playerOrder=[];var original=window.sdk.replayRoom.bind(window.sdk);window.sdk.replayRoom=function(p,c){var n=++window.__playerStarts;window.__playerOrder.push({event:'create-'+n,at:Date.now()});return original(p,c).then(function(player){var stop=player.stop.bind(player);player.stop=function(){window.__playerOrder.push({event:'stop-'+n,at:Date.now()});return stop()};player.seekToProgressTime(Math.max(0,player.timeDuration-1000));if(n!==1)return player;window.__delayedPlayer=player;return new Promise(function(resolve){setTimeout(function(){resolve(player)},50000)})})};true"];
    WhitePlayerConfig *config=[[WhitePlayerConfig alloc] initWithRoom:SessionRoomUuid roomToken:SessionRoomToken];config.region=WhiteRegionCN;config.windowParams=[[WhiteWindowParams alloc] init];
    __block NSUInteger firstCalls=0;__block NSError *firstError;
    [self.sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *player,NSError *error){firstCalls++;XCTAssertFalse(success);firstError=error;}];
    [self pause:46];XCTAssertEqual(firstCalls,0);XCTAssertEqualObjects([self js:@"window.__playerStarts"],@1);XCTAssertEqualObjects([self js:@"window.__delayedPlayer.phase"],@"pause");
    self.evidence[@"pendingAfter46s"]=[self js:@"({starts:window.__playerStarts,phase:window.__delayedPlayer.phase,order:window.__playerOrder})"];
    [self leave];XCTAssertEqual(firstCalls,1);XCTAssertEqualObjects(firstError.localizedDescription,@"Cancelled");
    XCTestExpectation *created=[self expectationWithDescription:@"second replay"];
    [self.sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *player,NSError *error){XCTAssertNil(error);XCTAssertTrue(success);[created fulfill];}];
    [self waitForExpectations:@[created] timeout:60];NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
    while(![[self js:@"window.player.phase"] isEqualToString:@"pause"]||![[self js:@"!!window.manager"] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.2];}
    [self leave];XCTAssertEqual(firstCalls,1);XCTAssertEqualObjects([self js:@"window.__playerOrder.map(function(e){return e.event}).join(',')"],@"create-1,stop-1,create-2,stop-2");
    self.evidence[@"playerOrder"]=[self js:@"window.__playerOrder"];
}
- (void)testReleaseRetainsOneConnectionForTenMinutes {
    [self join];self.board.room=nil;id callbacks=[self.board valueForKey:@"roomCallbacks"];[callbacks setValue:nil forKey:@"room"];[callbacks setValue:nil forKey:@"delegate"];
    [self js:@"window.__lifecycleProbe.weakenRoomReferences()"];
    for(NSUInteger elapsed=0;elapsed<600;elapsed+=30){[self pause:30];NSDictionary *sample=[self snapshot:[NSString stringWithFormat:@"releaseAt%lus",(unsigned long)elapsed+30]];XCTAssertEqual([self open:sample],1);XCTAssertEqual([sample[@"joinStarts"] integerValue],1);}
    [self leave];[self pause:1];XCTAssertEqual([self open:[self snapshot:@"afterTenMinuteLeave"]],0);[self join];[self pause:31];XCTAssertEqual([self open:[self snapshot:@"afterLongRejoin"]],1);[self leave];
}

- (void)testSdkMethodsKeepTheirOriginalReturnTypes {
    XCTestExpectation *state=[self expectationWithDescription:@"SDK state"];
    [self.sdk getLocalLogStateWithCompletionHandler:^(NSDictionary *value,NSError *error){XCTAssertNil(error);XCTAssertNotNil(value[@"enabled"]);XCTAssertNil(value[@"scope"]);[state fulfill];}];
    [self waitForExpectations:@[state] timeout:10];[self join];
    WhiteHasBackgroundImageParams *params=[WhiteHasBackgroundImageParams new];params.viewId=@"mainView";params.scenePath=@"/init";params.imageUrl=@"https://example.invalid/lifecycle.png";params.sources=@[@"whiteSdk"];
    XCTestExpectation *query=[self expectationWithDescription:@"background query"];
    [self.sdk hasBackgroundImage:params completionHandler:^(BOOL exists,NSError *error){XCTAssertNil(error);XCTAssertFalse(exists);[query fulfill];}];
    [self waitForExpectations:@[query] timeout:10];[self leave];
    [self.sdk joinRoomWithConfig:[self config] callbacks:nil completionHandler:nil];[self pause:3];
    XCTAssertEqualObjects([self.board valueForKey:@"whiteState"],@"active");[self leave];
}

- (void)testLongOutageTerminalDoesNotAutoJoin {
    [self join];[self gate:YES];[self js:@"window.__lifecycleProbe.closeTransport(0)"];[self phase:@"reconnecting" timeout:10];[self pause:51];
    [self phase:@"disconnected" timeout:5];self.expectBlocked=YES;XCTAssertEqualObjects([self.board valueForKey:@"whiteState"],@"blocked");[self rejectDuplicate];[self gate:NO];[self pause:3];
    NSDictionary *final=[self snapshot:@"afterLongOutage"];XCTAssertEqual([final[@"joinStarts"] integerValue],1);XCTAssertEqual([self open:final],0);
}

- (void)testReloadRequiresCompletedLeaveAndRehandshakes {
    [self join];WhiteRoom *old=self.room;NSString *document=[self.board valueForKey:@"whiteDocument"];
    [self leave];[self snapshot:@"beforeControlledReload"];[self.board reload];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
    while(![self.board valueForKey:@"whiteDocument"] || [[self.board valueForKey:@"whiteDocument"] isEqual:document] || ![[self js:SessionLifecycleProbeJS] boolValue]){XCTAssertGreaterThan(deadline.timeIntervalSinceNow,0);[self pause:.1];}
    [self join];[old setGlobalState:(WhiteGlobalState *)@{@"staleReloadHandle":@YES}];[self pause:.3];
    XCTAssertFalse([[[self js:@"window.room.state.globalState"] objectForKey:@"staleReloadHandle"] boolValue]);
    NSDictionary *current=[self snapshot:@"afterControlledReload"];XCTAssertEqual([self open:current],1);XCTAssertEqual([current[@"joinStarts"] integerValue],1);
    [self.board reload];[self pause:1];self.expectBlocked=YES;[self rejectDuplicate];XCTAssertTrue([[self.board valueForKey:@"whiteInvalid"] boolValue]);
}

- (void)testPlayerStopBeforeFirstFrameFailureBlocksRejoin {
    WhitePlayerConfig *config=[[WhitePlayerConfig alloc] initWithRoom:SessionRoomUuid roomToken:SessionRoomToken];config.region=WhiteRegionCN;config.windowParams=[[WhiteWindowParams alloc] init];
    XCTestExpectation *created=[self expectationWithDescription:@"uninitialized player"];__block WhitePlayer *player;
    [self.sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *value,NSError *error){XCTAssertNil(error);XCTAssertTrue(success);player=value;[created fulfill];}];
    [self waitForExpectations:@[created] timeout:60];XCTAssertEqualObjects([self js:@"window.player.phase"],@"waitingFirstFrame");
    [self js:@"window.__stopCount=0;var p=window.player,original=p.stop.bind(p);p.stop=function(){window.__stopCount++;return original()};true"];
    XCTestExpectation *stopped=[self expectationWithDescription:@"failed stop"];
    [player stop];[self.sdk leaveRoomWithCompletionHandler:^(NSError *error){XCTAssertNotNil(error);self.expectBlocked=YES;[stopped fulfill];}];
    [self waitForExpectations:@[stopped] timeout:25];XCTAssertEqualObjects([self.board valueForKey:@"whiteState"],@"blocked");[self rejectDuplicate];
    XCTAssertEqualObjects([self js:@"window.__stopCount"],@1);XCTAssertEqual([[self snapshot:@"stopFailureRetryRejected"][@"joinStarts"] integerValue],0);
}

@end

// Unit transport: exercises the production owner without a real SDK or server.
@interface LifecycleUnitBoard : WhiteBoardView
@property BOOL dropHandshake;
@property BOOL holdSetup;
@property BOOL holdLeave;
@property (copy) void (^leaveReply)(void);
@property NSUInteger leaves;
@property (copy) void (^handshakeReply)(id);
@property (copy) void (^setupReply)(id);
@property NSUInteger setups;
@property NSString *actualApp;
@property NSDictionary *actualConfiguration;
@property NSDictionary *replayParameters;
@property NSUInteger replays;
@end
@implementation LifecycleUnitBoard
- (void)callHandler:(NSString *)method arguments:(NSArray *)args completionHandler:(void (^)(id))reply {
    if ([method isEqualToString:@"sdk.getLifecycle"]) {
        self.handshakeReply=reply;
        if(!self.dropHandshake) reply(@{@"value":@"{\"documentId\":\"unit-doc\"}"});
    } else {
        if([method isEqualToString:@"sdk.newWhiteSdk"]) {
            id payload=args.lastObject;
            self.actualApp=[payload valueForKey:@"appIdentifier"];
            self.actualConfiguration=[payload isKindOfClass:NSDictionary.class] ? payload : [NSJSONSerialization JSONObjectWithData:[[payload jsonString] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }
        if([method isEqualToString:@"sdk.replayRoom"]) { self.replays++; self.replayParameters=args.lastObject; }
        if(!reply) return;
        id envelope=@{@"scope":args[0][@"__whiteScope"],@"value":@"{}"};
        if([method isEqualToString:@"sdk.newWhiteSdk"]){self.setups++;self.setupReply=^(id value){reply(value ? @{@"scope":args[0][@"__whiteScope"],@"value":value} : envelope);};if(!self.holdSetup)self.setupReply(nil);}
        else if([method isEqualToString:@"sdk.leaveRoom"]){self.leaves++;self.leaveReply=^{reply(envelope);};if(!self.holdLeave)self.leaveReply();}
        else reply(envelope);
    }
}
@end
@interface SessionLifecycleOwnerTests : XCTestCase
@end
@implementation SessionLifecycleOwnerTests
- (void)verifyTimeout:(BOOL)missingHandshake {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];board.dropHandshake=missingHandshake;board.holdSetup=YES;[board whiteClaimSdk];
    XCTestExpectation *done=[self expectationWithDescription:@"deadline"];__block NSUInteger results=0,starts=0;
    [board whiteReplaceRoom:NSUUID.UUID.UUIDString configuration:@{} timeout:.15 bind:^{} start:^(NSNumber *g){starts++;} failure:^(NSError *error){results++;XCTAssertEqualObjects(error.localizedDescription,@"JoinTimeout");[done fulfill];}];
    [self waitForExpectations:@[done] timeout:3];
    if(missingHandshake)board.handshakeReply(@{@"value":@"{\"documentId\":\"unit-doc\"}"});else board.setupReply(nil);
    XCTAssertEqual(results,1);XCTAssertEqual(starts,0);if(missingHandshake)XCTAssertEqual(board.setups,0);[board whiteInvalidate];
}
- (void)testMissingHandshakeTimesOutAndLateReplyCannotStart {[self verifyTimeout:YES];}
- (void)testDelayedSetupTimesOutAndCompletesOnce {[self verifyTimeout:NO];}
- (void)testPlayerCannotStealPendingReplacement {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];board.holdSetup=YES;[board whiteClaimSdk];
    XCTestExpectation *ready=[self expectationWithDescription:@"creation started"],*joined=[self expectationWithDescription:@"joined"];
    [board whiteReplaceRoom:NSUUID.UUID.UUIDString configuration:@{} timeout:2 bind:^{} start:^(NSNumber *g){XCTAssertTrue([board whiteContinueJoin:g cancellation:^(NSError *e){}]);XCTAssertTrue([board whiteComplete:g success:YES]);[joined fulfill];} failure:^(NSError *e){XCTFail(@"%@",e);}];
    dispatch_async(dispatch_get_main_queue(),^{XCTAssertNil([board whiteBeginWithCancellation:^(NSError *e){}]);[ready fulfill];board.setupReply(nil);});
    [self waitForExpectations:@[ready,joined] timeout:3];[board whiteInvalidate];
}
- (void)activate:(LifecycleUnitBoard *)board key:(NSString *)key {
    XCTestExpectation *joined=[self expectationWithDescription:@"activate"];
    [board whiteReplaceRoom:key configuration:@{} timeout:5 bind:^{} start:^(NSNumber *g){XCTAssertTrue([board whiteContinueJoin:g cancellation:^(NSError *e){XCTFail(@"%@",e);}]);XCTAssertTrue([board whiteComplete:g success:YES]);[joined fulfill];} failure:^(NSError *e){XCTFail(@"%@",e);}];
    [self waitForExpectations:@[joined] timeout:2];
}
- (void)testReplacementDoesNotCloseOwnerThatChangedIdentityDuringLocalLeave {
    LifecycleUnitBoard *a=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero],*b=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];[a whiteClaimSdk];[b whiteClaimSdk];
    NSString *key=NSUUID.UUID.UUIDString;
    [self activate:a key:[key stringByAppendingString:@"1"]];[self activate:b key:[key stringByAppendingString:@"2"]];b.holdLeave=YES;
    XCTestExpectation *joined=[self expectationWithDescription:@"B/K1"];
    [b whiteReplaceRoom:[key stringByAppendingString:@"1"] configuration:@{} timeout:5 bind:^{} start:^(NSNumber *g){XCTAssertTrue([b whiteContinueJoin:g cancellation:^(NSError *e){XCTFail(@"%@",e);}]);XCTAssertTrue([b whiteComplete:g success:YES]);[joined fulfill];} failure:^(NSError *e){XCTFail(@"%@",e);}];
    // Both replacements use the existing main queue: B must reach its held local leave before A switches.
    [self activate:a key:[key stringByAppendingString:@"3"]];XCTAssertEqual(b.leaves,1);b.leaveReply();
    [self waitForExpectations:@[joined] timeout:2];XCTAssertEqual(a.leaves,1);XCTAssertTrue([a whiteCurrent:@2]);XCTAssertTrue([b whiteCurrent:@2]);
    b.holdLeave=NO;[a whiteLeave:nil completion:nil];[b whiteLeave:nil completion:nil];[a whiteInvalidate];[b whiteInvalidate];
}
- (void)joinSDK:(WhiteSDK *)sdk {
    WhiteRoomConfig *config=[[WhiteRoomConfig alloc] initWithUUID:@"mock-room" roomToken:@"mock-token" uid:@"mock-uid"];
    XCTestExpectation *done=[self expectationWithDescription:@"join facade"];
    [sdk joinRoomWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhiteRoom *room,NSError *error){XCTAssertTrue(success);XCTAssertNil(error);[done fulfill];}];
    [self waitForExpectations:@[done] timeout:2];
}
- (void)testCommonCallbackFollowsActualFacadeAndPreservesNilAndWeak {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];
    LifecycleCommonCounter *ca=[LifecycleCommonCounter new],*cb=[LifecycleCommonCounter new],*changed=[LifecycleCommonCounter new];
    WhiteSDK *a=[[WhiteSDK alloc] initWithWhiteBoardView:board config:[[WhiteSdkConfiguration alloc] initWithApp:@"mock-app"] commonCallbackDelegate:ca];[self joinSDK:a];
    WhiteSDK *b=[[WhiteSDK alloc] initWithWhiteBoardView:board config:[[WhiteSdkConfiguration alloc] initWithApp:@"mock-app"] commonCallbackDelegate:cb];
    XCTAssertEqual(board.commonCallbacks.delegate,ca);[b setCommonCallbackDelegate:changed];XCTAssertEqual(board.commonCallbacks.delegate,ca);
    [self joinSDK:b];XCTAssertEqual(board.commonCallbacks.delegate,changed);
    [self joinSDK:a];XCTAssertEqual(board.commonCallbacks.delegate,ca);[a setCommonCallbackDelegate:cb];XCTAssertEqual(board.commonCallbacks.delegate,cb);
    [b setCommonCallbackDelegate:nil];XCTAssertEqual(board.commonCallbacks.delegate,cb);[self joinSDK:b];XCTAssertNil(board.commonCallbacks.delegate);
    __weak LifecycleCommonCounter *weakCallback;
    @autoreleasepool {LifecycleCommonCounter *temporary=[LifecycleCommonCounter new];weakCallback=temporary;[a setCommonCallbackDelegate:temporary];}
    XCTAssertNil(weakCallback);[self joinSDK:a];XCTAssertNil(board.commonCallbacks.delegate);
    [board whiteLeave:nil completion:nil];[board whiteInvalidate];
}
- (void)testPlayerAdmissionBindsSelectedFacadeCommonCallback {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];LifecycleCommonCounter *ca=[LifecycleCommonCounter new],*cb=[LifecycleCommonCounter new];
    WhiteSDK *a=[[WhiteSDK alloc] initWithWhiteBoardView:board config:[[WhiteSdkConfiguration alloc] initWithApp:@"mock-app"] commonCallbackDelegate:ca];
    __unused WhiteSDK *b=[[WhiteSDK alloc] initWithWhiteBoardView:board config:[[WhiteSdkConfiguration alloc] initWithApp:@"mock-app"] commonCallbackDelegate:cb];
    WhitePlayerConfig *config=[[WhitePlayerConfig alloc] initWithRoom:@"mock-room" roomToken:@"mock-token"];XCTestExpectation *done=[self expectationWithDescription:@"player"];
    [a createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *player,NSError *error){XCTAssertTrue(success);XCTAssertNil(error);[done fulfill];}];
    [self waitForExpectations:@[done] timeout:2];XCTAssertEqual(board.commonCallbacks.delegate,ca);[board whiteLeave:nil completion:nil];[board whiteInvalidate];
}

- (WhiteSDK *)playerFacade:(LifecycleUnitBoard *)board app:(NSString *)app multi:(BOOL)multi {
    WhiteSdkConfiguration *config=[[WhiteSdkConfiguration alloc] initWithApp:app];config.useMultiViews=multi;
    return [[WhiteSDK alloc] initWithWhiteBoardView:board config:config];
}
- (void)createPlayer:(WhiteSDK *)sdk {
    XCTestExpectation *done=[self expectationWithDescription:@"player configured"];
    [sdk createReplayerWithConfig:[[WhitePlayerConfig alloc] initWithRoom:@"mock-room" roomToken:@"mock"] callbacks:nil completionHandler:^(BOOL success,WhitePlayer *p,NSError *e){XCTAssertTrue(success);XCTAssertNil(e);[done fulfill];}];
    [self waitForExpectations:@[done] timeout:2];
}
- (void)testPlayerConstructedDuringRoomUsesSelectedSdkConfiguration {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];
    WhiteSDK *a=[self playerFacade:board app:@"mock-app-A" multi:NO];[self joinSDK:a];
    WhiteSDK *b=[self playerFacade:board app:@"mock-app-B" multi:YES];XCTAssertEqualObjects(board.actualApp,@"mock-app-A");
    [board whiteLeave:nil completion:nil];[self createPlayer:b];
    XCTAssertEqualObjects(board.actualApp,@"mock-app-B");XCTAssertTrue([board.actualConfiguration[@"useMultiViews"] boolValue]);XCTAssertEqual(board.replays,1);
    [board whiteLeave:nil completion:nil];[board whiteInvalidate];
}
- (void)testPlayerEarlierIdleFacadeRestoresSelectedSdkConfiguration {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];
    WhiteSDK *a=[self playerFacade:board app:@"mock-app-A" multi:NO];
    __unused WhiteSDK *b=[self playerFacade:board app:@"mock-app-B" multi:YES];[self createPlayer:a];
    XCTAssertEqualObjects(board.actualApp,@"mock-app-A");XCTAssertFalse([board.actualConfiguration[@"useMultiViews"] boolValue]);
    XCTAssertEqualObjects([[board valueForKey:@"whiteSdkInitArgs"] firstObject][@"appIdentifier"],@"mock-app-A");
    [board whiteLeave:nil completion:nil];[board whiteInvalidate];
}
- (void)testPlayerWaitsForSetupKeepsBusyAndCapturesParameters {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];WhiteSDK *sdk=[self playerFacade:board app:@"mock-app-A" multi:NO];board.holdSetup=YES;
    WhitePlayerConfig *config=[[WhitePlayerConfig alloc] initWithRoom:@"original-room" roomToken:@"mock"];
    XCTestExpectation *created=[self expectationWithDescription:@"delayed configured player"];
    [sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *p,NSError *e){XCTAssertTrue(success);XCTAssertNil(e);[created fulfill];}];
    XCTAssertEqual(board.replays,0);
    __block NSUInteger rejected=0;[sdk createReplayerWithConfig:config callbacks:nil completionHandler:^(BOOL success,WhitePlayer *p,NSError *e){XCTAssertFalse(success);XCTAssertNotNil(e);rejected++;}];XCTAssertEqual(rejected,1);
    config.room=@"mutated-room";sdk.config.useMultiViews=YES;board.setupReply(nil);
    [self waitForExpectations:@[created] timeout:2];XCTAssertEqualObjects(board.replayParameters[@"room"],@"original-room");XCTAssertFalse([board.actualConfiguration[@"useMultiViews"] boolValue]);
    [board whiteLeave:nil completion:nil];[board whiteInvalidate];
}
- (void)testPlayerSetupErrorCompletesOnceAndExplicitLeaveAllowsRetry {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];WhiteSDK *sdk=[self playerFacade:board app:@"mock-app-A" multi:NO];board.holdSetup=YES;
    __block NSUInteger calls=0;[sdk createReplayerWithConfig:[[WhitePlayerConfig alloc] initWithRoom:@"mock-room" roomToken:@"mock"] callbacks:nil completionHandler:^(BOOL success,WhitePlayer *p,NSError *e){calls++;XCTAssertFalse(success);XCTAssertEqualObjects(e.localizedDescription,@"SetupRejected");}];
    void (^late)(id)=board.setupReply;late(@"{\"__error\":{\"message\":\"SetupRejected\"}}");XCTAssertEqual(calls,1);XCTAssertEqual(board.replays,0);
    [board whiteLeave:nil completion:nil];board.holdSetup=NO;late(nil);XCTAssertEqual(calls,1);XCTAssertEqual(board.replays,0);[self createPlayer:sdk];
    XCTAssertEqual(board.replays,1);[board whiteLeave:nil completion:nil];[board whiteInvalidate];
}
- (void)testCancelledPlayerSetupCannotReplayAfterNewGeneration {
    LifecycleUnitBoard *board=[[LifecycleUnitBoard alloc] initWithFrame:CGRectZero];WhiteSDK *a=[self playerFacade:board app:@"mock-app-A" multi:NO];board.holdSetup=YES;
    __block NSUInteger calls=0;[a createReplayerWithConfig:[[WhitePlayerConfig alloc] initWithRoom:@"mock-room" roomToken:@"mock"] callbacks:nil completionHandler:^(BOOL success,WhitePlayer *p,NSError *e){calls++;XCTAssertFalse(success);XCTAssertEqualObjects(e.localizedDescription,@"Cancelled");}];
    void (^late)(id)=board.setupReply;[board whiteLeave:nil completion:nil];board.holdSetup=NO;
    WhiteSDK *b=[self playerFacade:board app:@"mock-app-B" multi:YES];[self createPlayer:b];late(nil);
    XCTAssertEqual(calls,1);XCTAssertEqual(board.replays,1);XCTAssertEqualObjects(board.actualApp,@"mock-app-B");
    [board whiteLeave:nil completion:nil];[board whiteInvalidate];
}

@end
