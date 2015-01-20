//
//  TransitFunctionTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Transit+Private.h"
#import "OCMock.h"
#import "CCWeakMockProxy.h"
#import "TransitNativeFunction.h"
#import "TransitNativeFunction+Private.h"
#import "TransitFunctionCallScope.h"
#import "TransitFunctionCallScope+Private.h"
#import "TransitContext.h"
#import "TransitFunctionBodyProtocol.h"

@interface TransitNativeFunctionWithSpecificBlockTests : SenTestCase

@end

@implementation TransitNativeFunctionWithSpecificBlockTests

+ (NSArray *) testInvocations {
    // hide these tests on iOS 5
    // specific blocks are not supported over there
    if(transit_specificBlocksSupported()) {
        return [super testInvocations];
    } else {
        // if specific blocks are not supported, test at least that calls will cause an intended exception
        SEL selector = @selector(testGenericFunctionBlockWithBlockThrowsIfUnsupported);
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:selector]];
        inv.selector = selector;
        return @[inv];
    }
}

-(void)testGenericFunctionBlockWithBlockThrowsIfUnsupported {
    if(transit_specificBlocksSupported()){
        STAssertNoThrow(([TransitNativeFunction genericFunctionBlockWithBlock:^{}]), @"specfic block supported");
    } else {
        STAssertThrows(([TransitNativeFunction genericFunctionBlockWithBlock:^{}]), @"specfic block not supported");
    }
}

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

#if TRANSIT_SPECIFIC_BLOCKS_SUPPORTED

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

-(void)testNativeArgumentTypes {
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

        return f+d;
    };

    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    STAssertEqualObjects(actualResult, @24, @"result");
}

-(void)testBoolReturnType {
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:^{return YES;}];
    TransitNativeFunctionCallScope *scope = [TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:nil expectsResult:YES function:nil];
    id actualResult = genericBlock(scope);
    STAssertEqualObjects(actualResult, @YES, @"result");
}

-(void)testNativeReturnTypes {
    //cislqCISLQfdB see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    NSArray* blocks = @[
            ^{return (char)1;},
            ^{return (int)2;},
            ^{return (short)3;},
            ^{return (long)4;},
            ^{return (long long)5;},
            ^{return (unsigned char)6;},
            ^{return (unsigned int)7;},
            ^{return (unsigned short)8;},
            ^{return (unsigned long)9;},
            ^{return (unsigned long long)10;},
            ^{return (float)11;},
            ^{return (double)12;},
    ];

    for(NSUInteger i=0; i<blocks.count; i++) {
        id block = blocks[i];
        TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
        id actualResult = genericBlock([[TransitNativeFunctionCallScope alloc] initWithContext:nil parentScope:nil thisArg:nil arguments:nil expectsResult:YES function:nil]);
        STAssertEqualObjects(actualResult, @(i+1), @"result");
    }
}

-(void)testIncompatibleArgsWillBeTransformedToAsGoodAsPossible {
    id block = ^(int i, float f, bool b1, bool b2, double d) {
        return [NSString stringWithFormat:@"i: %d, f: %.2f, b1: %d, b2: %d, d: %.2f", i, f, b1, b2, d];
    };

    NSArray* args = @[@"foo", @"bar", @"baz", @"true", @"12.5"];
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([[TransitNativeFunctionCallScope alloc] initWithContext:nil parentScope:nil thisArg:nil arguments:args expectsResult:YES function:nil]);
    STAssertEqualObjects(actualResult, @"i: 0, f: 0.00, b1: 0, b2: 1, d: 12.50", @"result");
}

-(void)testCannotDetectClassesFromSignature {
    id block = ^(NSString* s, NSNumber* n) {
        return [NSString stringWithFormat:@"%@-%@, %@-%@", s, s.class, n, n.class];
    };

    NSArray* args = @[@12.5, @"foo"];
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([[TransitNativeFunctionCallScope alloc] initWithContext:nil parentScope:nil thisArg:nil arguments:args expectsResult:YES function:nil]);
    STAssertEqualObjects(actualResult, @"12.5-__NSCFNumber, foo-__NSCFConstantString", @"result");
}


-(void)testCallFromContext {
    id mock = [CCWeakMockProxy mockForProtocol:@protocol(TransitFunctionBodyProtocol)];
    id block = ^(int i, float f, BOOL b, NSString* s){
        STAssertEquals(i, (int)1, @"int");
        STAssertEquals(f, (float)2.5, @"float");
        STAssertEquals(b, YES, @"bool");
        STAssertEqualObjects(s, @"foo", @"string");

        return f+i;
    };

    TransitContext *context = [TransitContext new];
    TransitFunction *func = [context functionWithBlock:block];

    id thisArg = @{};
    id args = @[@1, @2.5, @YES, @"foo"];
    id returnValue = @"3.5";

    [[[mock stub] andReturn:returnValue] callWithFunction:func thisArg:thisArg arguments:args expectsResult:YES];
    id actualResult = [func callWithThisArg:thisArg arguments:args];
    STAssertEquals([actualResult floatValue], [returnValue floatValue], @"result");
    [mock verify];
}

#endif

@end
