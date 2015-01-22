//
//  TransitFunctionTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

@interface TransitNativeFunctionWithSpecificBlockTests : XCTestCase

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
        XCTAssertNoThrow(([TransitNativeFunction genericFunctionBlockWithBlock:^{}]), @"specfic block supported");
    } else {
        XCTAssertThrows(([TransitNativeFunction genericFunctionBlockWithBlock:^{}]), @"specfic block not supported");
    }
}

-(void)teXCTAssertFailsOnNonBlocks {
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:nil], @"nil");
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:NSNull.null], @"NSNull");
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:NSObject.new], @"NSObject");
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:@123], @"NSNumber");
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:@"foobar"], @"NSString");
}

-(void)teXCTAssertPassesOnSimpleVoidBlock {
    XCTAssertNoThrow([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:^{}], @"void()");
}

-(void)teXCTAssertPassesOnIntAndString {
    id block = ^(NSString* s){return s.length;};
    XCTAssertNoThrow([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:block], @"int(NSString*)");
}

-(void)teXCTAssertFailsOnCharString {
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:^(char* a){}], @"void(char*)");
}

-(void)teXCTAssertFailsOnVoidPointer {
    XCTAssertThrows([TransitNativeFunction assertSpecificBlockCanBeUsedAsTransitFunction:^(void* p){}], @"void(void*)");
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
    XCTAssertNil(actualResult, @"result is nil");
    XCTAssertTrue(called, @"called");
}

-(void)testObjectCall {
    NSArray* expectedArgs = @[@"foo", @123];
    id block = ^(NSString* s, NSNumber *n){
        XCTAssertEqualObjects(s, @"foo", @"arg 1");
        XCTAssertEqualObjects(n, @123, @"arg 2");
        return [NSString stringWithFormat:@"%@ %@", s, n];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    XCTAssertEqualObjects(@"foo 123", actualResult, @"args");
}

-(void)testTooFewArgs {
    NSArray* expectedArgs = @[@"foo"];
    id block = ^(NSString* s, NSNumber *n){
        XCTAssertEqualObjects(s, @"foo", @"arg 1");
        XCTAssertNil(n, @"arg 2");
        return [NSString stringWithFormat:@"%@ %@", s, n];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    XCTAssertEqualObjects(@"foo (null)", actualResult, @"args");
}

-(void)testTooManyArgs {
    NSArray* expectedArgs = @[@"foo", @123, @YES];
    id block = ^(NSString* s, NSNumber *n){
        XCTAssertEqualObjects(s, @"foo", @"arg 1");
        XCTAssertEqualObjects(n, @123, @"arg 2");
        return [NSString stringWithFormat:@"%@ %@", s, n];
    };
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    XCTAssertEqualObjects(@"foo 123", actualResult, @"args");
}

-(void)testNativeArgumentTypes {
    NSArray* expectedArgs = @[[NSNumber numberWithChar:'c'], @2, @3, @4, @5, [NSNumber numberWithChar:'C'], @7, @8, @9, @10, @11.5, @12.5, @YES];
    //cislqCISLQfdB see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    id block = ^(
            char c, int i, short s, long l, long long q,
            unsigned char C, unsigned int I, unsigned short S, unsigned long L, unsigned long long Q,
            float f, double d, bool B){
        XCTAssertEqual(c, (char)'c', @"char");
        XCTAssertEqual(i, (int)2, @"int");
        XCTAssertEqual(s, (short)3, @"short");
        XCTAssertEqual(l, (long)4, @"long");
        XCTAssertEqual(q, (long long)5, @"long long");
        XCTAssertEqual(C, (unsigned char)'C', @"unsigned char");
        XCTAssertEqual(I, (unsigned int)7, @"unsigned int");
        XCTAssertEqual(S, (unsigned short)8, @"unsigned short");
        XCTAssertEqual(L, (unsigned long)9, @"unsigned long");
        XCTAssertEqual(Q, (unsigned long long)10, @"unsigned long long");
        XCTAssertEqual(f, (float)11.5, @"float");
        XCTAssertEqual(d, (double)12.5, @"double");
        XCTAssertEqual(B, (bool)YES, @"bool");

        return f+d;
    };

    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:expectedArgs expectsResult:YES function:nil]);

    XCTAssertEqualObjects(actualResult, @24, @"result");
}

-(void)testBoolReturnType {
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:^{return YES;}];
    TransitNativeFunctionCallScope *scope = [TransitNativeFunctionCallScope.alloc initWithContext:nil parentScope:nil thisArg:nil arguments:nil expectsResult:YES function:nil];
    id actualResult = genericBlock(scope);
    XCTAssertEqualObjects(actualResult, @YES, @"result");
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
        XCTAssertEqualObjects(actualResult, @(i+1), @"result");
    }
}

-(void)testIncompatibleArgsWillBeTransformedToAsGoodAsPossible {
    id block = ^(int i, float f, bool b1, bool b2, double d) {
        return [NSString stringWithFormat:@"i: %d, f: %.2f, b1: %d, b2: %d, d: %.2f", i, f, b1, b2, d];
    };

    NSArray* args = @[@"foo", @"bar", @"baz", @"true", @"12.5"];
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([[TransitNativeFunctionCallScope alloc] initWithContext:nil parentScope:nil thisArg:nil arguments:args expectsResult:YES function:nil]);
    XCTAssertEqualObjects(actualResult, @"i: 0, f: 0.00, b1: 0, b2: 1, d: 12.50", @"result");
}

-(void)testCannotDetectClassesFromSignature {
    id block = ^(NSString* s, NSNumber* n) {
        return [NSString stringWithFormat:@"%@-%@, %@-%@", s, s.class, n, n.class];
    };

    NSArray* args = @[@12.5, @"foo"];
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    id actualResult = genericBlock([[TransitNativeFunctionCallScope alloc] initWithContext:nil parentScope:nil thisArg:nil arguments:args expectsResult:YES function:nil]);
    XCTAssertEqualObjects(actualResult, @"12.5-__NSCFNumber, foo-__NSCFConstantString", @"result");
}


-(void)testCallFromContext {
    id mock = [CCWeakMockProxy mockForProtocol:@protocol(TransitFunctionBodyProtocol)];
    id block = ^(int i, float f, BOOL b, NSString* s){
        XCTAssertEqual(i, (int)1, @"int");
        XCTAssertEqual(f, (float)2.5, @"float");
        XCTAssertEqual(b, YES, @"bool");
        XCTAssertEqualObjects(s, @"foo", @"string");

        return f+i;
    };

    TransitContext *context = [TransitContext new];
    TransitFunction *func = [context functionWithBlock:block];

    id thisArg = @{};
    id args = @[@1, @2.5, @YES, @"foo"];
    id returnValue = @"3.5";

    [[[mock stub] andReturn:returnValue] callWithFunction:func thisArg:thisArg arguments:args expectsResult:YES];
    id actualResult = [func callWithThisArg:thisArg arguments:args];
    XCTAssertEqual([actualResult floatValue], [returnValue floatValue], @"result");
    [mock verify];
}

#endif

@end
