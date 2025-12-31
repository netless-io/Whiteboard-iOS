//
//  LocalResourceLoaderTests.m
//  WhiteboardTests
//

#import <XCTest/XCTest.h>
#import "WhiteBoardView.h"
#import "WhiteboardResourceLoader.h"

@interface WhiteboardLocalFileResourceLoader (Testing)
- (NSString *)htmlByRemovingResourceTags:(NSString *)html orderedResources:(NSArray<NSDictionary *> * _Nullable * _Nullable)orderedResources;
@end

@interface LocalResourceLoaderTests : XCTestCase
@end

@implementation LocalResourceLoaderTests

- (void)testEnableHttpsSchemeOffDoesNotCreateResourceLoader
{
    WhiteBoardView *view = [[WhiteBoardView alloc] initWithEnableHttpsScheme:NO];
    id loader = [view valueForKey:@"resourceLoader"];
    XCTAssertNil(loader);
}

- (void)testRemoveAndRecordResourceOrder
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    WhiteboardLocalFileResourceLoader *loader = [[WhiteboardLocalFileResourceLoader alloc] initWithWebView:webView resourceBundle:bundle];
    NSString *html = @"<html><head>"
                     "<link href=\"a.css\" rel=\"stylesheet\">"
                     "<script defer src=\"a.js\"></script>"
                     "<link rel=\"stylesheet\" href=\"b.css\">"
                     "<script src=\"b.js\"></script>"
                     "</head><body></body></html>";
    NSArray<NSDictionary *> *orderedResources = nil;
    NSString *result = [loader htmlByRemovingResourceTags:html orderedResources:&orderedResources];
    
    XCTAssertFalse([result containsString:@"a.css"]);
    XCTAssertFalse([result containsString:@"b.css"]);
    XCTAssertFalse([result containsString:@"a.js"]);
    XCTAssertFalse([result containsString:@"b.js"]);
    XCTAssertEqual(orderedResources.count, 4);
    XCTAssertEqualObjects(orderedResources[0][@"type"], @"style");
    XCTAssertEqualObjects(orderedResources[0][@"source"], @"a.css");
    XCTAssertEqualObjects(orderedResources[1][@"type"], @"script");
    XCTAssertEqualObjects(orderedResources[1][@"source"], @"a.js");
    XCTAssertEqualObjects(orderedResources[2][@"type"], @"style");
    XCTAssertEqualObjects(orderedResources[2][@"source"], @"b.css");
    XCTAssertEqualObjects(orderedResources[3][@"type"], @"script");
    XCTAssertEqualObjects(orderedResources[3][@"source"], @"b.js");
}

@end
