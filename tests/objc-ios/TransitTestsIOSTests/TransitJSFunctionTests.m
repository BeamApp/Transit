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
#import "OCMockObject+Reset.h"

@interface TransitJSFunctionTests : SenTestCase

@end


@implementation TransitJSFunctionTests

-(void)testCallRetainedWithoutArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithContext:context proxyId:@"proxyId"];
    [[[context stub] andReturn:@"someJSRepresentation"] jsRepresentationForProxyWithId:@"proxyId"];

    [[[context stub] andReturn:@"someResult"] _eval:@"someJSRepresentation()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSetWithObject:func] returnJSResult:YES];
    
    id actual = [func call];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");

    [[context expect] releaseJSProxyWithId:func.proxyId];
    [func dispose];
    
    
    [context verify];
}

-(void)testCallWithoutArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func call];
    [context verify];
}

-(void)testCallWithEmptyArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:@[]];
    [context verify];
}

-(void)testShortcutCallWithNilArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:nil];
    [context verify];
}

-(void)testCallWithOneArgument {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func(1)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:@[@1]];
    [context verify];
}

-(void)testShortcutCallWithTwoArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func(1,2)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES];
    
    [func callWithArguments:@[@1, @2]];
    [context verify];
}

-(void)testShortcutCallWithRetainedArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];
    TransitProxy* p1 = [[TransitProxy alloc] initWithContext:context proxyId:@"p1"];
    TransitProxy* p2 = [[TransitProxy alloc] initWithContext:context proxyId:@"p2"];
    
    [[[context stub] andReturn:@"__p1"] jsRepresentationForProxyWithId:@"p1"];
    [[[context stub] andReturn:@"__p2"] jsRepresentationForProxyWithId:@"p2"];
    [[context expect] _eval:@"func(__p1,__p2)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSetWithArray:@[p1, p2]] returnJSResult:YES];
    
    [func callWithArguments:@[p1, p2]];
    [context verify];

    [p1 clearContextAndProxyId];
    [p2 clearContextAndProxyId];
}


-(void)testCallWithThisAndArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    
    id thisArg = @{@"one":@1};
    id arguments = @[@1,@"two", @YES];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"someJSRepresentation"];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(@,@)" thisArg:nil values:@[func, thisArg, arguments] returnJSResult:YES];
    
    id actual = [func callWithThisArg:thisArg arguments:arguments];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");
    
    [context verify];
}

-(void)testQueuedCallWithTwoArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"transit.r('proxyId')"] jsRepresentationToResolveProxyWithId:@"proxyId"];
    [[[context stub] andReturn:@"__JSFUNC_proxyId"] jsRepresentationForProxyWithId:@"proxyId"];
    
    TransitJSFunction *func = [[TransitJSFunction alloc] initWithContext:context proxyId:@"proxyId"];
    
    TransitQueuedCallToJSFunction *queuedCall = [TransitQueuedCallToJSFunction.alloc initWithJSFunction:func thisArg:nil arguments:@[@1, @2]];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    NSString* js = [queuedCall jsRepresentationOfCallCollectingProxiesOnScope:proxiesOnScope];
    
    STAssertEqualObjects(@"__JSFUNC_proxyId(1,2);", js, @"js");
    STAssertEqualObjects(@[func], proxiesOnScope.array, @"proxies");
    STAssertNoThrow([context verify], @"verify mock");

    [func clearContextAndProxyId];
}

-(void)testQueuedCallWithThisAndArgument {
    id context = [OCMockObject mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"transit.r('proxyId')"] jsRepresentationToResolveProxyWithId:@"proxyId"];
    [[[context stub] andReturn:@"__JSFUNC_proxyId"] jsRepresentationForProxyWithId:@"proxyId"];
    
    TransitJSFunction *func = [[TransitJSFunction alloc] initWithContext:context proxyId:@"proxyId"];
    
    TransitQueuedCallToJSFunction *queuedCall = [TransitQueuedCallToJSFunction.alloc initWithJSFunction:func thisArg:@"someObj".stringAsJSExpression arguments:@[@1]];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    NSString* js = [queuedCall jsRepresentationOfCallCollectingProxiesOnScope:proxiesOnScope];
    
    STAssertEqualObjects(@"__JSFUNC_proxyId.apply(someObj,[1]);", js, @"js");
    STAssertEqualObjects(@[func], proxiesOnScope.array, @"proxies");
    STAssertNoThrow([context verify], @"verify mock");

    [func clearContextAndProxyId];
}




@end
