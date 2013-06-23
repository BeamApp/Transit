//
//  TransitWebViewTests.m
//  TransitTestsOSX
//
//  Created by Heiko Behrens on 21.06.13.
//  Copyright (c) 2013 BeamApp UG. All rights reserved.
//

#import "TransitAbstractWebViewContextTests.h"
#import <WebKit/WebKit.h>
#import "Transit+Private.h"

@interface TransitWebViewTests : TransitAbstractWebViewContextTests

@end

@implementation TransitWebViewTests

- (TransitWebViewContext *)contextWithEmptyPage {
    WebView *wv = WebView.new;
    [wv.mainFrame loadHTMLString:self.htmlStringForEmptyPage baseURL:nil];
    return [TransitWebViewContext contextWithWebView:wv];
}

+(void)waitForWebViewToBeLoaded:(WebView*)webView {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    while (webView.isLoading) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        NSLog(@"waiting for webview to load...");
    }
}

+(void)loadHTMLString:(NSString*)htmlString inWebView:(WebView*)webView {
    [webView.mainFrame loadHTMLString:htmlString baseURL:nil];
}

+(void)loadRequest:(NSURLRequest*)request inWebView:(WebView*)webView {
    [webView.mainFrame loadRequest:request];
}

-(TransitJSFunction*)functionToCallContextBareToTheMetal:(TransitContext*)context {
    NSString* js = @"(function(arg){\n"
            "window.globalTestVar = 'beforeCall '+arg;\n"
            "transit_callback.callHandleRequestBlock();\n"
            "return window.globalTestVar;\n"
            "})";
    return [[TransitJSFunction alloc] initWitContext:context jsRepresentation:js];
}

#pragma mark - actual tests


@end