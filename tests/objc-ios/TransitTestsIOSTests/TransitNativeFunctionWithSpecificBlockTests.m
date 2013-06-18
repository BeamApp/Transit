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

@interface TransitNativeFunctionWithSpecificBlockTests : SenTestCase

@end

@implementation TransitNativeFunctionWithSpecificBlockTests

-(void)testAssertFailsOnNonBlocks {
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:nil], @"nil");
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:NSNull.null], @"NSNull");
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:NSObject.new], @"NSObject");
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:@123], @"NSNumber");
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:@"foobar"], @"NSString");
}

-(void)testAssertPassesOnSimpleVoidBlock {
    STAssertNoThrow([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:^{}], @"void()");
}

-(void)testAssertPassesOnIntAndString {
    id block = ^(NSString* s){return s.length;};
    STAssertNoThrow([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:block], @"int(NSString*)");
}

-(void)testAssertFailsOnCharString {
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:^(char* a){}], @"void(char*)");
}

-(void)testAssertFailsOnVoidPointer {
    STAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:^(void* p){}], @"void(void*)");
}

-(void)testNonArgCall {
    NSArray* expectedArgs = @[];
    __block NSArray* actualArgs;
    id block = ^{
        actualArgs = @[];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:actualArgs expectsResult:YES function:nil]);

    STAssertEqualObjects(actualArgs, expectedArgs, @"args");
    STAssertEqualObjects(nil, actualResult, @"args");
}

@end
