//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Transit.h"
#import "Transit+Private.h"
#import "OCMock.h"
#import "OCMockObject+Reset.h"


@interface FakeNativeProxyForTest : TransitProxy

@end

@implementation FakeNativeProxyForTest

-(void)dispose {
    if(self.context && self.proxyId) {
        [self.context releaseNativeFunction:self];
    }
    [self clearContextAndProxyId];
}
@end

@interface TransitContextTests : SenTestCase

@end

@implementation TransitContextTests {
    NSUInteger _transitContextLivingInstanceCountBefore;
}

-(void)setUp {
    [super setUp];
    _transitContextLivingInstanceCountBefore = _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;
}

-(void)tearDown {
    STAssertEquals(_transitContextLivingInstanceCountBefore, _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT, @"no garbage context created");
    [super tearDown];
}

-(void)testJsRepresentationForProxy {
    TransitContext *context = [TransitContext new];
    NSString* actual = [context jsRepresentationForProxyWithId:@"someId"];
    STAssertEqualObjects(@"someId", actual, @"proxy representation is just the id, corresponding var will be put on scope");
}

-(void)testJsRepresentationToResolveProxy {
    TransitContext *context = [TransitContext new];
    NSString* actual = [context jsRepresentationToResolveProxyWithId:@"someId"];
    STAssertEqualObjects(@"transit.r(\"someId\")", actual, @"proxy representation as function");
}

-(TransitProxy*)stubWithContext:(TransitContext*)context proxyId:(NSString*)proxyId {
    id proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[proxy stub] andReturn:context] context];
    [[[proxy stub] andReturn:proxyId] proxyId];
    return proxy;
}

-(void)testSingleNativeRetain {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context retainNativeFunction:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{@"someId":proxy}), @"correctly retained");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testMultipleNativeRetains {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *p1 = [self stubWithContext:context proxyId:@"id1"];
        TransitProxy *p2 = [self stubWithContext:context proxyId:@"id2"];
        [context retainNativeFunction:p1];
        [context retainNativeFunction:p2];
        STAssertEqualObjects(context.retainedNativeProxies, (@{@"id1":p1, @"id2":p2}), @"retains both");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testMutipleNativeRetainsForSameObjectWithoutEffect {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];

        [context retainNativeFunction:proxy];
        STAssertEquals((NSUInteger)1, context.retainedNativeProxies.count, @"retains one object");
        [context retainNativeFunction:proxy];
        STAssertEquals((NSUInteger)1, context.retainedNativeProxies.count, @"still retains object");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testNativeRetainRelease {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context retainNativeFunction:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{@"someId":proxy}), @"correctly retained");
        [context releaseNativeFunction:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained anymore");
    }
}

-(void)testCannotReleaseNonRetained {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy =  [self stubWithContext:context proxyId:@"someId"];
        
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context releaseNativeFunction:proxy];
        STAssertEqualObjects(context.retainedNativeProxies, (@{}), @"still, nothing retained");
    }
}

-(void)testDisposesNativeProxiesOnDispose {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        [[(OCMockObject*)proxy expect] dispose];
        [context retainNativeFunction:proxy];
        [context dispose];
        [(OCMockObject*)proxy verify];
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(TransitProxy*)createAndReleaseContextButReturnNativeProxy {
    TransitProxy *proxy;

    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)context), @"single ref");
        proxy = [[FakeNativeProxyForTest alloc] initWithContext:context proxyId:@"someId"];
        STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)context), @"still, single ref to context");
        STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)proxy), @"var keeps ref to proxy");

        [context retainNativeFunction:proxy];
    }
    STAssertEquals(1L, CFGetRetainCount((__bridge CFTypeRef)proxy), @"var keeps ref to proxy");
    
    return proxy;
}

-(void)testNoRetainCyclesAndDisposesNativeProxies {
    __weak TransitProxy* proxy;
    @autoreleasepool {
        proxy = [self createAndReleaseContextButReturnNativeProxy];
        
        STAssertTrue(proxy.disposed, @"proxy has been disposed");
        STAssertNil(proxy.context, @"hence, does not keep reference to context anymore");
    }
    STAssertNil(proxy, @"proxy is free");
}

-(void)testDoNotReplaceSimpleObjectsWithMarkers {
    TransitContext* context = TransitContext.new;
    STAssertEqualObjects(@42, [context recursivelyReplaceMarkersWithProxies:@42], @"do nothing on numbers");
    STAssertEqualObjects(@"foobar", [context recursivelyReplaceMarkersWithProxies:@"foobar"], @"do nothing on simple string");
}

-(void)testReplaceMarkerStrings {
    TransitContext* context = TransitContext.new;
    
    NSString* marker = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_, @"someId"];
    id proxy = [context recursivelyReplaceMarkersWithProxies:marker];
    STAssertTrue([proxy isKindOfClass:TransitProxy.class], @"object proxy");
    STAssertFalse([proxy isKindOfClass:TransitJSFunction.class], @"function proxy");
    STAssertEqualObjects(marker, [proxy proxyId], @"extracts proxy id");

    marker = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_JS_FUNCTION_, @"someId"];
    proxy = [context recursivelyReplaceMarkersWithProxies:marker];
    STAssertTrue([proxy isKindOfClass:TransitProxy.class], @"object proxy");
    STAssertTrue([proxy isKindOfClass:TransitJSFunction.class], @"function proxy");
    STAssertEqualObjects(marker, [proxy proxyId], @"extracts proxy id");
}

-(void)testDetectsMarkerStringsInComplexObject {
    TransitContext* context = TransitContext.new;
    
    NSString* marker = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_JS_FUNCTION_, @"someId"];
    
    // recursivelyReplaceMarkersWithProxies expects mutable array/dictionary
    id detected = [context recursivelyReplaceMarkersWithProxies:[NSMutableArray arrayWithArray:@[@1, @"two", [NSMutableDictionary dictionaryWithDictionary:@{@"three":@3, @4: marker}]]]];
    STAssertEqualObjects(@1, detected[0], @"one");
    STAssertEqualObjects(@"two", detected[1], @"two");
    STAssertEqualObjects(@3, detected[2][@"three"], @"three");
    id proxy = detected[2][@4];
    STAssertTrue([proxy isKindOfClass:TransitJSFunction.class], @"function proxy");
    STAssertEqualObjects(marker, [proxy proxyId], @"extracts proxy id");
}

-(void)testRetainedNativeFunctionWithId {
    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        STAssertThrows([context retainedNativeFunctionWithId:@"someId"], @"no such function");
        
        TransitFunction* func = [context functionWithDelegate:nil];
        STAssertTrue(func == [context retainedNativeFunctionWithId:func.proxyId], @"yes, function exists");
        
        [func dispose];
        STAssertThrows([context retainedNativeFunctionWithId:func.proxyId], @"and disposed, again");
    }
}

-(void)testInvokeNativeWithMissingFunction {
    TransitContext* context = TransitContext.new;
    id result = [context invokeNativeWithDescription:@{@"nativeId" : @"missing"}];
    STAssertTrue([result isKindOfClass:NSError.class], @"missing native functions results in error");
    STAssertEqualObjects(@"No native function with id: missing. Could have been disposed.", [result userInfo][NSLocalizedDescriptionKey], @"meaningful error message");
}

-(void)testInvokeNativeWithThisArgVariations {
    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:context nativeId:@"someId" genericBlock:^id(TransitNativeFunctionCallScope *scope) {
            return scope.thisArg;
        }];
        
        // js: this == undefined
        id result = [func callWithThisArg:nil];
        STAssertTrue(result == context, @"undefined");
        
        // js: this == null
        result = [func callWithThisArg:NSNull.null];
        STAssertTrue(result == context, @"null");
        
        // js: this == "3", e.g. transit.nativeFunc("someId").apply("3");
        result = [func callWithThisArg:@"3"];
        STAssertFalse([result isKindOfClass:TransitProxy.class], @"is not a proxy!");
        STAssertEqualObjects(@"3", result, @"does not wrap '3'");
    }
}

-(void)testNativeFunctionIdsMatchMagicMarker {
    TransitContext* context = TransitContext.alloc.init;
    STAssertEqualObjects(@"1", [context nextNativeFunctionId], @"first native function");
    STAssertEqualObjects(@"2", [context nextNativeFunctionId], @"second native function");
}

-(void)testAsyncCallToJSFunctionFillsQueue {
    @autoreleasepool {
        id context = [OCMockObject mockForClass:TransitContext.class];
        
        TransitJSFunction *jsFunc = [TransitJSFunction.alloc initWithContext:context proxyId:@"someId"];
        
        [[context expect] queueAsyncCallToJSFunction:jsFunc thisArg:nil arguments:@[@1, @2]];
        [jsFunc callAsyncWithArg:@1 arg:@2];

        STAssertNoThrow([context verify], @"verify mock");
        [jsFunc clearContextAndProxyId];
    }
}

-(void)testEmptyCallScope {
    TransitContext *context = TransitContext.new;
    TransitCallScope *actual = context.currentCallScope;
    STAssertNil(actual, @"nil if not inside a function");
}

-(void)testCallScopeCallNativeFuncDirectly {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;

        id thisArg = @"thisValue";
        NSArray *arguments = @[@1, @2, @3];
        BOOL expectsResult = YES;

        __block TransitFunction *function = [context functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
            STAssertTrue(context.currentCallScope == callScope, @"currentCallScope");

            BOOL callScopeIsBoundToCurrentFunction = callScope.function == function;
            STAssertTrue(callScopeIsBoundToCurrentFunction, @"current function");
            STAssertNil(callScope.parentScope, @"parent scope");
            return @{@"function" : callScope.function, @"thisArg" : callScope.thisArg, @"arguments" : callScope.arguments, @"expectsResult" : @(callScope.expectsResult)};
        }];

        NSDictionary* scope = [function callWithThisArg:thisArg arguments:arguments returnResult:expectsResult];

        NSDictionary *expected = @{@"function": function, @"thisArg":thisArg, @"arguments":arguments, @"expectsResult": @(expectsResult)};
        STAssertEqualObjects(scope, expected, @"scope");

        [function dispose];
        function = nil;
    }
}

-(void)testCallScopeCallTwoNativeFunctionsDirectly {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;

        id thisArg1 = @"thisValue";
        NSArray *arguments1 = @[@1, @2, @3];
        BOOL expectsResult1 = YES;

        id thisArg2 = @"thisValue2";
        NSArray *arguments2 = @[@2, @3, @4];
        BOOL expectsResult2 = YES;

        __block TransitFunctionCallScope *scope1;
        __block TransitFunctionCallScope *scope2;

         __block TransitFunction *function1 = [context functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
             scope1 = callScope;

             STAssertTrue(context.currentCallScope == callScope, @"currentCallScope");

             return nil;
         }];

        __block TransitFunction *function2 = [context functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
            scope2 = callScope;

            STAssertTrue(context.currentCallScope == callScope, @"currentCallScope");
            [function1 callWithThisArg:thisArg1 arguments:arguments1 returnResult:expectsResult1];
            STAssertTrue(context.currentCallScope == callScope, @"currentCallScope after call");

            return nil;
        }];

        [function2 callWithThisArg:thisArg2 arguments:arguments2 returnResult:expectsResult2];

        STAssertTrue(function1 == scope1.function, @"function");
        STAssertEqualObjects(thisArg1, scope1.thisArg, @"thisArg");
        STAssertEqualObjects(arguments1, scope1.arguments, @"arguments");
        STAssertEquals(expectsResult1, scope1.expectsResult, @"expectsResult");
        STAssertTrue(scope2 == scope1.parentScope, @"parentScope");

        STAssertTrue(function2 == scope2.function, @"function");
        STAssertEqualObjects(thisArg2, scope2.thisArg, @"thisArg");
        STAssertEqualObjects(arguments2, scope2.arguments, @"arguments");
        STAssertEquals(expectsResult2, scope2.expectsResult, @"expectsResult");
        STAssertNil(scope2.parentScope, @"parentScope");

        scope1 = nil;
        scope2 = nil;

        [function1 dispose];
        [function2 dispose];
        function1 = nil;
        function2 = nil;
    }
}



@end
