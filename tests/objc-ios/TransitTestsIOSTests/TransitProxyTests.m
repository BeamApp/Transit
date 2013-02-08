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

- (void)testJSExpressionFromObjectWithJsRepresentation {
    TransitProxy* proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[(id)proxy stub] andReturn:@"myRepresentation"] jsRepresentation];
    STAssertEqualObjects(proxy.jsRepresentation, @"myRepresentation", @"works");
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
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context];
    
    // calls for the first time
    [[context expect] releaseProxy:proxy];
    [proxy dispose];
    [context verify];
    
    // does not call a second time
    STAssertTrue(proxy.disposed, @"is disposed");
    [proxy dispose];
    [context verify];
}

-(void)createAndReleseProxyWithContext:(TransitContext*)context {
    TransitProxy *proxy = [[TransitProxy alloc] initWithRootContext:context];
    proxy = nil;
}

-(void)testImplicitDisposeOnDealloc {
    id context = [OCMockObject mockForClass:TransitContext.class];

    [[context expect] releaseProxy:OCMOCK_ANY];
    [self createAndReleseProxyWithContext:context];
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

@end
