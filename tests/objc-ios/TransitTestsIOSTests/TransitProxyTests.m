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
    id actual = [TransitProxy jsExpressionFromCode:@"@" arguments:@[error]];
    STAssertEqualObjects(@"new Error(\"some description\")", actual, @"error");
}

- (void)testJSExpressionFromCodeAndArguments {
    STAssertEqualObjects(@"no arguments", [TransitProxy jsExpressionFromCode:@"no arguments" arguments:@[]], @"no arguments");
    
    STAssertEqualObjects(@"int: 23", [TransitProxy jsExpressionFromCode:@"int: @" arguments:@[@23]], @"one int");
    STAssertEqualObjects(@"float: 42.5", [TransitProxy jsExpressionFromCode:@"float: @" arguments:@[@42.5]], @"one float");
    STAssertEqualObjects(@"bool: true", [TransitProxy jsExpressionFromCode:@"bool: @" arguments:@[@YES]], @"one true");
    STAssertEqualObjects(@"bool: false", [TransitProxy jsExpressionFromCode:@"bool: @" arguments:@[@NO]], @"one false");
    
    STAssertEqualObjects(@"string: \"foobar\"", [TransitProxy jsExpressionFromCode:@"string: @" arguments:@[@"foobar"]], @"one string");
    
    STAssertEqualObjects(@"\"foo\" + \"bar\"", [TransitProxy jsExpressionFromCode:@"@ + @" arguments:(@[@"foo", @"bar"])], @"two strings");
    STAssertEqualObjects(@"'baz' + \"bam\" + 23", [TransitProxy jsExpressionFromCode:@"'baz' + @ + @" arguments:(@[@"bam", @23])], @"two strings");
}

-(void)testDoNotReplaceArgumentsTwice {
    NSString* replaced = [TransitContext jsExpressionFromCode:@"str: @" arguments:@[@"foo@bar"]];
    STAssertEqualObjects(@"str: \"foo@bar\"", replaced, @"first replacement");
    
    STAssertNoThrow([TransitContext jsExpressionFromCode:replaced arguments:@[]], @"does not try to replace a second time");
    
    STAssertThrows([TransitContext jsExpressionFromCode:replaced arguments:@[@"another argument"]], @"the @ in the string will not be recognized as placeholder. Hence, too many args");
}

-(void)testJSExpression {
    NSString* varName = @"some.var".stringAsJSExpression;
    
    STAssertTrue(varName.isJSExpression, @"marked as JS Expression");
    STAssertEqualObjects(varName, [TransitProxy jsRepresentation:varName], @"js expression is its own jsRepresentation");
    
    varName = [@[varName] copy][0];
    STAssertTrue(varName.isJSExpression, @"marked as JS Expression");
    STAssertEqualObjects(varName, [TransitProxy jsRepresentation:varName], @"js expression is its own jsRepresentation");
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
    
    NSString* actual = [TransitProxy jsExpressionFromCode:@"@ = @" arguments:@[varName, realString]];
    STAssertTrue(actual.isJSExpression, @"marked as JS expression");
    STAssertEqualObjects(@"some.var = \"some.var\"", actual, @"replaced correctly");
}

- (void)testJSExpressionFromObjectWithJsRepresentation {
    TransitProxy* proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[(id)proxy stub] andReturn:@"myRepresentation"] _jsRepresentation];
    [[[(id)proxy stub] andReturnValue:@NO] isKindOfClass:NSString.class];
    [[[(id)proxy stub] andReturnValue:@YES] isKindOfClass:TransitProxy.class];
    STAssertEqualObjects(proxy._jsRepresentation, @"myRepresentation", @"works");
    
    STAssertEqualObjects([TransitProxy jsExpressionFromCode:@"return @" arguments:@[proxy]], @"return myRepresentation", @"static method uses instance jsRepresentation");
}

- (void)testJSExpressionWithInvalidArgumentCount {
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"expect arg: @" arguments:@[]], NSException, NSInvalidArgumentException, @"too few arguments");
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"expect nothing" arguments:@[@"some"]], NSException, NSInvalidArgumentException, @"too many arguments");
}

- (void)testJSExpressionWithInvalidArgumentType {
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"obj: @" arguments:@[self]], NSException, NSInvalidArgumentException, @"cannot make JSON");
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
    NSString* actual = proxy.jsRepresentation;
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
    STAssertThrows([proxy jsRepresentation], @"has no intrinsict representation");
}

-(void)testDelegatesJSRepesentationToValue {
    STAssertEqualObjects(@"42", [[[TransitProxy alloc] initWithRootContext:nil value:@42] jsRepresentation], @"int");
    
    STAssertEqualObjects(@"42.5", [[[TransitProxy alloc] initWithRootContext:nil value:@42.5] jsRepresentation], @"float");
    STAssertEqualObjects(@"true", [[[TransitProxy alloc] initWithRootContext:nil value:@YES] jsRepresentation], @"bool true");
    STAssertEqualObjects(@"false", [[[TransitProxy alloc] initWithRootContext:nil value:@NO] jsRepresentation], @"bool false");
    
    STAssertEqualObjects(@"\"foobar\"", [[[TransitProxy alloc] initWithRootContext:nil value:@"foobar"] jsRepresentation], @"string");
    
    STAssertEqualObjects(@"[1,2]", [[[TransitProxy alloc] initWithRootContext:nil value:(@[@1, @2])] jsRepresentation], @"array");
    STAssertEqualObjects(@"{\"a\":1}", [[[TransitProxy alloc] initWithRootContext:nil value:(@{@"a": @1})] jsRepresentation], @"dictionary");
}

-(void)testJsRepresentationOfArrayWithProxies {
    id values = @[@"string", @"expression".stringAsJSExpression];
    
    id actual = [TransitProxy jsRepresentation:values];
    STAssertEqualObjects(@"[\"string\",expression]", actual, @"calls jsRepresentation of elements in array");
}

-(void)testJsRepresentationOfDictionaryWithProxies {
    id values = @{@"a":@"string", @"b":@"expression".stringAsJSExpression};
    
    id actual = [TransitProxy jsRepresentation:values];
    STAssertEqualObjects(@"{\"a\":\"string\",\"b\":expression}", actual, @"calls jsRepresentation of elements in object");
}

-(void)testJSRepresentationOfNestedDictionaryWithProxies {
    id values = @{@"a":@"string", @"b":@[@"expression".stringAsJSExpression]};
    
    id actual = [TransitProxy jsRepresentation:values];
    STAssertEqualObjects(@"{\"a\":\"string\",\"b\":[expression]}", actual, @"calls jsRepresentation of elements in nested object");
    
}


@end
