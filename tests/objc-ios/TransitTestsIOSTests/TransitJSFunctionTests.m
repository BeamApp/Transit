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

-(void)testCallWithoutArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context proxyId:@"proxyId"];
    [[[context stub] andReturn:@"someJSRepresentation"] jsRepresentationForProxyWithId:@"proxyId"];
    [[[context stub] andReturn:@"someResult"] eval:@"someJSRepresentation()" thisArg:nil arguments:nil returnJSResult:YES];

    id actual = [func call];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");

    [[context expect] releaseJSProxyWithId:func.proxyId];
    [func dispose];
    
    [context verify];
}

-(void)testCallWithThisAndArguments {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitJSFunction alloc] initWithRootContext:context proxyId:@"proxyId"];
    [[[context stub] andReturn:@"someJSRepresentation"] jsRepresentationForProxyWithId:@"proxyId"];
    [[[context stub] andReturn:@"someResult"] eval:@"someJSRepresentation(@,@,@)" thisArg:@{@"one":@1} arguments:@[@1,@"two",@YES] returnJSResult:YES];
    
    id actual = [func callWithThisArg:@{@"one":@1} arguments:@[@1,@"two", @YES]];
    STAssertEqualObjects(@"someResult", actual, @"result passed along");
    
    [[context expect] releaseJSProxyWithId:func.proxyId];
    [func dispose];
    
    [context verify];
}


@end
