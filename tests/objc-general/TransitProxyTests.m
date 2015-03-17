//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

@interface TransitProxyTests : XCTestCase

@end

@implementation TransitProxyTests

-(void)testJSRepresentationForNSError {
    NSError *error = [NSError errorWithDomain:@"transit" code:1 userInfo:@{NSLocalizedDescriptionKey:@"some description"}];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentationFromCode:@"@" arguments:@[error] collectingProxiesOnScope:proxiesOnScope];
    XCTAssertEqualObjects(@"new Error(\"some description\")", actual, @"error");
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies needed");
}

- (void)testJSExpressionFromCodeAndArguments {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;

    XCTAssertEqualObjects(@"no arguments", [TransitProxy jsRepresentationFromCode:@"no arguments" arguments:@[] collectingProxiesOnScope:proxiesOnScope], @"no arguments");
    
    XCTAssertEqualObjects(@"int: 23", [TransitProxy jsRepresentationFromCode:@"int: @" arguments:@[@23] collectingProxiesOnScope:proxiesOnScope], @"one int");
    XCTAssertEqualObjects(@"float: 42.5", [TransitProxy jsRepresentationFromCode:@"float: @" arguments:@[@42.5] collectingProxiesOnScope:proxiesOnScope], @"one float");
    XCTAssertEqualObjects(@"bool: true", [TransitProxy jsRepresentationFromCode:@"bool: @" arguments:@[@YES] collectingProxiesOnScope:proxiesOnScope], @"one true");
    XCTAssertEqualObjects(@"bool: false", [TransitProxy jsRepresentationFromCode:@"bool: @" arguments:@[@NO] collectingProxiesOnScope:proxiesOnScope], @"one false");
    
    XCTAssertEqualObjects(@"string: \"foobar\"", [TransitProxy jsRepresentationFromCode:@"string: @" arguments:@[@"foobar"] collectingProxiesOnScope:proxiesOnScope], @"one string");
    
    XCTAssertEqualObjects(@"\"foo\" + \"bar\"", [TransitProxy jsRepresentationFromCode:@"@ + @" arguments:(@[@"foo", @"bar"]) collectingProxiesOnScope:proxiesOnScope], @"two strings");
    XCTAssertEqualObjects(@"'baz' + \"bam\" + 23", [TransitProxy jsRepresentationFromCode:@"'baz' + @ + @" arguments:(@[@"bam", @23]) collectingProxiesOnScope:proxiesOnScope], @"two strings");
    
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies needed for any of the above expressions");
}

-(void)testDoNotReplaceArgumentsTwice {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    NSString* replaced = [TransitProxy jsRepresentationFromCode:@"str: @" arguments:@[@"foo@bar"] collectingProxiesOnScope:proxiesOnScope];
    XCTAssertEqualObjects(@"str: \"foo@bar\"", replaced, @"first replacement");
    
    XCTAssertNoThrow([TransitProxy jsRepresentationFromCode:replaced arguments:@[] collectingProxiesOnScope:proxiesOnScope], @"does not try to replace a second time");
    
    XCTAssertThrows([TransitProxy jsRepresentationFromCode:replaced arguments:@[@"another argument"] collectingProxiesOnScope:proxiesOnScope], @"the @ in the string will not be recognized as placeholder. Hence, too many args");
    
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies needed for any of the above expressions");
}

-(void)testJSExpression {
    NSString* varName = transit_stringAsJSExpression(@"some.var");
    
    XCTAssertTrue(transit_isJSExpression(varName), @"marked as JS Expression");
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    XCTAssertEqualObjects(varName, [TransitProxy jsRepresentation:varName collectingProxiesOnScope:proxiesOnScope], @"js expression is its own jsRepresentation");
    
    varName = [@[varName] copy][0];
    XCTAssertTrue(transit_isJSExpression(varName), @"marked as JS Expression");
    XCTAssertEqualObjects(varName, [TransitProxy jsRepresentation:varName collectingProxiesOnScope:proxiesOnScope], @"js expression is its own jsRepresentation");
    
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies on scope");
}

-(void)testMarkAsJSExpressionHasNoSideEffect {
    NSString* s1 = @"someString";
    NSString* s2 = transit_stringAsJSExpression(s1);
    
    XCTAssertTrue(s1 != s2, @"not same identity");
    XCTAssertFalse(transit_isJSExpression(s1), @"s1 uneffected");
    XCTAssertTrue(transit_isJSExpression(s2), @"s2 correctly marked");
}

-(void)testJSExpressionWillNotBeUnderstoodAsString {
    NSString* realString = @"some.var";
    NSString* varName = transit_stringAsJSExpression(realString);
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    NSString* actual = [TransitProxy jsRepresentationFromCode:@"@ = @" arguments:@[varName, realString] collectingProxiesOnScope:proxiesOnScope];
    XCTAssertTrue(transit_isJSExpression(actual), @"marked as JS expression");
    XCTAssertEqualObjects(@"some.var = \"some.var\"", actual, @"replaced correctly");
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies on scope");
}

static BOOL boolYes = YES;
static BOOL boolNo = NO;

- (void)testJSExpressionFromObjectWithJsRepresentation {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    TransitProxy* proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[(id)proxy stub] andReturn:@"myRepresentation"] _jsRepresentationCollectingProxiesOnScope:proxiesOnScope];
    [[[(id)proxy stub] andReturnValue:OCMOCK_VALUE(boolNo)] isKindOfClass:NSString.class];
    [[[(id)proxy stub] andReturnValue:OCMOCK_VALUE(boolYes)] isKindOfClass:TransitProxy.class];
    XCTAssertEqualObjects([proxy _jsRepresentationCollectingProxiesOnScope:proxiesOnScope], @"myRepresentation", @"works");
    
    XCTAssertEqualObjects([TransitProxy jsRepresentationFromCode:@"return @" arguments:@[proxy] collectingProxiesOnScope:proxiesOnScope], @"return myRepresentation", @"static method uses instance jsRepresentation");
    
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"mock does not put itself onto set");
}

- (void)testJSExpressionWithInvalidArgumentCount {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;

    XCTAssertThrowsSpecificNamed([TransitProxy jsRepresentationFromCode:@"expect arg: @" arguments:@[] collectingProxiesOnScope:proxiesOnScope], NSException, NSInvalidArgumentException, @"too few arguments");
    XCTAssertThrowsSpecificNamed([TransitProxy jsRepresentationFromCode:@"expect nothing" arguments:@[@"some"] collectingProxiesOnScope:proxiesOnScope], NSException, NSInvalidArgumentException, @"too many arguments");
    
    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"well, proxies collected halfway though would appear here");
}

- (void)testJSExpressionWithInvalidArgumentType {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    XCTAssertThrowsSpecificNamed([TransitProxy jsRepresentationFromCode:@"obj: @" arguments:@[self] collectingProxiesOnScope:proxiesOnScope], NSException, NSInvalidArgumentException, @"cannot make JSON");

    XCTAssertEqualObjects(@[], proxiesOnScope.array, @"well, proxies collected halfway though would appear here");
}

-(void)testExplicitDispose {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context proxyId:@"someId"];
    
    // calls for the first time
    [[context expect] releaseJSProxyWithId:@"someId"];
    [proxy dispose];
    [context verify];
    
    // does not call a second time
    XCTAssertTrue(proxy.disposed, @"is disposed");
    [proxy dispose];
    [context verify];
}

-(void)createAndReleseProxyWithContext:(TransitContext*)context proxyId:(NSString*)proxyId{
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context proxyId:proxyId];
    proxy = nil;
}

-(void)testImplicitDisposeOnDealloc {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];

    [[context expect] releaseJSProxyWithId:@"fakeId"];
    [self createAndReleseProxyWithContext:context proxyId:@"fakeId"];
    [context verify];
}

-(void)testNoJSReleaseIfNoProxyId {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context];
    
    XCTAssertNil(proxy.proxyId, @"proxy without id");
    // does not call anything on context
    [proxy dispose];
    [context verify];
}

-(void)testJsRepresentationWithProxyId {
    id context = [CCWeakMockProxy niceMockForClass:TransitContext.class];
    
    NSString* proxyId = @"someProxyId";
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context proxyId:proxyId];
    
    [[[context stub] andReturn:@"fancyJsRepresentation"] jsRepresentationForProxyWithId:proxyId];
    NSMutableOrderedSet* set = NSMutableOrderedSet.orderedSet;
    NSString* actual = [proxy _jsRepresentationCollectingProxiesOnScope:set];
    XCTAssertEqualObjects(@[proxy], set.array, @"proxy on scope");
    XCTAssertEqualObjects(@"fancyJsRepresentation", actual, @"proxy representation from context");
    [context verify];
}

-(void)testHasNoJSRepresentationIfWithoutProxyAndValue {
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:nil];
    XCTAssertNil([proxy _jsRepresentationCollectingProxiesOnScope:nil], @"has no intrinsict representation");
}

-(void)testDelegatesJSRepesentationToValue {
    NSString*(^jsAndNoProxyOnScope)(TransitProxy*) = ^(TransitProxy* proxy) {
        NSMutableOrderedSet* set = NSMutableOrderedSet.orderedSet;
        NSString* result = [proxy _jsRepresentationCollectingProxiesOnScope:set];
        XCTAssertEqualObjects(@[], set.array, @"no proxies needed on scope");
        return result;
    };
    
    XCTAssertEqualObjects(@"42", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:@42]), @"int");
    
    XCTAssertEqualObjects(@"42.5", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:@42.5]), @"float");
    XCTAssertEqualObjects(@"true", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:@YES]), @"bool true");
    XCTAssertEqualObjects(@"false", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:@NO]), @"bool false");
    
    XCTAssertEqualObjects(@"\"foobar\"", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:@"foobar"]), @"string");
    
    XCTAssertEqualObjects(@"[1,2]", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:(@[@1, @2])]), @"array");
    XCTAssertEqualObjects(@"{\"a\":1}", jsAndNoProxyOnScope([[TransitProxy alloc] initWithContext:nil value:(@{@"a" : @1})]), @"dictionary");
}

-(void)testJsRepresentationOfArrayWithProxies {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"PROXY_REPRESENTATION" ] jsRepresentationForProxyWithId:@"someId"];
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context proxyId:@"someId"];
    
    id values = @[@"string", transit_stringAsJSExpression(@"expression"), proxy];

    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentation:values collectingProxiesOnScope:proxiesOnScope];
    
    XCTAssertEqualObjects(@"[\"string\",expression,PROXY_REPRESENTATION]", actual, @"calls jsRepresentation of elements in array");
    XCTAssertEqualObjects(@[proxy], proxiesOnScope.array, @"one proxy on scope");

    [proxy clearContextAndProxyId];
}

-(void)testJsRepresentationOfDictionaryWithProxies {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"PROXY_REPRESENTATION" ] jsRepresentationForProxyWithId:@"someId"];
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context proxyId:@"someId"];

    id values = @{@"a":@"string", @"b":transit_stringAsJSExpression(@"expression"), @"c":proxy};
    
    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentation:values collectingProxiesOnScope:proxiesOnScope];
    
    XCTAssertEqualObjects(@"{\"a\":\"string\",\"b\":expression,\"c\":PROXY_REPRESENTATION}", actual, @"calls jsRepresentation of elements in object");
    XCTAssertEqualObjects(@[proxy], proxiesOnScope.array, @"one proxy on scope");

    [proxy clearContextAndProxyId];
}

-(void)testJSRepresentationOfNestedDictionaryWithProxies {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"PROXY_REPRESENTATION" ] jsRepresentationForProxyWithId:@"someId"];
    TransitProxy *proxy = [[TransitProxy alloc] initWithContext:context proxyId:@"someId"];
    
    id values = @{@"a":@"string", @"b":@[transit_stringAsJSExpression(@"expression"), proxy], @"c":proxy};
    
    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentation:values collectingProxiesOnScope:proxiesOnScope];

    XCTAssertEqualObjects(@"{\"a\":\"string\",\"b\":[expression,PROXY_REPRESENTATION],\"c\":PROXY_REPRESENTATION}", actual, @"calls jsRepresentation of elements in nested object");
    XCTAssertEqualObjects(@[proxy], proxiesOnScope.array, @"one proxy on scope");

    [proxy clearContextAndProxyId];
}


@end
