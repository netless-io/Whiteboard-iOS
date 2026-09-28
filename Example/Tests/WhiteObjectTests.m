//
//  WhiteObjectTests.m
//  WhiteSDKPrivate_Tests
//
//  Created by yleaf on 2019/6/7.
//  Copyright © 2019 leavesster. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Whiteboard/Whiteboard.h>
#import "../../Whiteboard/Classes/Room/WhiteRoom+Private.h"

@interface WhitePencilTestDelegate : NSObject <UIGestureRecognizerDelegate>
@end

@implementation WhitePencilTestDelegate
@end

@interface CustomGlobalTestClass : WhiteGlobalState
@property (nonatomic, strong) NSString *name;
@end

@implementation CustomGlobalTestClass

@end

@interface WhiteUnifiedPageCallbackRecorder : NSObject <WhiteRoomCallbackDelegate>
@property (nonatomic, strong) WhiteUnifiedPageStateChange *state;
@end

@implementation WhiteUnifiedPageCallbackRecorder
- (void)onUnifiedPageStateChange:(WhiteUnifiedPageStateChange *)state
{
    self.state = state;
}
@end



@interface WhiteObjectTests : XCTestCase
@property (nonatomic, strong) UIWindow *pencilWindow;
@end

@implementation WhiteObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    self.pencilWindow.hidden = YES;
    self.pencilWindow = nil;
}

#pragma mark - Commom
- (WhiteBoardView *)pencilTestWebView
{
    WhiteBoardView *view = [[WhiteBoardView alloc] init];
    view.frame = CGRectMake(0, 0, 200, 200);
    self.pencilWindow = [[UIWindow alloc] initWithFrame:view.frame];
    self.pencilWindow.rootViewController = [[UIViewController alloc] init];
    [self.pencilWindow.rootViewController.view addSubview:view];
    self.pencilWindow.hidden = NO;

    NSPredicate *ready = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        for (UIView *content in view.scrollView.subviews) {
            if (![[content.classForCoder description] isEqualToString:@"WKContentView"]) {
                continue;
            }
            for (UIGestureRecognizer *gesture in content.gestureRecognizers) {
                NSString *name = [gesture.classForCoder description];
                if ([name isEqualToString:@"UIWebTouchEventsGestureRecognizer"] ||
                    [name isEqualToString:@"WKTouchEventsGestureRecognizer"]) {
                    return YES;
                }
            }
        }
        return NO;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:ready object:view];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[expectation] timeout:10], XCTWaiterResultCompleted);
    return view;
}

- (ApplePencilDrawHandler *)pencilHandlerWithGesture:(UIGestureRecognizer *)gesture
                                  originalDelegate:(id<UIGestureRecognizerDelegate>)delegate
{
    ApplePencilDrawHandler *handler = [[ApplePencilDrawHandler alloc] init];
    [handler setValue:gesture forKey:@"originalGesture"];
    [handler setValue:delegate forKey:@"originalDelegate"];
    gesture.delegate = (id<UIGestureRecognizerDelegate>)handler;
    return handler;
}

- (void)testPencilInvalidateRestoresOriginalDelegateAndIsIdempotent
{
    UIGestureRecognizer *gesture = [[UIGestureRecognizer alloc] init];
    WhitePencilTestDelegate *original = [[WhitePencilTestDelegate alloc] init];
    ApplePencilDrawHandler *handler = [self pencilHandlerWithGesture:gesture originalDelegate:original];
    [handler invalidate];
    XCTAssertEqual(gesture.delegate, original);
    XCTAssertNil([handler valueForKey:@"originalGesture"]);
    XCTAssertNil([handler valueForKey:@"originalDelegate"]);
    [handler invalidate];
    XCTAssertEqual(gesture.delegate, original);
}

- (void)testPencilOldHandlerDeallocationPreservesSuccessor
{
    UIGestureRecognizer *gesture = [[UIGestureRecognizer alloc] init];
    WhitePencilTestDelegate *original = [[WhitePencilTestDelegate alloc] init];
    WhitePencilTestDelegate *successor = [[WhitePencilTestDelegate alloc] init];
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) ApplePencilDrawHandler *handler =
            [self pencilHandlerWithGesture:gesture originalDelegate:original];
        gesture.delegate = successor;
        XCTAssertNotNil(handler);
    }
    XCTAssertEqual(gesture.delegate, successor);
}

- (void)testPencilDisconnectDetachesWhileRoomRemainsRetained
{
    WhiteRoom *room = [[WhiteRoom alloc] init];
    UIGestureRecognizer *gesture = [[UIGestureRecognizer alloc] init];
    WhitePencilTestDelegate *original = [[WhitePencilTestDelegate alloc] init];
    __weak ApplePencilDrawHandler *weakHandler;
    @autoreleasepool {
        ApplePencilDrawHandler *handler = [self pencilHandlerWithGesture:gesture originalDelegate:original];
        weakHandler = handler;
        room.applePencilDrawHandler = handler;
    }
    [room disconnect:nil];
    XCTAssertNil(room.applePencilDrawHandler);
    XCTAssertNil(weakHandler);
    XCTAssertEqual(gesture.delegate, original);
    XCTAssertNotNil(room);
}

- (void)testPencilRoomDeallocationDetachesRetainedHandler
{
    UIGestureRecognizer *gesture = [[UIGestureRecognizer alloc] init];
    WhitePencilTestDelegate *original = [[WhitePencilTestDelegate alloc] init];
    ApplePencilDrawHandler *handler = [self pencilHandlerWithGesture:gesture originalDelegate:original];
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) WhiteRoom *room = [[WhiteRoom alloc] init];
        room.applePencilDrawHandler = handler;
    }
    XCTAssertEqual(gesture.delegate, original);
    XCTAssertNil([handler valueForKey:@"originalGesture"]);
}

- (void)testPencilReplacementOnWebViewPreservesOriginalDelegate
{
    WhiteBoardView *view = [self pencilTestWebView];
    WhiteRoom *room = [[WhiteRoom alloc] initWithUuid:@"pencil-test" bridge:view];
    [room prepareForApplePencilDrawOnly:YES];
    ApplePencilDrawHandler *first = room.applePencilDrawHandler;
    UIGestureRecognizer *gesture = [first valueForKey:@"originalGesture"];
    id<UIGestureRecognizerDelegate> original = [first valueForKey:@"originalDelegate"];
    XCTAssertNotNil(gesture);
    XCTAssertNotNil(original);
    [room prepareForApplePencilDrawOnly:YES];
    ApplePencilDrawHandler *second = room.applePencilDrawHandler;
    XCTAssertNotEqual(first, second);
    XCTAssertNil([first valueForKey:@"originalGesture"]);
    XCTAssertEqual([second valueForKey:@"originalDelegate"], original);
    XCTAssertEqual(gesture.delegate, (id<UIGestureRecognizerDelegate>)second);
    [room disconnect:nil];
    XCTAssertEqual(gesture.delegate, original);
}

- (void)testPencilNewRoomSurvivesOldRoomDisconnectOnSharedWebView
{
    WhiteBoardView *view = [self pencilTestWebView];
    WhiteRoom *oldRoom = [[WhiteRoom alloc] initWithUuid:@"old-room" bridge:view];
    [oldRoom prepareForApplePencilDrawOnly:YES];
    ApplePencilDrawHandler *oldHandler = oldRoom.applePencilDrawHandler;
    UIGestureRecognizer *gesture = [oldHandler valueForKey:@"originalGesture"];
    id<UIGestureRecognizerDelegate> original = [oldHandler valueForKey:@"originalDelegate"];
    XCTAssertNotNil(gesture);
    XCTAssertNotNil(original);
    WhiteRoom *newRoom = [[WhiteRoom alloc] initWithUuid:@"new-room" bridge:view];
    [newRoom prepareForApplePencilDrawOnly:YES];
    ApplePencilDrawHandler *newHandler = newRoom.applePencilDrawHandler;
    XCTAssertEqual([newHandler valueForKey:@"originalDelegate"], original);
    [oldRoom disconnect:nil];
    XCTAssertEqual(gesture.delegate, (id<UIGestureRecognizerDelegate>)newHandler);
    [newRoom disconnect:nil];
    XCTAssertEqual(gesture.delegate, original);
}

- (void)testBooleanToJson {
    NSDictionary *dict = @{@"k1": @YES, @"k2": @(YES), @"k3": [NSNumber numberWithBool:YES]};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString *string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"true" options:NSRegularExpressionCaseInsensitive error: nil];
    NSArray *matches = [regex matchesInString:string
                                      options:NSMatchingReportCompletion
                                        range:NSMakeRange(0, [string length])];
    XCTAssertEqual([matches count], 3);

    NSLog(@"%@", string);
    
}

- (void)testHasBackgroundImageParamsToJson
{
    WhiteHasBackgroundImageParams *params = [[WhiteHasBackgroundImageParams alloc] init];
    params.viewId = @"mainView";
    params.scenePath = @"/scene-1";
    params.imageUrl = @"https://example.com/background.webp?token=value#fragment";
    params.sources = @[@"appliance"];

    NSDictionary *dict = [params jsonDict];
    XCTAssertEqualObjects(dict[@"viewId"], params.viewId);
    XCTAssertEqualObjects(dict[@"scenePath"], params.scenePath);
    XCTAssertEqualObjects(dict[@"imageUrl"], params.imageUrl);
    XCTAssertEqualObjects(dict[@"sources"], params.sources);
}

- (void)testUnifiedPageOptionsAndReadonlyModels
{
    WhiteWindowDocsEventOptions *options = [[WhiteWindowDocsEventOptions alloc] init];
    options.target = @"Slide-1";
    options.page = @2;
    options.scale = @1.5;
    XCTAssertEqualObjects([options jsonDict], (@{ @"target": @"Slide-1", @"page": @2, @"scale": @1.5 }));

    WhiteWindowPageStateOptions *stateOptions = [[WhiteWindowPageStateOptions alloc] init];
    stateOptions.target = @"Presentation-1";
    XCTAssertEqualObjects([stateOptions jsonDict], (@{ @"target": @"Presentation-1" }));

    WhiteUnifiedPageState *state = [WhiteUnifiedPageState _white_yy_modelWithJSON:@{
        @"target": @"Presentation", @"appId": @"Presentation-1", @"page": @2,
        @"pageCount": @5, @"scale": @1.5,
    }];
    XCTAssertEqualObjects(state.target, @"Presentation");
    XCTAssertEqualObjects(state.appId, @"Presentation-1");
    XCTAssertEqual(state.page, 2);
    XCTAssertEqual(state.pageCount, 5);
    XCTAssertEqualObjects(state.scale, @1.5);

    WhiteDispatchDocsEventResult *result = [WhiteDispatchDocsEventResult _white_yy_modelWithJSON:@{
        @"accepted": @NO,
        @"reason": @"eventNotSupported",
        @"message": @"DocsViewer does not support scalePage",
    }];
    XCTAssertFalse(result.accepted);
    XCTAssertEqualObjects(result.reason, WhiteDispatchDocsEventFailureReasonEventNotSupported);
    XCTAssertEqualObjects(result.message, @"DocsViewer does not support scalePage");
}

- (void)testWindowAppOriginSizeUsesAttributesContract
{
    WhiteAppOptions *options = [[WhiteAppOptions alloc] init];
    WhiteAppParam *param = [[WhiteAppParam alloc] initWithKind:@"Slide" options:options attrs:@{
        @"taskId": @"task-1",
    }];
    param.originSize = [[WhiteWindowOriginSize alloc] initWithWidth:1280 height:900];
    XCTAssertEqualObjects(param.resolvedAttrs, (@{
        @"taskId": @"task-1",
        @"originSize": @{ @"width": @1280, @"height": @900 },
    }));
}

- (void)testUnifiedPageCallbackForwardsCompletePayload
{
    WhiteUnifiedPageCallbackRecorder *recorder = [[WhiteUnifiedPageCallbackRecorder alloc] init];
    WhiteCommonCallbacks *callbacks = [[WhiteCommonCallbacks alloc] init];
    callbacks.roomDelegate = recorder;
    [callbacks unifiedPageStateChange:@{
        @"target": @"DocsViewer", @"appId": @"DocsViewer-1", @"page": @2,
        @"pageCount": @3, @"scale": @1.25, @"status": @"success", @"changeType": @"scale",
    }];
    XCTAssertEqualObjects(recorder.state.target, @"DocsViewer");
    XCTAssertEqualObjects(recorder.state.status, @"success");
    XCTAssertEqualObjects(recorder.state.changeType, @"scale");
    XCTAssertEqualObjects(recorder.state.scale, @1.25);
}

#pragma mark - WhiteEvent
- (void)testWhiteEventConvertDict {
    WhiteEvent *event = [[WhiteEvent alloc] init];
    event.eventName = @"ee";
    event.payload = @{@"k": @"v"};
    NSDictionary *dict = [event jsonDict];
    
    WhiteEvent *event1 = [WhiteEvent _white_yy_modelWithJSON:dict];
    XCTAssertTrue([event1.payload isEqual:event.payload]);
    
    event1.payload = @"";
    XCTAssertFalse([event1.payload isEqual:event.payload]);
}

- (void)testWhiteEventConvertStr {
    WhiteEvent *event = [[WhiteEvent alloc] init];
    event.eventName = @"ee";
    event.payload = @"313131";
    NSDictionary *dict = [event jsonDict];
    
    WhiteEvent *event1 = [WhiteEvent _white_yy_modelWithJSON:dict];
    XCTAssertTrue([self whiteEventEqual:event event:event1]);

    event1.payload = @"";
    XCTAssertFalse([self whiteEventEqual:event event:event1]);
}

- (void)testWhiteEventConvertNum {
    WhiteEvent *event = [[WhiteEvent alloc] init];
    event.eventName = @"ee";
    NSInteger num = 333;
    event.payload = @(num);
    NSDictionary *dict = [event jsonDict];
    
    WhiteEvent *event1 = [WhiteEvent _white_yy_modelWithJSON:dict];
    XCTAssertTrue([self whiteEventEqual:event event:event1]);
    
    event1.payload = @"";
    XCTAssertFalse([self whiteEventEqual:event event:event1]);
}

#pragma mark - PlayConfig
- (void)testPlayConfigSecConvert
{
    WhitePlayerConfig *pConfig = [[WhitePlayerConfig alloc] initWithRoom:@"room" roomToken:@"roomToken"];
    pConfig.duration = @40;
    NSNumber *beginTimestamp = @([[NSDate dateWithTimeIntervalSince1970:2000] timeIntervalSince1970]);
    pConfig.beginTimestamp = beginTimestamp;
    
    NSDictionary *dict = [pConfig jsonDict];
    NSLog(@"dict:%@", dict);
    
    // 在 iOS 端传给 js 端时，自动切换为毫秒精度
    XCTAssertEqual([dict[@"duration"] integerValue], 40 * 1000);
    XCTAssertEqual([dict[@"beginTimestamp"] integerValue], [beginTimestamp integerValue] * 1000);
}

- (void)testPlayConfigNoSecConvert
{
    WhitePlayerConfig *pConfig = [[WhitePlayerConfig alloc] initWithRoom:@"room" roomToken:@"roomToken"];
    
    NSDictionary *dict = [pConfig jsonDict];
    NSLog(@"dict:%@", dict);
    
    XCTAssertNil(dict[@"duration"]);
    XCTAssertNil(dict[@"beginTimestamp"]);
}

#pragma mark - GlobalState
- (void)testCustomGlobalStateInDisplayerState
{
    [WhiteDisplayerState setCustomGlobalStateClass:[CustomGlobalTestClass class]];
    
    // 不能直接初始化复制，直接从字典生成一个
    NSDictionary *dict = @{@"globalState": @{@"name": @"value"}};
    WhiteDisplayerState *result = [WhiteDisplayerState _white_yy_modelWithJSON:dict];
    
    XCTAssertNotNil(result.globalState);
    XCTAssertTrue([result.globalState isKindOfClass:[CustomGlobalTestClass class]]);
    XCTAssertTrue([[(CustomGlobalTestClass *)result.globalState name] isEqualToString:@"value"]);
}

- (void)testCustomGlobalStateInRoomState
{
    [WhiteDisplayerState setCustomGlobalStateClass:[CustomGlobalTestClass class]];
    
    // 不能直接初始化复制，直接从字典生成一个
    NSDictionary *dict = @{@"globalState": @{@"name": @"value"}};
    WhiteRoomState *result = [WhiteRoomState _white_yy_modelWithJSON:dict];
    
    XCTAssertNotNil(result.globalState);
    XCTAssertTrue([result.globalState isKindOfClass:[CustomGlobalTestClass class]]);
    XCTAssertTrue([[(CustomGlobalTestClass *)result.globalState name] isEqualToString:@"value"]);
}

- (void)testCustomGlobalStateInPlayerState
{
    [WhiteDisplayerState setCustomGlobalStateClass:[CustomGlobalTestClass class]];
    
    // 不能直接初始化复制，直接从字典生成一个
    NSDictionary *dict = @{@"globalState": @{@"name": @"value"}};
    WhitePlayerState *result = [WhitePlayerState _white_yy_modelWithJSON:dict];
    
    XCTAssertNotNil(result.globalState);
    XCTAssertTrue([result.globalState isKindOfClass:[CustomGlobalTestClass class]]);
    XCTAssertTrue([[(CustomGlobalTestClass *)result.globalState name] isEqualToString:@"value"]);
}

#pragma mark - MemberState
- (void)testMemberState
{
    WhiteMemberState *memberState = [[WhiteMemberState alloc] init];
    memberState.strokeWidth = @1;
    NSDictionary *dict1 = [memberState jsonDict];
    
    WhiteReadonlyMemberState *readonlyState = [WhiteReadonlyMemberState _white_yy_modelWithJSON:dict1];
    
    XCTAssertNotNil(readonlyState);
    XCTAssertNotNil(readonlyState.strokeWidth);
}

#pragma mark - Private

- (BOOL)whiteEventEqual:(WhiteEvent *)event event:(WhiteEvent *)event1
{
    return [event.eventName isEqualToString:event1.eventName] && [event.payload isEqual:event1.payload];
}

@end
