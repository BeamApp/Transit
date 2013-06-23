//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "TransitAbstractWebViewContextTests.h"

#import "Transit.h"
#import "Transit+Private.h"
#import "OCMockObject+Reset.h"
#import "OCMock.h"
#import "CCWeakMockProxy.h"


@implementation TransitAbstractWebViewContextTests {
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

- (TransitAbstractWebViewContext *)contextWithEmptyPage {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+(void)waitForWebViewToBeLoaded:(id)webView {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+(void)loadHTMLString:(NSString*)htmlString inWebView:(id)webView {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+(void)loadRequest:(NSURLRequest*)request inWebView:(id)webView {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSArray *) testInvocations {
    if(self.class == TransitAbstractWebViewContextTests.class)
        return @[];

    NSArray* result = [super testInvocations];
    return result;
}

-(void)testResultTypes {
    TransitAbstractWebViewContext *context = [self contextWithEmptyPage];

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

-(void)testInjectsCode {
    _TRANSIT_JS_RUNTIME_CODE = @"window.findme = true";
    TransitAbstractWebViewContext *context = [self contextWithEmptyPage];
    context.proxifyEval = NO;

    STAssertEqualObjects(@YES, [context eval:@"window.findme"], @"code has been injected");
    [self.class waitForWebViewToBeLoaded:context.webView];
    STAssertEqualObjects(@"Empty Page", [context eval:@"document.title"], @"can access title");

}

-(void)testInjectsCodeOnReloadOfHTMLString {
    _TRANSIT_JS_RUNTIME_CODE = @"window.findme = true";
    TransitAbstractWebViewContext *context = [self contextWithEmptyPage];
    context.proxifyEval = NO;

    STAssertEqualObjects(@"boolean", [context eval:@"typeof window.findme"], @"code has been injected");

    // wait for page to be fully loaded, otherwise JS code won't get replaced on reload below
    [self.class waitForWebViewToBeLoaded:context.webView];

    STAssertEqualObjects(@"boolean", [context eval:@"typeof window.findme"], @"code has been injected");

    [self.class loadHTMLString:@"<head><title>Changed</title></head><body></body>" inWebView:context.webView];
    [self.class waitForWebViewToBeLoaded:context.webView];

    STAssertEqualObjects(@"Changed", [context eval:@"document.title"], @"code has been injected");
    STAssertEqualObjects(@"boolean", [context eval:@"typeof window.findme"], @"code has been injected");
}

-(void)testInjectsCodeOnReloadOfURLLoad {
    _TRANSIT_JS_RUNTIME_CODE = @"window.findme = {v:1, add:function(){window.findme.v++;}}";
    TransitAbstractWebViewContext *context = [self contextWithEmptyPage];
    context.proxifyEval = NO;


    STAssertEqualObjects(@"object", [context eval:@"typeof window.findme"], @"code has been injected");

    // wait for page to be fully loaded, otherwise JS code won't get replaced on reload below
    [self.class waitForWebViewToBeLoaded:context.webView];

    STAssertEqualObjects(@"object", [context eval:@"typeof window.findme"], @"code has been injected");

    STAssertEqualObjects(@1, [context eval:@"window.findme.v"], @"code has been injected");
    [context eval:@"window.findme.add()"];
    STAssertEqualObjects(@2, [context eval:@"window.findme.v"], @"code has been injected");

    NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"testPage" withExtension:@"html"];
    STAssertNotNil(url, @"url from test asset could be loaded");
    [self.class loadRequest:[NSURLRequest requestWithURL:url] inWebView:context.webView];

    [self.class waitForWebViewToBeLoaded:context.webView];

    STAssertEqualObjects(@"TestPage from File", [context eval:@"document.title"], @"code has been injected");
    STAssertEqualObjects(@"object", [context eval:@"typeof window.findme"], @"code has been injected");
    STAssertEqualObjects(@1, [context eval:@"window.findme.v"], @"code has been reset");
}

-(void)testProxifyOfGlobalObject {
    TransitAbstractWebViewContext *context = [self contextWithEmptyPage];
    id actual = [context eval:@"window"];
    STAssertEqualObjects(context, actual, @"just to get better output on failure");
    STAssertTrue(context == actual, @"window is same proxy again");

    actual = [context eval:@"this"];
    STAssertEqualObjects(context, actual, @"just to get better output on failure");
    STAssertTrue(context == actual, @"this = window is same proxy again");
}

- (NSString *)htmlStringForEmptyPage {
    return @"<html><head><title>Empty Page</title></head><body></body></html>";
}
@end
