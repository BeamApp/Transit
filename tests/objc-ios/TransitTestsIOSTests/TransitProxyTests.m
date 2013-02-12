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

@interface TransitProxyTests : SenTestCase

@end

@implementation TransitProxyTests

-(void)testJSRepresentationForNSError {
    NSError *error = [NSError errorWithDomain:@"transit" code:1 userInfo:@{NSLocalizedDescriptionKey:@"some description"}];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsExpressionFromCode:@"@" arguments:@[error] collectingProxiesOnScope:proxiesOnScope];
    STAssertEqualObjects(@"new Error(\"some description\")", actual, @"error");
    STAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies needed");
}

- (void)testJSExpressionFromCodeAndArguments {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;

    STAssertEqualObjects(@"no arguments", [TransitProxy jsExpressionFromCode:@"no arguments" arguments:@[] collectingProxiesOnScope:proxiesOnScope], @"no arguments");
    
    STAssertEqualObjects(@"int: 23", [TransitProxy jsExpressionFromCode:@"int: @" arguments:@[@23] collectingProxiesOnScope:proxiesOnScope], @"one int");
    STAssertEqualObjects(@"float: 42.5", [TransitProxy jsExpressionFromCode:@"float: @" arguments:@[@42.5] collectingProxiesOnScope:proxiesOnScope], @"one float");
    STAssertEqualObjects(@"bool: true", [TransitProxy jsExpressionFromCode:@"bool: @" arguments:@[@YES] collectingProxiesOnScope:proxiesOnScope], @"one true");
    STAssertEqualObjects(@"bool: false", [TransitProxy jsExpressionFromCode:@"bool: @" arguments:@[@NO] collectingProxiesOnScope:proxiesOnScope], @"one false");
    
    STAssertEqualObjects(@"string: \"foobar\"", [TransitProxy jsExpressionFromCode:@"string: @" arguments:@[@"foobar"] collectingProxiesOnScope:proxiesOnScope], @"one string");
    
    STAssertEqualObjects(@"\"foo\" + \"bar\"", [TransitProxy jsExpressionFromCode:@"@ + @" arguments:(@[@"foo", @"bar"]) collectingProxiesOnScope:proxiesOnScope], @"two strings");
    STAssertEqualObjects(@"'baz' + \"bam\" + 23", [TransitProxy jsExpressionFromCode:@"'baz' + @ + @" arguments:(@[@"bam", @23]) collectingProxiesOnScope:proxiesOnScope], @"two strings");
    
    STAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies needed for any of the above expressions");
}

-(void)testDoNotReplaceArgumentsTwice {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    NSString* replaced = [TransitContext jsExpressionFromCode:@"str: @" arguments:@[@"foo@bar"] collectingProxiesOnScope:proxiesOnScope];
    STAssertEqualObjects(@"str: \"foo@bar\"", replaced, @"first replacement");
    
    STAssertNoThrow([TransitContext jsExpressionFromCode:replaced arguments:@[] collectingProxiesOnScope:proxiesOnScope], @"does not try to replace a second time");
    
    STAssertThrows([TransitContext jsExpressionFromCode:replaced arguments:@[@"another argument"] collectingProxiesOnScope:proxiesOnScope], @"the @ in the string will not be recognized as placeholder. Hence, too many args");
    
    STAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies needed for any of the above expressions");
}

-(void)testJSExpression {
    NSString* varName = @"some.var".stringAsJSExpression;
    
    STAssertTrue(varName.isJSExpression, @"marked as JS Expression");
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    STAssertEqualObjects(varName, [TransitProxy jsRepresentation:varName collectingProxiesOnScope:proxiesOnScope], @"js expression is its own jsRepresentation");
    
    varName = [@[varName] copy][0];
    STAssertTrue(varName.isJSExpression, @"marked as JS Expression");
    STAssertEqualObjects(varName, [TransitProxy jsRepresentation:varName collectingProxiesOnScope:proxiesOnScope], @"js expression is its own jsRepresentation");
    
    STAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies on scope");
}

-(void)testMarkAsJSExpressionHasNoSideEffect {
    NSString* s1 = @"someString";
    NSString* s2 = s1.stringAsJSExpression;
    
    STAssertTrue(s1 != s2, @"not same identity");
    STAssertFalse(s1.isJSExpression, @"s1 uneffected");
    STAssertTrue(s2.isJSExpression, @"s2 correctly marked");
}

-(void)testJSExpressionWillNotBeUnderstoodAsString {
    NSString* realString = @"some.var";
    NSString* varName = realString.stringAsJSExpression;
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    NSString* actual = [TransitProxy jsExpressionFromCode:@"@ = @" arguments:@[varName, realString] collectingProxiesOnScope:proxiesOnScope];
    STAssertTrue(actual.isJSExpression, @"marked as JS expression");
    STAssertEqualObjects(@"some.var = \"some.var\"", actual, @"replaced correctly");
    STAssertEqualObjects(@[], proxiesOnScope.array, @"no proxies on scope");
}

- (void)testJSExpressionFromObjectWithJsRepresentation {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    TransitProxy* proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[(id)proxy stub] andReturn:@"myRepresentation"] _jsRepresentationCollectingProxiesOnScope:proxiesOnScope];
    [[[(id)proxy stub] andReturnValue:@NO] isKindOfClass:NSString.class];
    [[[(id)proxy stub] andReturnValue:@YES] isKindOfClass:TransitProxy.class];
    STAssertEqualObjects([proxy _jsRepresentationCollectingProxiesOnScope:proxiesOnScope], @"myRepresentation", @"works");
    
    STAssertEqualObjects([TransitProxy jsExpressionFromCode:@"return @" arguments:@[proxy] collectingProxiesOnScope:proxiesOnScope], @"return myRepresentation", @"static method uses instance jsRepresentation");
    
    STAssertEqualObjects(@[], proxiesOnScope.array, @"mock does not put itself onto set");
}

- (void)testJSExpressionWithInvalidArgumentCount {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;

    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"expect arg: @" arguments:@[] collectingProxiesOnScope:proxiesOnScope], NSException, NSInvalidArgumentException, @"too few arguments");
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"expect nothing" arguments:@[@"some"] collectingProxiesOnScope:proxiesOnScope], NSException, NSInvalidArgumentException, @"too many arguments");
    
    STAssertEqualObjects(@[], proxiesOnScope.array, @"well, proxies collected halfway though would appear here");
}

- (void)testJSExpressionWithInvalidArgumentType {
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"obj: @" arguments:@[self] collectingProxiesOnScope:proxiesOnScope], NSException, NSInvalidArgumentException, @"cannot make JSON");

    STAssertEqualObjects(@[], proxiesOnScope.array, @"well, proxies collected halfway though would appear here");
}

-(void)testExplicitDispose {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:@"someId"];
    
    // calls for the first time
    [[context expect] releaseJSProxyWithId:@"someId"];
    [proxy dispose];
    [context verify];
    
    // does not call a second time
    STAssertTrue(proxy.disposed, @"is disposed");
    [proxy dispose];
    [context verify];
}

-(void)createAndReleseProxyWithContext:(TransitContext*)context proxyId:(NSString*)proxyId{
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:proxyId];
    proxy = nil;
}

-(void)testImplicitDisposeOnDealloc {
    id context = [OCMockObject mockForClass:TransitContext.class];

    [[context expect] releaseJSProxyWithId:@"fakeId"];
    [self createAndReleseProxyWithContext:context proxyId:@"fakeId"];
    [context verify];
}

-(void)testNoJSReleaseIfNoProxyId {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context];
    
    STAssertNil(proxy.proxyId, @"proxy without id");
    // does not call anything on context
    [proxy dispose];
    [context verify];
}

-(void)testJsRepresentationWithProxyId {
    id context = [OCMockObject niceMockForClass:TransitContext.class];
    
    NSString* proxyId = @"someProxyId";
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:proxyId];
    
    [[[context stub] andReturn:@"fancyJsRepresentation"] jsRepresentationForProxyWithId:proxyId];
    NSMutableOrderedSet* set = NSMutableOrderedSet.orderedSet;
    NSString* actual = [proxy _jsRepresentationCollectingProxiesOnScope:set];
    STAssertEqualObjects(@[proxy], set.array, @"proxy on scope");
    STAssertEqualObjects(@"fancyJsRepresentation", actual, @"proxy representation from context");
    [context verify];
}

-(void)testDelegatesEvalToRootContext {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:@"someId"];
    
    [[[context stub] andReturn:@"4"] eval:@"2+2" thisArg:proxy arguments:@[] returnJSResult:YES];
    NSString* actual = [proxy eval:@"2+2"];
    STAssertEqualObjects(@"4", actual, @"passed through");
    [context verify];
}

-(void)testHasNoJSRepresentationIfWithoutProxyAndValue {
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:nil];
    STAssertNil([proxy _jsRepresentationCollectingProxiesOnScope:nil], @"has no intrinsict representation");
}

-(void)testDelegatesJSRepesentationToValue {
    NSString*(^jsAndNoProxyOnScope)(TransitProxy*) = ^(TransitProxy* proxy) {
        NSMutableOrderedSet* set = NSMutableOrderedSet.orderedSet;
        NSString* result = [proxy _jsRepresentationCollectingProxiesOnScope:set];
        STAssertEqualObjects(@[], set.array, @"no proxies needed on scope");
        return result;
    };
    
    STAssertEqualObjects(@"42", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:@42]), @"int");
    
    STAssertEqualObjects(@"42.5", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:@42.5]), @"float");
    STAssertEqualObjects(@"true", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:@YES]), @"bool true");
    STAssertEqualObjects(@"false", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:@NO]), @"bool false");
    
    STAssertEqualObjects(@"\"foobar\"", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:@"foobar"]), @"string");
    
    STAssertEqualObjects(@"[1,2]", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:(@[@1, @2])]), @"array");
    STAssertEqualObjects(@"{\"a\":1}", jsAndNoProxyOnScope([[TransitProxy alloc] initWithRootContext:nil value:(@{@"a": @1})]), @"dictionary");
}

-(void)testJsRepresentationOfArrayWithProxies {
    id context = [OCMockObject mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"PROXY_REPRESENTATION" ] jsRepresentationForProxyWithId:@"someId"];
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:@"someId"];
    
    id values = @[@"string", @"expression".stringAsJSExpression, proxy];

    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentation:values collectingProxiesOnScope:proxiesOnScope];
    
    STAssertEqualObjects(@"[\"string\",expression,PROXY_REPRESENTATION]", actual, @"calls jsRepresentation of elements in array");
    STAssertEqualObjects(@[proxy], proxiesOnScope.array, @"one proxy on scope");
    
    [proxy clearRootContextAndProxyId];
}

-(void)testJsRepresentationOfDictionaryWithProxies {
    id context = [OCMockObject mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"PROXY_REPRESENTATION" ] jsRepresentationForProxyWithId:@"someId"];
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:@"someId"];

    id values = @{@"a":@"string", @"b":@"expression".stringAsJSExpression, @"c":proxy};
    
    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentation:values collectingProxiesOnScope:proxiesOnScope];
    
    STAssertEqualObjects(@"{\"a\":\"string\",\"b\":expression,\"c\":PROXY_REPRESENTATION}", actual, @"calls jsRepresentation of elements in object");
    STAssertEqualObjects(@[proxy], proxiesOnScope.array, @"one proxy on scope");
    
    [proxy clearRootContextAndProxyId];
}

-(void)testJSRepresentationOfNestedDictionaryWithProxies {
    id context = [OCMockObject mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"PROXY_REPRESENTATION" ] jsRepresentationForProxyWithId:@"someId"];
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context proxyId:@"someId"];
    
    id values = @{@"a":@"string", @"b":@[@"expression".stringAsJSExpression, proxy], @"c":proxy};
    
    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;
    id actual = [TransitProxy jsRepresentation:values collectingProxiesOnScope:proxiesOnScope];

    STAssertEqualObjects(@"{\"a\":\"string\",\"b\":[expression,PROXY_REPRESENTATION],\"c\":PROXY_REPRESENTATION}", actual, @"calls jsRepresentation of elements in nested object");
    STAssertEqualObjects(@[proxy], proxiesOnScope.array, @"one proxy on scope");

    [proxy clearRootContextAndProxyId];
}


@end
