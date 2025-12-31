//
//  WhiteboardResourceLoader.h
//  Whiteboard
//
//  Created by Codex.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WhiteboardLocalFileResourceLoader : NSObject

- (instancetype)initWithWebView:(WKWebView *)webView resourceBundle:(NSBundle *)resourceBundle;
- (void)loadResourceURL:(NSURL *)url baseURL:(NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
