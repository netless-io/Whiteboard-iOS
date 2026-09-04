//
//  WhiteWindowDocsEventOptions.m
//  Whiteboard
//
//  Created by xuyunshi on 2023/7/6.
//

#import "WhiteWindowDocsEventOptions.h"

WhiteWindowDocsEventKey const WhiteWindowDocsEventPrevPage = @"prevPage";
WhiteWindowDocsEventKey const WhiteWindowDocsEventNextPage = @"nextPage";
WhiteWindowDocsEventKey const WhiteWindowDocsEventPrevStep = @"prevStep";
WhiteWindowDocsEventKey const WhiteWindowDocsEventNextStep = @"nextStep";
WhiteWindowDocsEventKey const WhiteWindowDocsEventJumpToPage = @"jumpToPage";
WhiteWindowDocsEventKey const WhiteWindowDocsEventScalePage = @"scalePage";

WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonInvalidEvent = @"invalidEvent";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonInvalidOptions = @"invalidOptions";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonTargetNotFound = @"targetNotFound";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonTargetNotSupported = @"targetNotSupported";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonEventNotSupported = @"eventNotSupported";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonNotWritable = @"notWritable";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonStateUnavailable = @"stateUnavailable";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonOutOfRange = @"outOfRange";
WhiteDispatchDocsEventFailureReason const WhiteDispatchDocsEventFailureReasonCommandFailed = @"commandFailed";

@interface WhiteDispatchDocsEventResult ()
@property (nonatomic, assign, readwrite) BOOL accepted;
@property (nonatomic, copy, readwrite, nullable) WhiteDispatchDocsEventFailureReason reason;
@property (nonatomic, copy, readwrite, nullable) NSString *message;
@end

@implementation WhiteWindowDocsEventOptions

@end

@implementation WhiteDispatchDocsEventResult
@end
