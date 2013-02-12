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

@interface TransitUIWebViewTests : SenTestCase

@end

@implementation TransitUIWebViewTests {
    NSString* _storedJSRuntimeCode;
}

-(void)setUp {
    [super setUp];
    _storedJSRuntimeCode = _TRANSIT_JS_RUNTIME_CODE;
}

-(void)tearDown {
    _TRANSIT_JS_RUNTIME_CODE = _storedJSRuntimeCode;
    [super tearDown];
}

-(UIWebView*)webViewWithEmptyPage {
    UIWebView* result = [UIWebView new];
    [result loadHTMLString:@"<html><head><title>Empty Page</title></head><body></body></html>" baseURL:nil];
    return result;
}

+(void)waitForWebViewToBeLoaded:(UIWebView*)webView {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    while (webView.loading) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        NSLog(@"waiting for webview to load...");
    }
}

-(void)testResultTypes {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    
    STAssertEqualObjects([context eval:@"2+2"], @4, @"number");
    STAssertEqualObjects([context eval:@"3>2"], @YES, @"boolean");
    STAssertEqualObjects([context eval:@"'foo'+'bar'"], @"foobar", @"string");
    
    id object = [context eval:@"{a:1,b:'two'}"];
    // isKindOf: test crucial since recursiveMarkerReplacement tests this way, too
    STAssertTrue([object isKindOfClass:NSDictionary.class], @"NSDictionary");
    STAssertEqualObjects(object,(@{@"a":@1,@"b":@"two"}), @"object");
    
    id array = [context eval:@"[1,2,3]"];
    // isKindOf: test crucial since recursiveMarkerReplacement tests this way, too
    STAssertTrue([array isKindOfClass:NSArray.class], @"NSArray");
    STAssertEqualObjects(array,(@[@1,@2,@3]), @"array");
    
    
    STAssertEqualObjects([context eval:@"null"], NSNull.null, @"null");
    STAssertEqualObjects([context eval:@"undefined"], nil, @"undefined");
}

-(void)testArguments {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    STAssertEqualObjects([context eval:@"@ + @" arg:@"2+2" arg:@4], @"2+24", @"'2+2' + 4 == '2+24'");
}

-(void)testThisArg {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    STAssertEqualObjects([context eval:@"this.a + @" thisArg:@{@"a":@"foo"} arg:@"bar"], @"foobar", @"this has been set");
}

-(void)testInjectsCode {
    _TRANSIT_JS_RUNTIME_CODE = @"window.findme = true";
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    context.proxifyEval = NO;
    
    STAssertEqualObjects(@YES, [context eval:@"window.findme"], @"code has been injected");
    [self.class waitForWebViewToBeLoaded:context.webView];
    STAssertEqualObjects(@"Empty Page", [context eval:@"document.title"], @"can access title");
    
}

-(void)testInjectsCodeOnReloadOfHTMLString {
    _TRANSIT_JS_RUNTIME_CODE = @"window.findme = true";
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    context.proxifyEval = NO;
    
    STAssertEqualObjects(@"boolean", [context eval:@"typeof window.findme"], @"code has been injected");

    // wait for page to be fully loaded, otherwise JS code won't get replaced on reload below
    [self.class waitForWebViewToBeLoaded:context.webView];
    
    STAssertEqualObjects(@"boolean", [context eval:@"typeof window.findme"], @"code has been injected");

    [context.webView loadHTMLString:@"<head><title>Changed</title></head><body></body>" baseURL:nil];
    [self.class waitForWebViewToBeLoaded:context.webView];
    
    STAssertEqualObjects(@"Changed", [context eval:@"document.title"], @"code has been injected");
    STAssertEqualObjects(@"boolean", [context eval:@"typeof window.findme"], @"code has been injected");
}

-(void)testInjectsCodeOnReloadOfURLLoad {
    _TRANSIT_JS_RUNTIME_CODE = @"window.findme = {v:1, add:function(){window.findme.v++;}}";
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    context.proxifyEval = NO;
    

    STAssertEqualObjects(@"object", [context eval:@"typeof window.findme"], @"code has been injected");
    
    // wait for page to be fully loaded, otherwise JS code won't get replaced on reload below
    [self.class waitForWebViewToBeLoaded:context.webView];

    STAssertEqualObjects(@"object", [context eval:@"typeof window.findme"], @"code has been injected");
    
    STAssertEqualObjects(@1, [context eval:@"window.findme.v"], @"code has been injected");
    [context eval:@"window.findme.add()"];
    STAssertEqualObjects(@2, [context eval:@"window.findme.v"], @"code has been injected");
    
    NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"testPage" withExtension:@"html"];
    [context.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.class waitForWebViewToBeLoaded:context.webView];
    
    STAssertEqualObjects(@"TestPage from File", [context eval:@"document.title"], @"code has been injected");
    STAssertEqualObjects(@"object", [context eval:@"typeof window.findme"], @"code has been injected");
    STAssertEqualObjects(@1, [context eval:@"window.findme.v"], @"code has been reset");
}

-(TransitJSFunction*)callContext:(TransitContext*)context {
    NSString* js = @"(function(arg){\n"
            "window.globalTestVar = 'beforeCall '+arg;\n"
            "var iFrame = document.createElement('iframe');\n"
            "iFrame.setAttribute('src', 'transit:'+arg);\n"
            "document.documentElement.appendChild(iFrame);\n"
            "iFrame.parentNode.removeChild(iFrame);\n"
            "iFrame = null;\n"
            "return window.globalTestVar;\n"
        "})";
    return [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:js];
}

-(void)testSimpleCallFromWebView{
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    context.handleRequestBlock = ^(TransitUIWebViewContext *ctx, NSURLRequest* req) {
        [ctx eval:@"window.globalTestVar = 'changedFromContext'"];
    };
    TransitFunction *func = [self callContext:context];
    
    [func call];
    
    STAssertEqualObjects(@"changedFromContext", [context eval:@"window.globalTestVar"], @"var changed in native code");
}

-(void)testRecursiveCallBetweenWebViewAndNative {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [self callContext:context];
    
    int expectedMaxDepth = 63;

    context.handleRequestBlock = ^(TransitUIWebViewContext *ctx, NSURLRequest* req) {
        int arg = req.URL.resourceSpecifier.intValue;
        
        if(arg <= expectedMaxDepth){
            NSNumber *succ = @(arg+1);
            [func callWithArg:succ];
            
            if(succ.intValue <= expectedMaxDepth) {
                STAssertEqualObjects(succ, [ctx eval:@"window.globalTestVar"], @"correct reentrant values");
            } else {
                NSString* expected = [NSString stringWithFormat:@"beforeCall %d", expectedMaxDepth+1];
                STAssertEqualObjects(expected, [ctx eval:@"window.globalTestVar"], @"max depth reached, frame will not block if max depth is exceed");
            }
        }
        [ctx eval:@"window.globalTestVar = @" arg:@(arg)];
    };
    
    [func callWithArg:@1];
    
    STAssertEqualObjects(@1, [context eval:@"window.globalTestVar"], @"var changed in native code");
}

-(void)testRealInjectionCodeCreatesGlobalTransitObject {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    STAssertTrue(context.proxifyEval, @"proxification enabled");
    context.proxifyEval = NO;
    id actual = [context eval:@"window.transit"];

    STAssertEqualObjects((@{@"lastRetainId":@0, @"retained":@{}}), actual, @"transit exists");
}

-(void)testTransitProxifiesFunction {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    id proxified = [context eval:@"function(){}"];
    id lastRetainId = [context eval:@"transit.lastRetainId"];
    
    STAssertEqualObjects(@1, lastRetainId, @"has been retained");
    STAssertTrue([proxified isKindOfClass:TransitProxy.class], @"is proxy");
    STAssertTrue([proxified isKindOfClass:TransitJSFunction.class], @"is function");
    STAssertEqualObjects(([NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_JS_FUNCTION_, lastRetainId]), [proxified proxyId], @"detected proxy id");
}

-(void)testTransitProxifiesDocument {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    id proxified = [context eval:@"document"];
    id lastRetainId = [context eval:@"transit.lastRetainId"];
    
    STAssertEqualObjects(@1, lastRetainId, @"has been retained");
    STAssertTrue([proxified isKindOfClass:TransitProxy.class], @"is proxy");
    STAssertFalse([proxified isKindOfClass:TransitJSFunction.class], @"is not a function");
    STAssertEqualObjects(([NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_, lastRetainId]), [proxified proxyId], @"has been proxified");
}

-(void)testCallThroughJavaScript {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        int a = [arguments[0] intValue];
        int b = [arguments[1] intValue];
        return @(a+b);
    }];
    [context retainNativeProxy:func];
    id result = [context eval:@"@(2,3)" arg:func];
    [func dispose];
    
    STAssertEqualObjects(@5, [context eval:@"transit.nativeInvokeTransferObject"], @"has been evaluated");
    STAssertEqualObjects(@5, result, @"correctly passes values");
}

-(id)captureErrorMessageFromContext:(TransitContext*)context whenCallingFunction:(TransitFunction*)function {
    NSString* js = @"(function(){\n"
    "var result = 'initial';"
    "try{\n"
    "   result = 'no error ' + @();\n"
    "} catch(e) {\n"
    "   result = e.message;\n"
    "}\n"
    "return result;\n"
    "})()";
    
    id result = [context eval:js arg:function];
    return result;
}

-(void)testInvokeNativeProducesJSExceptionIfNotHandledCorrectly {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    context.handleRequestBlock = nil;
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        // do nothing
        return nil;
    }];
    
    id result = [self captureErrorMessageFromContext:context whenCallingFunction:func];
    STAssertEqualObjects(@"internal error with transit: invocation transfer object not filled.", result, @"exception should be passed along");
}

-(void)testInvokeNativeThatThrowsExceptionWithoutLocalizedReason {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        @throw [NSException exceptionWithName:@"ExceptionName" reason:@"some reason" userInfo:nil];
    }];
    [context retainNativeProxy:func];
    id result = [self captureErrorMessageFromContext:context whenCallingFunction:func];
    [func dispose];
    STAssertEqualObjects(@"ExceptionName: some reason", result, @"exception should be passed along");
}

-(void)testInvokeNativeThatThrowsExceptionWithLocalizedReason {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        @throw [NSException exceptionWithName:@"ExceptionName" reason:@"some reason" userInfo:@{NSLocalizedDescriptionKey: @"localized description"}];
    }];
    [context retainNativeProxy:func];
    id result = [self captureErrorMessageFromContext:context whenCallingFunction:func];
    [func dispose];
    STAssertEqualObjects(@"localized description", result, @"exception should be passed along");
}

-(void)testNativeFunctionCanReturnVoid {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        return nil;
    }];
    [context retainNativeProxy:func];
    id result = [context eval:@"@()" arg:func];
    STAssertNil(result, @"objc:nil == js:void");
}

-(void)testNativeFunctionCanReturnNull {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        return NSNull.null;
    }];
    [context retainNativeProxy:func];
    id result = [context eval:@"@()" arg:func];
    STAssertEqualObjects(NSNull.null, result, @"objc:NSNull == js:null");
}


-(void)testInvokeNativeWithJSProxies {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        STAssertTrue([thisArg isKindOfClass:TransitJSFunction.class], @"this became js function proxy");
        STAssertTrue([arguments[0] isKindOfClass:TransitProxy.class], @"proxy");
        
        return [(TransitProxy*)arguments[0] proxyId];
    }];
    [context retainNativeProxy:func];
    // "this" will be a function -> proxy
    // arguments[0] is the window object -> proxy
    id result = [context eval:@"@.call(function(){}, window)" arg:func];
    [func dispose];
    id lastProxyId = [context eval:@"transit.lastRetainId"];
    NSString* expectedProxyId = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_, lastProxyId];
    
    STAssertEqualObjects(expectedProxyId, [result proxyId], @"proxy ids match");
}

-(void)exceptionWillBePropagatedOnContext:(TransitContext*)context {
    @try {
        [context eval:@"(function(){throw new Error('some error')})()"];
        STFail(@"should throw exception");
    }
    @catch (NSException *exception) {
        STAssertEqualObjects(@"TransitException", exception.name, @"exception.name");
        STAssertEqualObjects(@"some error", exception.reason, @"exception.reason");
        STAssertEqualObjects(@"Error while executing JavaScript: some error", exception.userInfo[NSLocalizedDescriptionKey], @"localized error description");
    }
}

-(void)testJSExceptionWillBePropagatedWithProxify {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    [self exceptionWillBePropagatedOnContext: context];
}

-(void)testJSExceptionWillBePropagatedWithoutProxify {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    context.proxifyEval = NO;
    [self exceptionWillBePropagatedOnContext: context];
}

-(void)testExceptionWithInvalidJS {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    @try {
        id result = [context eval:@"4*#"];
        STFail(@"should throw exception");
        STAssertEqualObjects(@"?", result, @"should never reach this line");
    }
    @catch (NSException *exception) {
        STAssertEqualObjects(@"TransitException", exception.name, @"exception.name");
        STAssertEqualObjects(@"Invalid JavaScript: 4*#", exception.reason, @"exception.reason");
        STAssertEqualObjects(@"Error while evaluating JavaScript. Seems to be invalid: 4*#", exception.userInfo[NSLocalizedDescriptionKey], @"localized error description");
    }
}

-(void)testCanCallJSFunction {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction* func = [context eval:@"function(a,b){return a+b}"];
    NSNumber* result = [func callWithArg:@1 arg:@2];
    STAssertEqualObjects(@3, result, @"sum");
}

-(void)testCanUseObjectProxy {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    [self.class waitForWebViewToBeLoaded:context.webView];
    TransitProxy* proxy = [context eval:@"window.document"];
    NSString* result = [context eval:@"@.title" arg:proxy];
    STAssertEqualObjects(@"Empty Page", result, @"document.title");
}

-(void)testPerformance {
    int num = 10;
    int len = 10;
    NSString* longString = [@"" stringByPaddingToLength:len withString:@"c" startingAtIndex:0];

    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    TransitFunction *nativeFunc = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"myId" block:^id(TransitProxy *thisArg, NSArray *arguments) {

        return [arguments[0] stringByAppendingFormat:@"%d", [arguments[1] intValue] ];
    }];
    [context retainNativeProxy:nativeFunc];
    
    TransitFunction* jsFunc = [context eval:@"function(a,b){return @(a,b);}" arg:nativeFunc];
    
    NSDate *start = [NSDate date];
    for(int i=0;i<num;i++) {
        NSString* result = [jsFunc callWithArg:longString arg:@(i)];
        STAssertEqualObjects(([longString stringByAppendingFormat:@"%d", i]), result, @"correct concat");
    }
    NSDate *methodFinish = [NSDate date];
    [nativeFunc dispose];

    NSTimeInterval ti = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"#### %.2f calls/s with len %d (%.0f ms for %d calls)", num/ti, len, ti * 1000, num);
    
    // results on iPhone 5 iOS 6.0.1:
    // #### 289.29 calls/s with len 10 (3457 ms for 1000 calls)
    // #### 284.18 calls/s with len 100 (3519 ms for 1000 calls)
    // #### 254.20 calls/s with len 1000 (3965 ms for 1000 calls)
}

-(void)testJasmine {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:UIWebView.new];
    NSURL *url = [NSBundle.mainBundle URLForResource:@"SpecRunner" withExtension:@"html" subdirectory:@"jasmine"];
    [context.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    __block BOOL finished = NO;
    TransitFunction *onFinish = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"onFinish" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        id results = [thisArg eval:@"{failed:this.results().failedCount, passed:this.results().passedCount}" thisArg:arguments[0]];
        finished = YES;
        STAssertEqualObjects(@0, results[@"failed"], @"no test failed");
        STAssertTrue([results[@"passed"] intValue]>=51, @"at the time of writing, 51 tests should have passed");
        return @"finished :)";
    }];
    
    TransitFunction *onLoad = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"onLoad" block:^id(TransitProxy *thisArg, NSArray *arguments) {
        [context eval:@"jasmineEnv.addReporter({reportRunnerResults: @})" arg:onFinish];
        return @"foo";
    }];
    [context retainNativeProxy:onLoad];
    [context retainNativeProxy:onFinish];
    [context eval:@"window.onload=@" arg:onLoad];
    
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

-(void)testJSContextKeepsDisposedJSFunction {
    TransitUIWebViewContext* context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    
    id funcMock = [OCMockObject mockForProtocol:@protocol(TransitFunctionBodyProtocol)];
    
    TransitFunction *nFunc = [context functionWithDelegate:funcMock];
    TransitFunction *jsFunc1 = [context eval:@"function(a){@('from1: '+a)}" arg:nFunc];
    TransitFunction *jsFunc2 = [context eval:@"function(a){@('from2: '+a)}" arg:jsFunc1];

    [[funcMock expect] callWithThisArg:OCMOCK_ANY arguments:@[@"from1: Foo"]];
    [jsFunc1 callWithArg:@"Foo"];

    [[funcMock expect] callWithThisArg:OCMOCK_ANY arguments:@[@"from1: from2: Bar"]];
    [jsFunc2 callWithArg:@"Bar"];

    NSString* jsListRetained = @"(function(){"
        "var keys = [];"
        "for(var key in transit.retained){"
            "keys.push('##'+key);"
        "}"
        "return keys;})()";
    id retained = [context eval:jsListRetained];
    STAssertEqualObjects((@[@"##__TRANSIT_JS_FUNCTION_1", @"##__TRANSIT_JS_FUNCTION_2"]), retained, @"two functions retained");
    
    [jsFunc1 dispose];
    [context drainJSProxies];
    
    retained = [context eval:jsListRetained];
    STAssertEqualObjects((@[@"##__TRANSIT_JS_FUNCTION_2"]), retained, @"only one functions retained");
    
    [[funcMock expect] callWithThisArg:OCMOCK_ANY arguments:@[@"from1: from2: No Crash"]];
    [jsFunc2 callWithArg:@"No Crash"];
    
    STAssertNoThrow([funcMock verify], @"mock is fine");
}


@end
