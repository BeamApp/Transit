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

@interface TransitCallScopeTests : SenTestCase

@end

@implementation TransitCallScopeTests

-(void)testFunctionCallScope {
    TransitContext *context = [OCMockObject mockForClass:TransitContext .class];
    TransitNativeFunction *function = [OCMockObject mockForClass:TransitNativeFunction.class];
    id thisArg = @"thisValue";
    NSArray *arguments = @[@1, @2, @3];
    TransitFunctionCallScope *scope = [TransitFunctionCallScope.alloc initWithContext:context function:function thisArg:thisArg arguments:arguments expectsResult:NO];

    STAssertTrue(context == scope.context, @"context prop");
    STAssertTrue(function == scope.function, @"function");
    STAssertTrue(thisArg == scope.thisArg, @"thisArg");
    STAssertTrue(arguments == scope.arguments, @"arguments");
}

-(void)testForwardToFunction {
    TransitContext *context = [OCMockObject mockForClass:TransitContext .class];
    TransitNativeFunction *function = [OCMockObject mockForClass:TransitNativeFunction.class];
    id function2 = [OCMockObject mockForClass:TransitFunction.class];
    id thisArg = @"thisValue";
    NSArray *arguments = @[@1, @2, @3];
    BOOL expectsResult = YES;
    TransitFunctionCallScope *scope = [TransitFunctionCallScope.alloc initWithContext:context function:function thisArg:thisArg arguments:arguments expectsResult:expectsResult];

    [[[function2 stub] andReturn:@"someResult"] callWithThisArg:thisArg arguments:arguments returnResult:expectsResult];
    id actual = [scope forwardToFunction:function2];
    STAssertEqualObjects(@"someResult", actual, @"result from forwarded delegate");
}

-(void)testForwardToDelegate {
    TransitContext *context = [OCMockObject mockForClass:TransitContext .class];
    TransitNativeFunction *function = [OCMockObject mockForClass:TransitNativeFunction.class];
    id delegate = [OCMockObject mockForProtocol:@protocol(TransitFunctionBodyProtocol)];
    id thisArg = @"thisValue";
    NSArray *arguments = @[@1, @2, @3];
    BOOL expectsResult = YES;
    TransitFunctionCallScope *scope = [TransitFunctionCallScope.alloc initWithContext:context function:function thisArg:thisArg arguments:arguments expectsResult:expectsResult];

    [[[delegate stub] andReturn:@"someResult"] callWithFunction:function thisArg:thisArg arguments:arguments expectsResult:expectsResult];
    id actual = [scope forwardToDelegate:delegate];
    STAssertEqualObjects(@"someResult", actual, @"result from forwarded function");
}

@end
