//
//  TransitUIWebViewTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Transit.h"
#import "Transit+Private.h"
#import "OCMock.h"
#import "TransitAbstractWebViewContextTests.h"

@interface TransitUIWebViewTests : TransitAbstractWebViewContextTests

@end

@implementation TransitUIWebViewTests

- (id)webViewOfContext:(TransitAbstractWebViewContext *)context {
    return [(TransitUIWebViewContext *) context webView];

    return nil;
}

-(UIWebView*)webViewWithEmptyPage {
    UIWebView* result = [UIWebView new];

    [result loadHTMLString:super.htmlStringForEmptyPage baseURL:nil];
    return result;
}

+(void)waitForWebViewToBeLoaded:(UIWebView*)webView {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    while (webView.loading) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        NSLog(@"waiting for webview to load...");
    }
}

+(void)loadHTMLString:(NSString*)htmlString inWebView:(UIWebView*)webView {
    [webView loadHTMLString:htmlString baseURL:nil];
}

+(void)loadRequest:(NSURLRequest*)request inWebView:(UIWebView*)webView {
    [webView loadRequest:request];
}

- (TransitUIWebViewContext *)contextWithEmptyPage {
    return [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
}

-(TransitJSFunction*)functionToCallContextBareToTheMetal:(TransitContext*)context {
    NSString* js = @"(function(arg){\n"
            "window.globalTestVar = 'beforeCall '+arg;\n"
            "var iFrame = document.createElement('iframe');\n"
            "iFrame.setAttribute('src', 'transit:'+arg);\n"
            "document.documentElement.appendChild(iFrame);\n"
            "iFrame.parentNode.removeChild(iFrame);\n"
            "iFrame = null;\n"
            "return window.globalTestVar;\n"
            "})";
    return [[TransitJSFunction alloc] initWitContext:context jsRepresentation:js];
}

#pragma mark - actual tests

-(void)_testJasmine {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:UIWebView.new];
    NSURL *url = [NSBundle.mainBundle URLForResource:@"SpecRunner" withExtension:@"html" subdirectory:@"jasmine"];
    [context.webView loadRequest:[NSURLRequest requestWithURL:url]];

    __block BOOL finished = NO;
    TransitFunction *onFinish = [[TransitNativeFunction alloc] initWithContext:context nativeId:@"onFinish" genericBlock:^id(TransitNativeFunctionCallScope *scope) {
        id results = [context eval:@"{failed:this.results().failedCount, passed:this.results().passedCount}" thisArg:scope.arguments[0]];
        finished = YES;
        STAssertEqualObjects(@0, results[@"failed"], @"no test failed");
        STAssertTrue([results[@"passed"] intValue] >= 51, @"at the time of writing, 51 tests should have passed");
        return @"finished :)";
    }];

    TransitFunction *onLoad = [[TransitNativeFunction alloc] initWithContext:context nativeId:@"onLoad" genericBlock:^id(TransitNativeFunctionCallScope *scope) {
        [context eval:@"jasmineEnv.addReporter({reportRunnerResults: @})" val:onFinish];
        return @"foo";
    }];
    [context retainNativeFunction:onLoad];
    [context retainNativeFunction:onFinish];
    [context eval:@"window.onload=@" val:onLoad];

    [self.class waitForWebViewToBeLoaded:context.webView];
    STAssertEqualObjects(@"Jasmine Spec Runner", [context eval:@"document.title"], @"page loaded");

    while (!finished) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        NSLog(@"waiting for tests to have finished");
    }

    [onLoad dispose];
    [onFinish dispose];

}

-(void)testThrowsExceptionIfDelegateReplaced {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:UIWebView.new];

    STAssertTrue(context.webView.delegate == context, @"delegate wired");

    id otherDelegate = [NSObject new];
    STAssertThrows([context.webView setDelegate: otherDelegate], @"delegate property must not be replaced");
    STAssertTrue(context.webView.delegate == otherDelegate, @"delegate replaced");
}

-(void)testOriginalDelegateWillBeCalled {
    UIWebView* webView = UIWebView.new;
    id mockedDelegate = [OCMockObject mockForProtocol:@protocol(UIWebViewDelegate)];

    webView.delegate = mockedDelegate;
    STAssertTrue(webView.delegate == mockedDelegate, @"delegate wired to mock");

    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:webView];

    STAssertTrue(webView.delegate == context, @"delegate wired to context");

    // test if context passes calls through
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://some.server"]];
    NSError *error = [NSError errorWithDomain:@"test" code:123 userInfo:nil];

    [[mockedDelegate expect] webView:webView shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeReload];
    [webView.delegate webView:webView shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeReload];

    [[mockedDelegate expect] webViewDidStartLoad:webView];
    [webView.delegate webViewDidStartLoad:webView];

    [[mockedDelegate expect] webViewDidFinishLoad:webView];
    [webView.delegate webViewDidFinishLoad:webView];

    [[mockedDelegate expect] webView:webView didFailLoadWithError:error];
    [webView.delegate webView:webView didFailLoadWithError:error];

    STAssertNoThrow([mockedDelegate verify], @"verify");
}


@end
