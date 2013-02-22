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

@interface TransitObjectTests : SenTestCase

@end

@implementation TransitObjectTests

-(void)testObjectForKeyNotSupported {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    STAssertThrows([object objectForKey:@"someKey"], @"not supported by base class");
}

-(void)testCallMemberNotSupported {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    STAssertThrows(([object callMember:@"someMember" arguments:@[@1, @2, @3]]), @"not supported by base class");
}

-(void)testContextCanBeCleared {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    STAssertTrue(object.context == context, @"context correctly assigned");
    [object clearContext];
    STAssertNil(object.context, @"context removed");
}

-(void)testObjectForKey {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    [[[context stub] andReturn:@"value"] eval:@"@[@]" val:object val:@"key"];
    id value = [object objectForKey:@"key"];

    STAssertEqualObjects(@"value", value, @"returned correct value");
    STAssertNoThrow([context verify], @"verify mock");

    [[context expect] eval:@"@[@]=@" val:object val:@"key" val:@"value2"];
    [object setObject:@"value2" forKey:@"key"];
    STAssertNoThrow([context verify], @"verify mock");
}

-(void)testIndexedSubscript {
    id context = [OCMockObject mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    [[[context stub] andReturn:@"value"] eval:@"@[@]" val:object val:@1];
    id value = object[1];

    STAssertEqualObjects(@"value", value, @"returned correct value");
    STAssertNoThrow([context verify], @"verify mock");

    [[context expect] eval:@"@[@]=@" val:object val:@2 val:@"another value"];
    object[2] = @"another value";
    STAssertNoThrow([context verify], @"verify mock");
}

-(void)testKeyedSubscript {
    id context = [OCMockObject mockForClass:TransitContext.class];
    id  object = [TransitObject.alloc initWithContext:context];

    [[[context stub] andReturn:@"value"] eval:@"@[@]" val:object val:@"key"];
    id value = object[@"key"];

    STAssertEqualObjects(@"value", value, @"returned correct value");
    STAssertNoThrow([context verify], @"verify mock");

    [[context expect] eval:@"@[@]=@" val:object val:@"key" val:@"another value"];
    object[@"key"] = @"another value";
    STAssertNoThrow([context verify], @"verify mock");
}

-(void)testCallMember {
    id context = [OCMockObject mockForClass:TransitContext.class];
    id  object = [TransitObject.alloc initWithContext:context];

    NSArray* arguments = @[@1,@2,@3];

    [[[context stub] andReturn:@"value"] eval:@"@[@].apply(@,@)" values:@[object, @"someMethod", object, arguments]];
    id value = [object callMember:@"someMethod" arguments:arguments];

    STAssertEqualObjects(@"value", value, @"returned correct value");
    STAssertNoThrow([context verify], @"verify mock");


}



@end
