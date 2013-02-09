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


@protocol TransitBlockTestProtocol <NSObject>

-(id)callWithThisArg:(TransitProxy*)thisArg arguments:(NSArray *)arguments;

@end

@implementation TransitNativeFunctionTests

-(void)testWillCallBlock {
    id mock = [OCMockObject mockForProtocol:@protocol(TransitBlockTestProtocol)];
    TransitFunctionBlock block = ^(TransitProxy* _this, NSArray* arguments){
        return [mock callWithThisArg:_this arguments:arguments];
    };
    
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:nil nativeId:@"someId" block:block];
    
    id thisArg = @{@"a":@1};
    id args = @[@1, @"b"];
    id returnValue = @"result";
    
    [[[mock stub] andReturn:returnValue] callWithThisArg:thisArg arguments:args];
    id actualResult = [func callWithThisArg:thisArg arguments:args];
    STAssertTrue(actualResult == returnValue, @"passes result");
    [mock verify];
}

-(id)contextStubForTransitGlobalVar {
    TransitContext *context = [OCMockObject niceMockForClass:TransitContext.class];
    id globalVar = [[TransitJSDirectExpression alloc] initWithExpression:@"transit"];
    [[[(id)context stub] andReturn:globalVar] transitGlobalVarProxy];
    return context;
}

-(void)testJSRepresentation {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:[self contextStubForTransitGlobalVar] nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    NSString* actual = func.jsRepresentation;
    NSLog(@"actual: %@", actual);
    STAssertEqualObjects(actual, @"transit.nativeFunction(\"someId\")", @"native jsCall");
}

-(void)testInExpression {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:[self contextStubForTransitGlobalVar] nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    
    STAssertEqualObjects([TransitProxy jsExpressionFromCode:@"@('foo')" arguments:@[func]], @"transit.nativeFunction(\"someId\")('foo')", @"native func");
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
