//
//  TransitFunctionTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

@interface TransitJSFunctionTests : XCTestCase

@end


@implementation TransitJSFunctionTests

-(void)testCallRetainedWithoutArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithContext:context proxyId:@"proxyId"];
    [[[context stub] andReturn:@"someJSRepresentation"] jsRepresentationForProxyWithId:@"proxyId"];

    [[[context stub] andReturn:@"someResult"] _eval:@"someJSRepresentation()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSetWithObject:func] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    [[context stub] currentCallScope];

    id actual = [func call];
    XCTAssertEqualObjects(@"someResult", actual, @"result passed along");

    [[context expect] releaseJSProxyWithId:func.proxyId];
    [func dispose];
    
    
    [context verify];
}

-(void)testCallWithoutArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    [[context stub] currentCallScope];

    [func call];
    [context verify];
}

-(void)testCallWithEmptyArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    [[context stub] currentCallScope];

    [func callWithArguments:@[]];
    [context verify];
}

-(void)testShortcutCallWithNilArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func()" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    [[context stub] currentCallScope];

    [func callWithArguments:nil];
    [context verify];
}

-(void)testCallWithOneArgument {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] _eval:@"func(1)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    [[context stub] currentCallScope];

    [func callWithArguments:@[@1]];
    [context verify];
}

-(void)testShortcutCallWithTwoArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];

    [[context expect] currentCallScope];
    [[context expect] _eval:@"func(1,2)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSet] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    
    [func callWithArguments:@[@1, @2]];
    [context verify];
}

-(void)testShortcutCallWithRetainedArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"func"];
    TransitProxy* p1 = [[TransitProxy alloc] initWithContext:context proxyId:@"p1"];
    TransitProxy* p2 = [[TransitProxy alloc] initWithContext:context proxyId:@"p2"];
    
    [[[context stub] andReturn:@"__p1"] jsRepresentationForProxyWithId:@"p1"];
    [[[context stub] andReturn:@"__p2"] jsRepresentationForProxyWithId:@"p2"];
    [[context expect] currentCallScope];
    [[context expect] _eval:@"func(__p1,__p2)" jsThisArg:@"null" collectedProxiesOnScope:[NSMutableOrderedSet orderedSetWithArray:@[p1, p2]] returnJSResult:YES onGlobalScope:NO useAndRestoreCallScope:OCMOCK_ANY];
    
    [func callWithArguments:@[p1, p2]];
    [context verify];

    [p1 clearContextAndProxyId];
    [p2 clearContextAndProxyId];
}


-(void)testCallWithThisAndArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    
    id thisArg = @{@"one":@1};
    id arguments = @[@1,@"two", @YES];
    TransitFunction *func = [[TransitJSFunction alloc] initWitContext:context jsRepresentation:@"someJSRepresentation"];
    [[context expect] currentCallScope];
    [[[context stub] andReturn:@"someResult"] _eval:@"@.apply(@,@)" thisArg:nil values:@[func, thisArg, arguments] returnJSResult:YES useAndRestoreCallScope:OCMOCK_ANY];
    
    id actual = [func callWithThisArg:thisArg arguments:arguments];
    XCTAssertEqualObjects(@"someResult", actual, @"result passed along");
    
    [context verify];
}

-(void)testQueuedCallWithTwoArguments {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"transit.r('proxyId')"] jsRepresentationToResolveProxyWithId:@"proxyId"];
    [[[context stub] andReturn:@"__JSFUNC_proxyId"] jsRepresentationForProxyWithId:@"proxyId"];
    
    TransitJSFunction *func = [[TransitJSFunction alloc] initWithContext:context proxyId:@"proxyId"];
    
    TransitQueuedCallToJSFunction *queuedCall = [TransitQueuedCallToJSFunction.alloc initWithJSFunction:func thisArg:nil arguments:@[@1, @2]];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    NSString* js = [queuedCall jsRepresentationOfCallCollectingProxiesOnScope:proxiesOnScope];
    
    XCTAssertEqualObjects(@"__JSFUNC_proxyId(1,2);", js, @"js");
    XCTAssertEqualObjects(@[func], proxiesOnScope.array, @"proxies");
    XCTAssertNoThrow([context verify], @"verify mock");

    [func clearContextAndProxyId];
}

-(void)testQueuedCallWithThisAndArgument {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    [[[context stub] andReturn:@"transit.r('proxyId')"] jsRepresentationToResolveProxyWithId:@"proxyId"];
    [[[context stub] andReturn:@"__JSFUNC_proxyId"] jsRepresentationForProxyWithId:@"proxyId"];
    
    TransitJSFunction *func = [[TransitJSFunction alloc] initWithContext:context proxyId:@"proxyId"];
    
    TransitQueuedCallToJSFunction *queuedCall = [TransitQueuedCallToJSFunction.alloc initWithJSFunction:func thisArg:transit_stringAsJSExpression(@"someObj") arguments:@[@1]];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    NSString* js = [queuedCall jsRepresentationOfCallCollectingProxiesOnScope:proxiesOnScope];
    
    XCTAssertEqualObjects(@"__JSFUNC_proxyId.apply(someObj,[1]);", js, @"js");
    XCTAssertEqualObjects(@[func], proxiesOnScope.array, @"proxies");
    XCTAssertNoThrow([context verify], @"verify mock");

    [func clearContextAndProxyId];
}




@end
