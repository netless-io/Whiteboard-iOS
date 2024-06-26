//
//  PencilDrawHandler.m
//  Masonry
//
//  Created by xuyunshi on 2022/5/7.
//

#import "ApplePencilDrawHandler.h"
#import "WhiteDisplayer+Private.h"

@interface ApplePencilDrawHandler ()<UIGestureRecognizerDelegate>
@property (nonatomic, weak) WhiteRoom *room;
@property (nonatomic, weak) UIGestureRecognizer *originalGesture;
@property (nonatomic, weak) id<UIGestureRecognizerDelegate> originalDelegate;

@property (nonatomic, assign) BOOL isPencilTouch;
@property (nonatomic, assign) BOOL hasRemovedAppliance;
@property (nonatomic, assign) WhiteApplianceNameKey removedAppliance;
@end

@implementation ApplePencilDrawHandler

- (instancetype)initWithRoom:(WhiteRoom *)room drawOnlyPencil:(BOOL)drawOnlyPencil {
    NSUInteger wkContentIndex = [room.bridge.scrollView.subviews indexOfObjectPassingTest:^BOOL(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj.classForCoder description] isEqualToString:@"WKContentView"]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (wkContentIndex != NSNotFound) {
        NSUInteger gestureIndex = [room.bridge.scrollView.subviews[wkContentIndex].gestureRecognizers indexOfObjectPassingTest:^BOOL(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[obj.classForCoder description] isEqualToString:@"UIWebTouchEventsGestureRecognizer"]) {
                *stop = YES;
                return YES;
            }
            if ([[obj.classForCoder description] isEqualToString:@"WKTouchEventsGestureRecognizer"]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (gestureIndex != NSNotFound) {
            UIGestureRecognizer *webTouch = room.bridge.scrollView.subviews[wkContentIndex].gestureRecognizers[gestureIndex];
            self.originalDelegate = webTouch.delegate;
            self.originalGesture = webTouch;
            webTouch.delegate = self;
        }
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recoverApplianceFromTempRemove) name:UIApplicationWillResignActiveNotification object:nil];
    
    if (self = [super init]) {
        _drawOnlyApplePencil = drawOnlyPencil;
        _room = room;
    }
    return self;
}

- (void)dealloc {
    self.originalGesture.delegate = self.originalDelegate;
}

- (void)setDrawOnlyApplePencil:(BOOL)drawOnlyPencil {
    _drawOnlyApplePencil = drawOnlyPencil;
    [self recoverApplianceFromTempRemove];
}

- (void)roomApplianceDidManualUpdate {
    if (!self.hasRemovedAppliance) {
        return;
    }
    if (![self.room.memberState.currentApplianceName isEqualToString:self.removedAppliance]) {
        self.hasRemovedAppliance = NO;
    }
}

- (void)removeApplianceIfNeed {
    if (self.hasRemovedAppliance) {
        return;
    }
    if ([self isApplianceDrawable:self.room.state.memberState.currentApplianceName]) {
        self.removedAppliance = self.room.state.memberState.currentApplianceName;
        WhiteMemberState *state = [[WhiteMemberState alloc] init];
        state.currentApplianceName = ApplianceClicker;
        [self.room setMemberState:state];
        self.hasRemovedAppliance = YES;
    }
}

- (void)recoverApplianceFromTempRemove {
    if ((self.hasRemovedAppliance) & (self.room.isWritable)) {
        WhiteMemberState *state = [[WhiteMemberState alloc] init];
        state.currentApplianceName = self.removedAppliance;
        [self.room setMemberState:state];
        self.hasRemovedAppliance = NO;
    }
}

- (BOOL)isApplianceDrawable:(WhiteApplianceNameKey)appliance {
    return [appliance isEqualToString:AppliancePencil];
}

#pragma mark - GestureDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (!self.drawOnlyApplePencil) {
        if (self.originalDelegate) {
            if ([self.originalDelegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
                return [self.originalDelegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
            }
        }
    }
    // 不可写状态的触摸不会触发Pencil阻拦事件
    if (self.room.isWritable) {
        self.isPencilTouch = (touch.type == UITouchTypePencil);
        if (!self.isPencilTouch) {
            [self removeApplianceIfNeed];
        } else {
            [self recoverApplianceFromTempRemove];
        }
    }
    if (self.originalDelegate) {
        if ([self.originalDelegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
            return [self.originalDelegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
        }
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.originalDelegate) {
        if ([self.originalDelegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
            return [self.originalDelegate gestureRecognizerShouldBegin:gestureRecognizer];
        }
    }
    return YES;
}

@end
