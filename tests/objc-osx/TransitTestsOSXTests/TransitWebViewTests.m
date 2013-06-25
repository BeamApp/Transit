//
//  TransitWebViewTests.m
//  TransitTestsOSX
//
//  Created by Heiko Behrens on 21.06.13.
//  Copyright (c) 2013 BeamApp UG. All rights reserved.
//

#import "TransitAbstractWebViewContextTests.h"
#import <WebKit/WebKit.h>
#import <WebKit/WebFrameLoadDelegate.h>
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMArg.h>
#import "Transit+Private.h"
#import "CCWeakMockProxy.h"

@interface __WebFrameLoadDelegateImpl : NSObject
@end

@implementation __WebFrameLoadDelegateImpl

- (void)webView:(WebView *)webView didStartProvisionalLoadForFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didCommitLoadForFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didChangeLocationWithinPageForFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didCancelClientRedirectForFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView willCloseFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame{};
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject{};

@end

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

-(void)testThrowsExceptionIfDelegateReplaced {
    TransitWebViewContext *context = [self contextWithEmptyPage];

    STAssertTrue(context.webView.frameLoadDelegate == context, @"frameLoadDelegate wired");

    id otherDelegate = [NSObject new];
    STAssertThrows([context.webView setFrameLoadDelegate: otherDelegate], @"delegate property must not be replaced");
    STAssertTrue(context.webView.frameLoadDelegate == otherDelegate, @"frameLoadDelegate replaced");
}

-(void)testOriginalDelegateWillBeCalled {
    WebView* webView = WebView.new;
    // there's now protocol for WebFrameLoadDelegate, so just use the Context

    id mockedDelegate = [OCMockObject partialMockForObject:__WebFrameLoadDelegateImpl.new];

    webView.frameLoadDelegate = mockedDelegate;
    STAssertTrue(webView.frameLoadDelegate == mockedDelegate, @"delegate wired to mock");

    [[mockedDelegate expect] webView:OCMOCK_ANY didClearWindowObject:OCMOCK_ANY forFrame:OCMOCK_ANY];

    TransitWebViewContext *context = [TransitWebViewContext contextWithWebView:webView];
    STAssertTrue(webView.frameLoadDelegate == context, @"delegate wired to context");
    STAssertTrue(context.originalFrameLoadDelegate == mockedDelegate, @"mocked delegated kept by context");

    // test if context passes calls through
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://some.server"]];
    NSError *error = [NSError errorWithDomain:@"test" code:123 userInfo:nil];

    [self.class waitForWebViewToBeLoaded:webView];


    [[mockedDelegate expect] webView:nil didStartProvisionalLoadForFrame:nil];
    [context webView:nil didStartProvisionalLoadForFrame:nil];

    [[mockedDelegate expect] webView:nil didReceiveServerRedirectForProvisionalLoadForFrame:nil];
    [context webView:nil didReceiveServerRedirectForProvisionalLoadForFrame:nil];

    [[mockedDelegate expect] webView:nil didFailProvisionalLoadWithError:nil forFrame:nil];
    [context webView:nil didFailProvisionalLoadWithError:nil forFrame:nil];

    [[mockedDelegate expect] webView:nil didCommitLoadForFrame:nil];
    [context webView:nil didCommitLoadForFrame:nil];

    [[mockedDelegate expect] webView:nil didReceiveTitle:nil forFrame:nil];
    [context webView:nil didReceiveTitle:nil forFrame:nil];

    [[mockedDelegate expect] webView:nil didReceiveIcon:nil forFrame:nil];
    [context webView:nil didReceiveIcon:nil forFrame:nil];

    [[mockedDelegate expect] webView:nil didFinishLoadForFrame:nil];
    [context webView:nil didFinishLoadForFrame:nil];

    [[mockedDelegate expect] webView:nil didFailLoadWithError:nil forFrame:nil];
    [context webView:nil didFailLoadWithError:nil forFrame:nil];

    [[mockedDelegate expect] webView:nil didChangeLocationWithinPageForFrame:nil];
    [context webView:nil didChangeLocationWithinPageForFrame:nil];

    [[mockedDelegate expect] webView:nil willPerformClientRedirectToURL:nil delay:0 fireDate:nil forFrame:nil];
    [context webView:nil willPerformClientRedirectToURL:nil delay:0 fireDate:nil forFrame:nil];

    [[mockedDelegate expect] webView:nil didCancelClientRedirectForFrame:nil];
    [context webView:nil didCancelClientRedirectForFrame:nil];

    [[mockedDelegate expect] webView:nil willCloseFrame:nil];
    [context webView:nil willCloseFrame:nil];

    [[mockedDelegate expect] webView:nil didClearWindowObject:nil forFrame:nil];
    [context webView:nil didClearWindowObject:nil forFrame:nil];

    [[mockedDelegate expect] webView:nil windowScriptObjectAvailable:nil];
    [context webView:nil windowScriptObjectAvailable:nil];

    STAssertNoThrow([mockedDelegate verify], @"verify");
}



@end