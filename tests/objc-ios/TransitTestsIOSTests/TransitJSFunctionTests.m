//
//  TransitFunctionTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Transit.h"
#import "Transit+Private.h"
#import "OCMock.h"

@interface TransitJSFunctionTests : SenTestCase

@end


@implementation TransitJSFunctionTests

-(void)testCallRetainedWithoutArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context proxyId:@"proxyId"];
    [[[context stub] andReturn:@"someJSRepresentation"] jsRepresentationForProxyWithId:@"proxyId"];

    [[[context stub] andReturn:@"someResult"] _evalJsExpression:@"someJSRepresentation()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSetWithObject:func] returnJSResult:YES];
    
    id actual = [func call];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");

    [[context expect] releaseJSProxyWithId:func.proxyId];
    [func dispose];
    
    
    [context verify];
}

-(void)testCallWithoutArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
    [[context expect] _evalJsExpression:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func call];
    [context verify];
}

-(void)testCallWithEmptyArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
    [[context expect] _evalJsExpression:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:@[]];
    [context verify];
}

-(void)testShortcutCallWithNilArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
    [[context expect] _evalJsExpression:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:nil];
    [context verify];
}

-(void)testCallWithOneArgument {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
    [[context expect] _evalJsExpression:@"func(1)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:@[@1]];
    [context verify];
}

-(void)testShortcutCallWithTwoArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
    [[context expect] _evalJsExpression:@"func(1,2)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:@[@1, @2]];
    [context verify];
}

-(void)testShortcutCallWithRetainedArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    TransitProxy* p1 = [[TransitProxy alloc] initWithRootContext:context proxyId:@"p1"];
    TransitProxy* p2 = [[TransitProxy alloc] initWithRootContext:context proxyId:@"p2"];
    
    [[[context stub] andReturn:@"__p1"] jsRepresentationForProxyWithId:@"p1"];
    [[[context stub] andReturn:@"__p2"] jsRepresentationForProxyWithId:@"p2"];
    [[context expect] _evalJsExpression:@"func(__p1,__p2)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSetWithArray:@[p1, p2]] returnJSResult:YES];
    
    [func callWithArguments:@[p1, p2]];
    [context verify];
    
    [p1 clearRootContextAndProxyId];
    [p2 clearRootContextAndProxyId];
}


-(void)testCallWithThisAndArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    
    id thisArg = @{@"one":@1};
    id arguments = @[@1,@"two", @YES];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"someJSRepresentation"];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:thisArg arguments:@[func, arguments] returnJSResult:YES];
    
    id actual = [func callWithThisArg:thisArg arguments:arguments];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");
    
    [context verify];
}


@end
