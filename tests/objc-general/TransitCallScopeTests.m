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
#import "CCWeakMockProxy.h"

@interface TransitCallScopeTests : SenTestCase

@end

@implementation TransitCallScopeTests

-(void)testFunctionCallScope {
    TransitContext *context = [CCWeakMockProxy mockForClass:TransitContext .class];
    TransitNativeFunction *function = [CCWeakMockProxy mockForClass:TransitNativeFunction.class];
    id thisArg = @"thisValue";
    NSArray *arguments = @[@1, @2, @3];
    TransitCallScope *parentScope = [TransitCallScope.alloc initWithContext:context];
    TransitFunctionCallScope *scope = [TransitFunctionCallScope.alloc initWithContext:context parentScope:parentScope thisArg:thisArg arguments:arguments expectsResult:NO function:function];

    STAssertEquals(context, scope.context, @"context prop");
    STAssertEquals(parentScope, scope.parentScope, @"parentScope");
    STAssertEquals(function, scope.function, @"function");
    STAssertEquals(thisArg, scope.thisArg, @"thisArg");
    STAssertEquals(arguments, scope.arguments, @"arguments");
}

-(void)testForwardToFunction {
    TransitContext *context = [CCWeakMockProxy mockForClass:TransitContext .class];
    TransitNativeFunction *function = [CCWeakMockProxy mockForClass:TransitNativeFunction.class];
    id function2 = [CCWeakMockProxy mockForClass:TransitFunction.class];
    id thisArg = @"thisValue";
    NSArray *arguments = @[@1, @2, @3];
    BOOL expectsResult = YES;
    TransitFunctionCallScope *scope = [TransitFunctionCallScope.alloc initWithContext:context parentScope:nil thisArg:thisArg arguments:arguments expectsResult:expectsResult function:function];

    [[[function2 stub] andReturn:@"someResult"] callWithThisArg:thisArg arguments:arguments returnResult:expectsResult];
    id actual = [scope forwardToFunction:function2];
    STAssertEqualObjects(@"someResult", actual, @"result from forwarded delegate");
}

-(void)testForwardToDelegate {
    TransitContext *context = [CCWeakMockProxy mockForClass:TransitContext .class];
    TransitNativeFunction *function = [CCWeakMockProxy mockForClass:TransitNativeFunction.class];
    id delegate = [OCMockObject mockForProtocol:@protocol(TransitFunctionBodyProtocol)];
    id thisArg = @"thisValue";
    NSArray *arguments = @[@1, @2, @3];
    BOOL expectsResult = YES;
    TransitFunctionCallScope *scope = [TransitFunctionCallScope.alloc initWithContext:context parentScope:nil thisArg:thisArg arguments:arguments expectsResult:expectsResult function:function];

    [[[delegate stub] andReturn:@"someResult"] callWithFunction:function thisArg:thisArg arguments:arguments expectsResult:expectsResult];
    id actual = [scope forwardToDelegate:delegate];
    STAssertEqualObjects(@"someResult", actual, @"result from forwarded function");
}

@end
