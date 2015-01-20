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
#import "CCWeakMockProxy.h"

@interface TransitNativeFunctionTests : SenTestCase

@end

@implementation TransitNativeFunctionTests {
    TransitContext *_simpleContext;
}

- (void)setUp {
    [super setUp];
    _simpleContext = TransitContext.new;
}

- (void)tearDown {
    _simpleContext = nil;
    [super tearDown];
}

-(void)testWillCallBlock {
    id mock = [CCWeakMockProxy mockForProtocol:@protocol(TransitFunctionBodyProtocol)];
    TransitGenericFunctionBlock block = ^(TransitNativeFunctionCallScope *scope){
        return [scope forwardToDelegate:mock];
    };

    TransitContext *context = TransitContext.new;
    TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:context nativeId:@"someId" genericBlock:block];

    id thisArg = @{@"a":@1};
    id args = @[@1, @"b"];
    id returnValue = @"result";

    [[[mock stub] andReturn:returnValue] callWithFunction:func thisArg:thisArg arguments:args expectsResult:YES];
    id actualResult = [func callWithThisArg:thisArg arguments:args];
    STAssertTrue(actualResult == returnValue, @"passes result");
    [mock verify];
}

-(void)testJSRepresentation {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:_simpleContext nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];

    NSMutableOrderedSet* set = NSMutableOrderedSet.orderedSet;
    NSString* actual = [func _jsRepresentationCollectingProxiesOnScope:set];
    STAssertEqualObjects(@[func], set.array, @"proxy on scope");

    STAssertEqualObjects(actual, @"__TRANSIT_NATIVE_FUNCTION_someId", @"just the id, corresponding variable will be put on scope");
}

-(void)testJSRepresentationToResolveProxyBlocked {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:_simpleContext nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];

    NSString* actual = [func jsRepresentationToResolveProxy];

    STAssertEqualObjects(actual, @"transit.nativeFunction(\"someId\")", @"actual function factory to create scoped variables on TransitContext-eval");
}

-(void)testJSRepresentationToResolveProxyAsync {
    TransitNativeFunction *func = [[TransitNativeFunction alloc] initWithContext:_simpleContext nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];
    func.async = YES;

    NSString* actual = [func jsRepresentationToResolveProxy];

    STAssertEqualObjects(actual, @"transit.nativeFunction(\"someId\",{async:true})", @"actual function factory to create scoped variables on TransitContext-eval");
}

-(void)testJSRepresentationToResolveProxyNoThis {
    TransitNativeFunction *func = [[TransitNativeFunction alloc] initWithContext:_simpleContext nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];
    func.noThis = YES;

    NSString* actual = [func jsRepresentationToResolveProxy];

    STAssertEqualObjects(actual, @"transit.nativeFunction(\"someId\",{noThis:true})", @"actual function factory to create scoped variables on TransitContext-eval");
}

-(void)testJSRepresentationToResolveProxyAsyncAndNoThis {
    TransitNativeFunction *func = [[TransitNativeFunction alloc] initWithContext:_simpleContext nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];
    func.async = YES;
    func.noThis = YES;

    NSString* actual = [func jsRepresentationToResolveProxy];

    STAssertEqualObjects(actual, @"transit.nativeFunction(\"someId\",{async:true,noThis:true})", @"actual function factory to create scoped variables on TransitContext-eval");
}

-(void)testInExpression {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:_simpleContext nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];

    NSMutableOrderedSet *proxiesOnScope = NSMutableOrderedSet.orderedSet;
    STAssertEqualObjects([TransitProxy jsRepresentationFromCode:@"@('foo')" arguments:@[func] collectingProxiesOnScope:proxiesOnScope], @"__TRANSIT_NATIVE_FUNCTION_someId('foo')", @"just the id, corresponding variable will be put on scope");
    STAssertEqualObjects(@[func], proxiesOnScope.array, @"");
}

-(void)testDisposeOnNilContextDoesNotThrowException {
    TransitNativeFunction *func = [[TransitNativeFunction alloc] initWithContext:nil nativeId:@"someId" genericBlock:^(TransitNativeFunctionCallScope *scope) {
        return (id) nil;
    }];
    [func dispose];
}

-(void)testExplicitDispose {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitFunction *func = [[TransitNativeFunction alloc] initWithContext:context proxyId:@"someId"];

    // calls for the first time
    [[context expect] releaseNativeFunction:func];
    [func dispose];
    [context verify];

    // does not call a second time
    STAssertTrue(func.disposed, @"is disposed");
    [func dispose];
    [context verify];
}

@end
