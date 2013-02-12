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

@interface TransitNativeFunctionTests : SenTestCase

@end

@implementation TransitNativeFunctionTests

-(void)testWillCallBlock {
    id mock = [OCMockObject mockForProtocol:@protocol(TransitBlockTestProtocol)];
    __block TransitProxy* receivedThis;
    TransitFunctionBlock block = ^(TransitProxy* _this, NSArray* arguments){
        receivedThis = _this;
        return [mock callWithThisArg:_this arguments:arguments];
    };
    
    TransitContext *context = TransitContext.new;
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context nativeId:@"someId" block:block];
    
    id thisArg = @{@"a":@1};
    id args = @[@1, @"b"];
    id returnValue = @"result";
    
    [[[mock stub] andReturn:returnValue] callWithThisArg:OCMOCK_ANY arguments:args];
    id actualResult = [func callWithThisArg:thisArg arguments:args];
    STAssertTrue(actualResult == returnValue, @"passes result");
    STAssertTrue(receivedThis.value == thisArg, @"naked this arg has been wrapped");
    [mock verify];
}

-(id)simpleContext {
    TransitContext *context = [[TransitContext alloc] init];
//    id globalVar = @"transit".stringAsJSExpression;
//    [[[(id)context stub] andReturn:globalVar] transitGlobalVarJSExpression];
    return context;
}

-(void)testJSRepresentation {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:[self simpleContext] nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    
    NSMutableOrderedSet* set = NSMutableOrderedSet.orderedSet;
    NSString* actual = [func _jsRepresentationCollectingProxiesOnScope:set];
    STAssertEqualObjects(@[func], set.array, @"proxy on scope");
    
    STAssertEqualObjects(actual, @"someId", @"just the id, corresponding variable will be put on scope");
}

-(void)testJSRepresentationToResolveProxy {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:[self simpleContext] nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    
    NSString* actual = [func jsRepresentationToResolveProxy];
    
    STAssertEqualObjects(actual, @"transit.nativeFunction(\"someId\")", @"actual function factory to create scoped variables on TransitContext-eval");
}

-(void)testInExpression {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:[self simpleContext] nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    
    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    STAssertEqualObjects([TransitProxy jsExpressionFromCode:@"@('foo')" arguments:@[func] collectingProxiesOnScope:proxiesOnScope], @"someId('foo')", @"just the id, corresponding variable will be put on scope");
    STAssertEqualObjects(@[func], proxiesOnScope.array, @"");
}

-(void)testDisposeOnNilContextDoesNotThrowException {
    TransitNativeFunction *func = [[TransitNativeFunction alloc] initWithRootContext:nil nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    [func dispose];
}

-(void)testExplicitDispose {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:context proxyId:@"someId"];
    
    // calls for the first time
    [[context expect] releaseNativeProxy:func];
    [func dispose];
    [context verify];
    
    // does not call a second time
    STAssertTrue(func.disposed, @"is disposed");
    [func dispose];
    [context verify];
}

@end
