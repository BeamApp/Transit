//
//  TransitFunctionTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "TransitFunctionTests.h"
#import "Transit.h"
#import "OCMock.h"

@protocol TransitBlockTestProtocol <NSObject>

-(id)callWithThisArg:(TransitProxy*)thisArg arguments:(NSArray *)arguments;

@end

@implementation TransitFunctionTests

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

-(void)testJSRepresentation {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:nil nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    STAssertEqualObjects(func.jsRepresentation, @"transit.nativeFunction(\"someId\")", @"native jsCall");
}

-(void)testInExpression {
    TransitFunction *func = [[TransitNativeFunction alloc] initWithRootContext:nil nativeId:@"someId" block:^(TransitProxy* _this, NSArray* arguments){return (id)nil;}];
    
    STAssertEqualObjects([TransitProxy jsExpressionFromCode:@"@('foo')" arguments:@[func]], @"transit.nativeFunction(\"someId\")('foo')", @"native func");
}

@end
