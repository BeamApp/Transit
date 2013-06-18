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
    __block bool called;
    id block = ^{
        called = YES;
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);
    STAssertNil(actualResult, @"result is nil");
    STAssertTrue(called, @"called");
}

-(void)testObjectCall {
    NSArray* expectedArgs = @[@"foo", @123];
    id block = ^(NSString* s, NSNumber *n){
        STAssertEqualObjects(s, @"foo", @"arg 1");
        STAssertEqualObjects(n, @123, @"arg 2");
        return [NSString stringWithFormat:@"%@ %@", s, n];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    STAssertEqualObjects(@"foo 123", actualResult, @"args");
}

-(void)testTooFewArgs {
    NSArray* expectedArgs = @[@"foo"];
    id block = ^(NSString* s, NSNumber *n){
        STAssertEqualObjects(s, @"foo", @"arg 1");
        STAssertNil(n, @"arg 2");
        return [NSString stringWithFormat:@"%@ %@", s, n];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    STAssertEqualObjects(@"foo (null)", actualResult, @"args");
}

-(void)testTooManyArgs {
    NSArray* expectedArgs = @[@"foo", @123, @YES];
    id block = ^(NSString* s, NSNumber *n){
        STAssertEqualObjects(s, @"foo", @"arg 1");
        STAssertEqualObjects(n, @123, @"arg 2");
        return [NSString stringWithFormat:@"%@ %@", s, n];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    STAssertEqualObjects(@"foo 123", actualResult, @"args");
}

-(void)testNativeTypes {
    NSArray* expectedArgs = @[[NSNumber numberWithChar:'c'], @2, @3, @4, @5, [NSNumber numberWithChar:'C'], @7, @8, @9, @10, @11.5, @12.5, @YES];
    //cislqCISLQfdB see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    id block = ^(
            char c, int i, short s, long l, long long q,
            unsigned char C, unsigned int I, unsigned short S, unsigned long L, unsigned long long Q,
            float f, double d, bool B){
        STAssertEquals(c, (char)'c', @"char");
        STAssertEquals(i, (int)2, @"int");
        STAssertEquals(s, (short)3, @"short");
        STAssertEquals(l, (long)4, @"long");
        STAssertEquals(q, (long long)5, @"long long");
        STAssertEquals(C, (unsigned char)'C', @"unsigned char");
        STAssertEquals(I, (unsigned int)7, @"unsigned int");
        STAssertEquals(S, (unsigned short)8, @"unsigned short");
        STAssertEquals(L, (unsigned long)9, @"unsigned long");
        STAssertEquals(Q, (unsigned long long)10, @"unsigned long long");
        STAssertEquals(f, (float)11.5, @"float");
        STAssertEquals(d, (double)12.5, @"double");
        STAssertEquals(B, (bool)YES, @"bool");

        // TODO: uncomment me, again
//        return f+d;
        return @(f+d);
    };

    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    STAssertEqualObjects(actualResult, @24, @"result");
}

@end
