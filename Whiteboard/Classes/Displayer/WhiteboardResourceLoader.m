//
//  WhiteboardResourceLoader.m
//  Whiteboard
//
//  Created by Codex.
//

#import "WhiteboardResourceLoader.h"

@interface WhiteboardScriptMessageHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, copy) void (^handler)(WKScriptMessage *message);

@end

@implementation WhiteboardScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (self.handler) {
        self.handler(message);
    }
}

@end

@interface WhiteboardLocalFileResourceLoader ()

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSBundle *resourceBundle;
@property (nonatomic, copy) NSArray<NSDictionary *> *pendingResources;
@property (nonatomic, assign) NSUInteger pendingResourceIndex;
@property (nonatomic, assign) BOOL pendingResourceInjectionScheduled;
@property (nonatomic, strong) WhiteboardScriptMessageHandler *domReadyHandler;
@property (nonatomic, assign) BOOL domReadyHandlerInstalled;

@end

@implementation WhiteboardLocalFileResourceLoader

static NSString *const kDomReadyHandlerName = @"_whiteboard_dom_ready_";

- (instancetype)initWithWebView:(WKWebView *)webView resourceBundle:(NSBundle *)resourceBundle
{
    self = [super init];
    if (self) {
        _webView = webView;
        _resourceBundle = resourceBundle;
    }
    return self;
}

- (void)loadResourceURL:(NSURL *)url baseURL:(NSURL *)baseURL
{
    if (url.isFileURL) {
        NSError *error = nil;
        NSString *html = [NSString stringWithContentsOfFile:url.path encoding:NSUTF8StringEncoding error:&error];
        if (html && !error) {
            NSArray<NSDictionary *> *orderedResources = nil;
            html = [self htmlByRemovingResourceTags:html orderedResources:&orderedResources];
            self.pendingResources = [self resourceFileInfoFromItems:orderedResources];
            self.pendingResourceIndex = 0;
            self.pendingResourceInjectionScheduled = YES;
            [self ensureDomReadyHandlerInstalled];
            [self.webView loadHTMLString:html baseURL:baseURL];
            return;
        }
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)ensureDomReadyHandlerInstalled
{
    if (self.domReadyHandlerInstalled || !self.webView) {
        return;
    }
    WKUserContentController *controller = self.webView.configuration.userContentController;
    if (!controller) {
        return;
    }
    NSString *domReadyScript = @"window.webkit.messageHandlers._whiteboard_dom_ready_.postMessage(null);";
    WKUserScript *domReadyUserScript = [[WKUserScript alloc] initWithSource:domReadyScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [controller addUserScript:domReadyUserScript];
    [controller removeScriptMessageHandlerForName:kDomReadyHandlerName];
    self.domReadyHandler = [[WhiteboardScriptMessageHandler alloc] init];
    __weak typeof(self) weakSelf = self;
    self.domReadyHandler.handler = ^(WKScriptMessage *message) {
        if (!weakSelf.pendingResourceInjectionScheduled) {
            return;
        }
        weakSelf.pendingResourceInjectionScheduled = NO;
        [weakSelf startPendingResourceInjection];
    };
    [controller addScriptMessageHandler:self.domReadyHandler name:kDomReadyHandlerName];
    self.domReadyHandlerInstalled = YES;
}

- (NSString *)htmlByRemovingResourceTags:(NSString *)html orderedResources:(NSArray<NSDictionary *> * _Nullable * _Nullable)orderedResources
{
    if (html.length == 0) {
        return html;
    }
    NSError *regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<script\\b[^>]*\\bsrc=[\"']([^\"']+)[\"'][^>]*>\\s*</script>|<link\\b(?=[^>]*\\brel=[\"']stylesheet[\"'])(?=[^>]*\\bhref=[\"']([^\"']+)[\"'])[^>]*>"
                                                                           options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
                                                                             error:&regexError];
    if (!regex || regexError) {
        return html;
    }
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
    if (matches.count == 0) {
        return html;
    }
    NSMutableString *mutableHTML = [html mutableCopy];
    NSMutableArray<NSDictionary *> *items = [NSMutableArray arrayWithCapacity:matches.count];
    for (NSTextCheckingResult *result in matches) {
        NSString *type = nil;
        NSString *value = nil;
        NSRange scriptRange = [result rangeAtIndex:1];
        NSRange linkRange = (result.numberOfRanges > 2) ? [result rangeAtIndex:2] : NSMakeRange(NSNotFound, 0);
        if (scriptRange.location != NSNotFound) {
            type = @"script";
            value = [mutableHTML substringWithRange:scriptRange];
        } else if (linkRange.location != NSNotFound) {
            type = @"style";
            value = [mutableHTML substringWithRange:linkRange];
        }
        if (type && value.length > 0) {
            [items addObject:@{@"type": type, @"source": value}];
        }
    }
    for (NSTextCheckingResult *result in [matches reverseObjectEnumerator]) {
        [mutableHTML deleteCharactersInRange:result.range];
    }
    if (orderedResources) {
        *orderedResources = [items copy];
    }
    return mutableHTML;
}

- (NSArray<NSDictionary *> *)resourceFileInfoFromItems:(NSArray<NSDictionary *> *)items
{
    if (items.count == 0) {
        return @[];
    }
    NSMutableArray<NSDictionary *> *resources = [NSMutableArray arrayWithCapacity:items.count];
    for (NSDictionary *item in items) {
        NSString *type = item[@"type"];
        NSString *src = item[@"source"];
        if (type.length == 0 || src.length == 0) {
            continue;
        }
        NSString *resolvedPath = nil;
        NSURL *srcURL = [NSURL URLWithString:src];
        NSString *path = srcURL ? srcURL.path : src;
        if (path.length == 0) {
            continue;
        }
        NSString *trimmedPath = [path hasPrefix:@"/"] ? [path substringFromIndex:1] : path;
        NSString *directory = [trimmedPath stringByDeletingLastPathComponent];
        NSString *fileName = [trimmedPath lastPathComponent];
        if (directory.length == 0 || [directory isEqualToString:@"."]) {
            resolvedPath = [self.resourceBundle pathForResource:fileName ofType:nil];
        } else {
            resolvedPath = [self.resourceBundle pathForResource:fileName ofType:nil inDirectory:directory];
        }
        if (resolvedPath.length > 0) {
            [resources addObject:@{
                @"type": type,
                @"path": resolvedPath
            }];
        }
    }
    return resources;
}

- (void)startPendingResourceInjection
{
    if (self.pendingResources.count == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf injectNextPendingResource];
    });
}

- (void)injectNextPendingResource
{
    if (self.pendingResourceIndex >= self.pendingResources.count) {
        return;
    }
    NSDictionary *item = self.pendingResources[self.pendingResourceIndex];
    NSString *type = item[@"type"];
    NSString *path = item[@"path"];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!content || error) {
        self.pendingResourceIndex += 1;
        [self injectNextPendingResource];
        return;
    }
    NSString *js = nil;
    if ([type isEqualToString:@"style"]) {
        js = [self javaScriptStringForStyleContent:content];
    } else {
        js = content;
    }
    __weak typeof(self) weakSelf = self;
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable evalError) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.pendingResourceIndex += 1;
        [strongSelf injectNextPendingResource];
    }];
}

- (NSString *)javaScriptStringForStyleContent:(NSString *)styleContent
{
    if (!styleContent) {
        return @"";
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@[styleContent] options:0 error:nil];
    if (!jsonData) {
        return @"";
    }
    NSString *jsonArray = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonArray.length < 2) {
        return @"";
    }
    NSString *jsonString = [jsonArray substringWithRange:NSMakeRange(1, jsonArray.length - 2)];
    return [NSString stringWithFormat:@"(function(){var s=document.createElement('style');s.textContent=%@;document.head.appendChild(s);}());", jsonString];
}

@end
