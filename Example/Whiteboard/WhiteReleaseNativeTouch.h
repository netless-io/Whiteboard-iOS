// Native event injection for this Debug release fixture only.
// These helpers use the pinned KIF touch implementation; no JS input is emitted.
#if DEBUG && WHITE_RELEASE_NATIVE_TOUCH
#import "ReleaseNativeTouch/IOHIDEvent+KIF.m"
#import "ReleaseNativeTouch/UITouch-KIFAdditions.m"
#import "ReleaseNativeTouch/UIEvent+KIFAdditions.m"

@interface UIApplication (WhiteReleaseTouchEvent)
- (UIEvent *)_touchesEvent;
@end

static void WhiteReleaseSendTouch(UITouch *touch) {
    UIEvent *event = [UIApplication.sharedApplication _touchesEvent];
    [event _clearTouches];
    [event kif_setEventWithTouches:@[touch]];
    [event _addTouch:touch forDelayedDelivery:NO];
    [UIApplication.sharedApplication sendEvent:event];
}

static void WhiteReleaseTouch(UIView *view, NSDictionary *command, void (^reply)(id)) {
    UIWindow *window = view.window;
    if (!window) { reply(@{@"error":@"Native touch window is unavailable"}); return; }
    BOOL tap = [command[@"type"] isEqual:@"tap"];
    BOOL swipe = [command[@"type"] isEqual:@"swipe"];
    if (!tap && !swipe) { reply(@{@"error":@"Unsupported native touch gesture"}); return; }
    CGPoint first = CGPointMake([command[tap ? @"x" : @"x1"] doubleValue], [command[tap ? @"y" : @"y1"] doubleValue]);
    CGPoint last = tap ? first : CGPointMake([command[@"x2"] doubleValue], [command[@"y2"] doubleValue]);
    NSTimeInterval duration = tap ? 0.08 : MAX(0.1, MIN(30.0, [command[@"duration"] doubleValue] / 1000.0));
    NSUInteger steps = tap ? 1 : MAX(2, (NSUInteger)ceil(duration * 60.0));
    UITouch *touch = [[UITouch alloc] initAtPoint:first inWindow:window];
    if (!touch.view || !touch.window) { reply(@{@"error":@"Native touch did not hit a window view"}); return; }
    NSString *hitViewClass=NSStringFromClass(touch.view.class) ?: @"nil";
    if (!tap) {
        // UIKit removed this optional private hint on newer iOS versions.
        if ([touch respondsToSelector:@selector(setIsTap:)]) [touch setIsTap:NO];
        [touch setTapCount:0];
    }
    NSTimeInterval started = NSDate.date.timeIntervalSince1970 * 1000;
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    [touch setIsFromEdge:NO];
    WhiteReleaseSendTouch(touch);
    for (NSUInteger i = 1; i <= steps; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * i / steps * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CGFloat fraction = (CGFloat)i / steps;
            [touch setLocationInWindow:CGPointMake(first.x + (last.x - first.x) * fraction, first.y + (last.y - first.y) * fraction)];
            [touch setPhaseAndUpdateTimestamp:UITouchPhaseMoved];
            if (!tap) WhiteReleaseSendTouch(touch);
            if (i == steps) {
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
                WhiteReleaseSendTouch(touch);
                reply(@{@"complete":@YES,@"input":@{@"kind":@"native UIKit UITouch began/moved/ended (KIF)",@"type":command[@"type"],@"startedAt":@(started),@"endedAt":@(NSDate.date.timeIntervalSince1970*1000),@"moveSamples":@(tap ? 0 : steps),@"hitView":hitViewClass,@"endedHitView":NSStringFromClass(touch.view.class) ?: @"nil",@"window":NSStringFromClass(window.class),@"windowHasWindow":@(window.window != nil),@"touchWindowMatches":@(touch.window == window)}});
            }
        });
    }
}
#endif
