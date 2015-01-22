//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

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

@interface TransitContextTests : XCTestCase

@end

@implementation TransitContextTests {
    NSUInteger _transitContextLivingInstanceCountBefore;
}

-(void)setUp {
    [super setUp];
    _transitContextLivingInstanceCountBefore = _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;
}

-(void)tearDown {
    XCTAssertEqual(_transitContextLivingInstanceCountBefore, _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT, @"no garbage context created");
    [super tearDown];
}

-(void)testContextReturnsSelfAsContext {
    TransitContext *context = [TransitContext new];
    XCTAssertEqualObjects(context.context, context, @"equal");
    XCTAssertTrue(context.context == context, @"identity");
}

-(void)testJsRepresentationForProxy {
    TransitContext *context = [TransitContext new];
    NSString* actual = [context jsRepresentationForProxyWithId:@"someId"];
    XCTAssertEqualObjects(@"someId", actual, @"proxy representation is just the id, corresponding var will be put on scope");
}

-(void)testJsRepresentationToResolveProxy {
    TransitContext *context = [TransitContext new];
    NSString* actual = [context jsRepresentationToResolveProxyWithId:@"someId"];
    XCTAssertEqualObjects(@"transit.r(\"someId\")", actual, @"proxy representation as function");
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
        
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context retainNativeFunction:proxy];
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{@"someId":proxy}), @"correctly retained");
        
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
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{@"id1":p1, @"id2":p2}), @"retains both");
        
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
        XCTAssertEqual((NSUInteger)1, context.retainedNativeProxies.count, @"retains one object");
        [context retainNativeFunction:proxy];
        XCTAssertEqual((NSUInteger)1, context.retainedNativeProxies.count, @"still retains object");
        
        // manually reset retained objects to get rid of mocks.
        // See tests with FakeNativeProxyForTest to see that this isn't needed for real TransitProxies
        [context.retainedNativeProxies removeAllObjects];
    }
}

-(void)testNativeRetainRelease {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy = [self stubWithContext:context proxyId:@"someId"];
        
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context retainNativeFunction:proxy];
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{@"someId":proxy}), @"correctly retained");
        [context releaseNativeFunction:proxy];
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained anymore");
    }
}

-(void)testCannotReleaseNonRetained {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        TransitProxy *proxy =  [self stubWithContext:context proxyId:@"someId"];
        
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{}), @"nothing retained");
        [context releaseNativeFunction:proxy];
        XCTAssertEqualObjects(context.retainedNativeProxies, (@{}), @"still, nothing retained");
    }
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "objc_incompatible_pointers"
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
#pragma clang diagnostic pop

-(TransitProxy*)createAndReleaseContextButReturnNativeProxy {
    TransitProxy *proxy;

    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        XCTAssertEqual(1L, CFGetRetainCount((__bridge CFTypeRef)context), @"single ref");
        proxy = [[FakeNativeProxyForTest alloc] initWithContext:context proxyId:@"someId"];

//  retain behavior differs on iOS 6 (retainCount==1) and iOS5 (retainCount==4)
//        XCTAssertEqual(1L, CFGetRetainCount((__bridge CFTypeRef)context), @"still, single ref to context");

        XCTAssertEqual(1L, CFGetRetainCount((__bridge CFTypeRef)proxy), @"var keeps ref to proxy");

        [context retainNativeFunction:proxy];
    }
    XCTAssertEqual(1L, CFGetRetainCount((__bridge CFTypeRef)proxy), @"var keeps ref to proxy");
    
    return proxy;
}

-(void)testNoRetainCyclesAndDisposesNativeProxies {
    __weak TransitProxy* proxy;
    @autoreleasepool {
        proxy = [self createAndReleaseContextButReturnNativeProxy];
        
        XCTAssertTrue(proxy.disposed, @"proxy has been disposed");
        XCTAssertNil(proxy.context, @"hence, does not keep reference to context anymore");
    }
    XCTAssertNil(proxy, @"proxy is free");
}

-(void)testDoNotReplaceSimpleObjectsWithMarkers {
    TransitContext* context = TransitContext.new;
    XCTAssertEqualObjects(@42, [context recursivelyReplaceMarkersWithProxies:@42], @"do nothing on numbers");
    XCTAssertEqualObjects(@"foobar", [context recursivelyReplaceMarkersWithProxies:@"foobar"], @"do nothing on simple string");
}

-(void)testReplaceMarkerStrings {
    @autoreleasepool {
        TransitContext* context = TransitContext.new;

        NSString* marker = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_, @"someId"];
        id proxy = [context recursivelyReplaceMarkersWithProxies:marker];
        XCTAssertTrue([proxy isKindOfClass:TransitProxy.class], @"object proxy");
        XCTAssertFalse([proxy isKindOfClass:TransitJSFunction.class], @"function proxy");
        XCTAssertEqualObjects(marker, [proxy proxyId], @"extracts proxy id");

        marker = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_JS_FUNCTION_, @"someId"];
        proxy = [context recursivelyReplaceMarkersWithProxies:marker];
        XCTAssertTrue([proxy isKindOfClass:TransitProxy.class], @"object proxy");
        XCTAssertTrue([proxy isKindOfClass:TransitJSFunction.class], @"function proxy");
        XCTAssertEqualObjects(marker, [proxy proxyId], @"extracts proxy id");
    }
}

-(void)testDetectsMarkerStringsInComplexObject {
    @autoreleasepool {
        TransitContext* context = TransitContext.new;

        NSString* marker = [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_JS_FUNCTION_, @"someId"];

        // recursivelyReplaceMarkersWithProxies expects mutable array/dictionary
        id detected = [context recursivelyReplaceMarkersWithProxies:[NSMutableArray arrayWithArray:@[@1, @"two", [NSMutableDictionary dictionaryWithDictionary:@{@"three":@3, @4: marker}]]]];
        XCTAssertEqualObjects(@1, detected[0], @"one");
        XCTAssertEqualObjects(@"two", detected[1], @"two");
        XCTAssertEqualObjects(@3, detected[2][@"three"], @"three");
        id proxy = detected[2][@4];
        XCTAssertTrue([proxy isKindOfClass:TransitJSFunction.class], @"function proxy");
        XCTAssertEqualObjects(marker, [proxy proxyId], @"extracts proxy id");
    }
}

-(void)testRetainedNativeFunctionWithId {
    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        XCTAssertThrows([context retainedNativeFunctionWithId:@"someId"], @"no such function");
        
        TransitFunction* func = [context functionWithDelegate:nil];
        XCTAssertTrue(func == [context retainedNativeFunctionWithId:func.proxyId], @"yes, function exists");
        
        [func dispose];
        XCTAssertThrows([context retainedNativeFunctionWithId:func.proxyId], @"and disposed, again");
    }
}

-(void)testInvokeNativeWithMissingFunction {
    TransitContext* context = TransitContext.new;
    id result = [context invokeNativeWithDescription:@{@"nativeId" : @"missing"}];
    XCTAssertTrue([result isKindOfClass:NSError.class], @"missing native functions results in error");
    NSDictionary* userInfo = [result userInfo];
    XCTAssertEqualObjects(@"No native function with id: missing. Could have been disposed.",userInfo[NSLocalizedDescriptionKey], @"meaningful error message");
}

-(void)testInvokeNativeWithThisArgVariations {
    @autoreleasepool {
        TransitContext* context = TransitContext.new;
        TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:context nativeId:@"someId" genericBlock:^id(TransitNativeFunctionCallScope *scope) {
            return scope.thisArg;
        }];
        
        // js: this == undefined
        id result = [func callWithThisArg:nil];
        XCTAssertTrue(result == context, @"undefined");
        
        // js: this == null
        result = [func callWithThisArg:NSNull.null];
        XCTAssertTrue(result == context, @"null");
        
        // js: this == "3", e.g. transit.nativeFunc("someId").apply("3");
        result = [func callWithThisArg:@"3"];
        XCTAssertFalse([result isKindOfClass:TransitProxy.class], @"is not a proxy!");
        XCTAssertEqualObjects(@"3", result, @"does not wrap '3'");
    }
}

-(void)testNativeFunctionIdsMatchMagicMarker {
    TransitContext* context = TransitContext.alloc.init;
    XCTAssertEqualObjects(@"1", [context nextNativeFunctionId], @"first native function");
    XCTAssertEqualObjects(@"2", [context nextNativeFunctionId], @"second native function");
}

-(void)testAsyncCallToJSFunctionFillsQueue {
    @autoreleasepool {
        id context = [CCWeakMockProxy mockForClass:TransitContext.class];
        
        TransitJSFunction *jsFunc = [TransitJSFunction.alloc initWithContext:context proxyId:@"someId"];
        
        [[context expect] queueAsyncCallToJSFunction:jsFunc thisArg:nil arguments:@[@1, @2]];
        [jsFunc callAsyncWithArg:@1 arg:@2];

        XCTAssertNoThrow([context verify], @"verify mock");
        [jsFunc clearContextAndProxyId];
    }
}

-(void)testEmptyCallScope {
    TransitContext *context = TransitContext.new;
    TransitCallScope *actual = context.currentCallScope;
    XCTAssertNil(actual, @"nil if not inside a function");
}

-(void)testCallScopeCallNativeFuncDirectly {
    @autoreleasepool {
        TransitContext *context = TransitContext.new;

        id thisArg = @"thisValue";
        NSArray *arguments = @[@1, @2, @3];
        BOOL expectsResult = YES;

        __block TransitFunction *function = [context functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
            XCTAssertTrue(context.currentCallScope == callScope, @"currentCallScope");

            XCTAssertTrue(TransitCurrentCall.context == callScope.context, @"TransitCurrentCall.context");
            XCTAssertTrue(TransitCurrentCall.callScope == callScope, @"TransitCurrentCall.callScope");
            XCTAssertEqualObjects(TransitCurrentCall.thisArg, callScope.thisArg, @"TransitCurrentCall.thisArg");
            XCTAssertEqualObjects(TransitCurrentCall.arguments, callScope.arguments, @"TransitCurrentCall.arguments");

            BOOL callScopeIsBoundToCurrentFunction = callScope.function == function;
            XCTAssertTrue(callScopeIsBoundToCurrentFunction, @"current function");
            XCTAssertNil(callScope.parentScope, @"parent scope");
            return @{@"function" : callScope.function, @"thisArg" : callScope.thisArg, @"arguments" : callScope.arguments, @"expectsResult" : @(callScope.expectsResult)};
        }];

        XCTAssertNil(TransitCurrentCall.context, @"TransitCurrentCall.context");
        XCTAssertNil(TransitCurrentCall.callScope, @"TransitCurrentCall.callScope");
        XCTAssertNil(TransitCurrentCall.thisArg, @"TransitCurrentCall.thisArg");
        XCTAssertNil(TransitCurrentCall.arguments, @"TransitCurrentCall.arguments");

        NSDictionary* scope = [function callWithThisArg:thisArg arguments:arguments returnResult:expectsResult];

        XCTAssertNil(TransitCurrentCall.context, @"TransitCurrentCall.context");
        XCTAssertNil(TransitCurrentCall.callScope, @"TransitCurrentCall.callScope");
        XCTAssertNil(TransitCurrentCall.thisArg, @"TransitCurrentCall.thisArg");
        XCTAssertNil(TransitCurrentCall.arguments, @"TransitCurrentCall.arguments");


        NSDictionary *expected = @{@"function": function, @"thisArg":thisArg, @"arguments":arguments, @"expectsResult": @(expectsResult)};
        XCTAssertEqualObjects(scope, expected, @"scope");

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

            XCTAssertTrue(context.currentCallScope == callScope, @"currentCallScope");

            XCTAssertTrue(TransitCurrentCall.context == callScope.context, @"TransitCurrentCall.context");
            XCTAssertTrue(TransitCurrentCall.callScope == callScope, @"TransitCurrentCall.callScope");
            XCTAssertEqualObjects(TransitCurrentCall.thisArg, callScope.thisArg, @"TransitCurrentCall.thisArg");
            XCTAssertEqualObjects(TransitCurrentCall.arguments, callScope.arguments, @"TransitCurrentCall.arguments");

            return nil;
        }];

        __block TransitFunction *function2 = [context functionWithGenericBlock:^id(TransitNativeFunctionCallScope *callScope) {
            scope2 = callScope;

            XCTAssertTrue(context.currentCallScope == callScope, @"currentCallScope");
            [function1 callWithThisArg:thisArg1 arguments:arguments1 returnResult:expectsResult1];
            XCTAssertTrue(context.currentCallScope == callScope, @"currentCallScope after call");

            XCTAssertTrue(TransitCurrentCall.context == callScope.context, @"TransitCurrentCall.context");
            XCTAssertTrue(TransitCurrentCall.callScope == callScope, @"TransitCurrentCall.callScope");
            XCTAssertEqualObjects(TransitCurrentCall.thisArg, callScope.thisArg, @"TransitCurrentCall.thisArg");
            XCTAssertEqualObjects(TransitCurrentCall.arguments, callScope.arguments, @"TransitCurrentCall.arguments");

            return nil;
        }];

        XCTAssertNil(TransitCurrentCall.context, @"TransitCurrentCall.context");
        XCTAssertNil(TransitCurrentCall.callScope, @"TransitCurrentCall.callScope");
        XCTAssertNil(TransitCurrentCall.thisArg, @"TransitCurrentCall.thisArg");
        XCTAssertNil(TransitCurrentCall.arguments, @"TransitCurrentCall.arguments");

        [function2 callWithThisArg:thisArg2 arguments:arguments2 returnResult:expectsResult2];

        XCTAssertNil(TransitCurrentCall.context, @"TransitCurrentCall.context");
        XCTAssertNil(TransitCurrentCall.callScope, @"TransitCurrentCall.callScope");
        XCTAssertNil(TransitCurrentCall.thisArg, @"TransitCurrentCall.thisArg");
        XCTAssertNil(TransitCurrentCall.arguments, @"TransitCurrentCall.arguments");

        XCTAssertTrue(function1 == scope1.function, @"function");
        XCTAssertEqualObjects(thisArg1, scope1.thisArg, @"thisArg");
        XCTAssertEqualObjects(arguments1, scope1.arguments, @"arguments");
        XCTAssertEqual(expectsResult1, scope1.expectsResult, @"expectsResult");
        XCTAssertTrue(scope2 == scope1.parentScope, @"parentScope");

        XCTAssertTrue(function2 == scope2.function, @"function");
        XCTAssertEqualObjects(thisArg2, scope2.thisArg, @"thisArg");
        XCTAssertEqualObjects(arguments2, scope2.arguments, @"arguments");
        XCTAssertEqual(expectsResult2, scope2.expectsResult, @"expectsResult");
        XCTAssertNil(scope2.parentScope, @"parentScope");

        // set to nil explicitly to release object ref
        scope1 = nil;
        scope2 = nil;

        [function1 dispose];
        [function2 dispose];

        // set to nil explicitly to release object ref
        function1 = nil;
        function2 = nil;
    }
}

-(void)testRecursivelyReplaceBlocksWithNativeFunctions {
    if(!transit_specificBlocksSupported())
        return;

    @autoreleasepool {
        TransitContext *context = TransitContext.new;
        //Class cls = NSClassFromString(@"NSBlock");
        Class cls = TransitNativeFunction.class;

        id func = [context recursivelyReplaceBlocksWithNativeFunctions:^{}];
        XCTAssertTrue([func isKindOfClass:cls], @"single block)");

        NSArray *array = [context recursivelyReplaceBlocksWithNativeFunctions:@[@"foo", ^{}]];
        XCTAssertTrue([array[1] isKindOfClass:cls], @"array)");
        XCTAssertEqualObjects(array[0], @"foo", @"keep non-funcs untouched");

        NSDictionary *dict = [context recursivelyReplaceBlocksWithNativeFunctions:@{@"foo": ^{}, @"bar": @"baz"}];
        XCTAssertTrue([dict[@"foo"] isKindOfClass:cls], @"array)");
        XCTAssertEqualObjects(dict[@"bar"], @"baz", @"keep non-funcs untouched");

        array = [context recursivelyReplaceBlocksWithNativeFunctions:@[@{@"foo": ^{}, @"bar": @"baz"}]];
        dict = array[0];
        XCTAssertTrue([dict[@"foo"] isKindOfClass:cls], @"array)");
        XCTAssertEqualObjects(dict[@"bar"], @"baz", @"keep non-funcs untouched");

        func = nil;
        array = nil;
        dict = nil;
        [context dispose];
    }
}



@end
