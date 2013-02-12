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
//    [[[context stub] andReturn:@"someResult"] eval:@"someJSRepresentation()" thisArg:nil arguments:nil returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:nil arguments:@[func, @[]] returnJSResult:YES];
    
    id actual = [func call];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");

    [[context expect] releaseJSProxyWithId:func.proxyId];
    [func dispose];
    
    [context verify];
}

-(void)testCallWithoutArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
//    [[context expect] eval:@"func()" thisArg:nil arguments:nil returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:nil arguments:@[func, @[]] returnJSResult:YES];
    
    [func call];
    [context verify];
}

-(void)testCallWithEmptyArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
//    [[context expect] eval:@"func()" thisArg:nil arguments:nil returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:nil arguments:@[func, @[]] returnJSResult:YES];
    
    [func callWithArguments:@[]];
    [context verify];
}

-(void)testShortcutCallWithNilArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
//    [[context expect] eval:@"func()" thisArg:nil arguments:nil returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:nil arguments:@[func, @[]] returnJSResult:YES];
    
    [func callWithArguments:nil];
    [context verify];
}

-(void)testCallWithOneArgument {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
//    [[context expect] eval:@"func(1)" thisArg:nil arguments:nil returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:nil arguments:@[func, @[@1]] returnJSResult:YES];
    
    [func callWithArguments:@[@1]];
    [context verify];
}

-(void)testShortcutCallWithTwoArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
//    [[context expect] eval:@"func(1,2)" thisArg:nil arguments:nil returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:nil arguments:@[func, @[@1, @2]] returnJSResult:YES];
    
    [func callWithArguments:@[@1, @2]];
    [context verify];
}

-(void)_testShortcutCallWithTwoArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"func"];
    
    [[context expect] eval:@"func.apply(this, [1,2])" thisArg:nil arguments:@[] returnJSResult:YES];
    
    [func callWithArguments:@[@1, @2]];
    [context verify];
}


-(void)testCallWithThisAndArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    
    id thisArg = @{@"one":@1};
    id arguments = @[@1,@"two", @YES];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context jsRepresentation:@"someJSRepresentation"];
//    [[[context stub] andReturn:@"someResult"] eval:@"someJSRepresentation.apply(this, [1,\"two\",true])" thisArg:@{@"one":@1} arguments:@[] returnJSResult:YES];
    [[[context stub] andReturn:@"someResult"] eval:@"@.apply(this,@)" thisArg:thisArg arguments:@[func, arguments] returnJSResult:YES];
    
    id actual = [func callWithThisArg:thisArg arguments:arguments];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");
    
    [context verify];
}


@end
