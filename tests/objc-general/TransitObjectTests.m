//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

@interface TransitObjectTests : XCTestCase

@end

@implementation TransitObjectTests

-(void)testObjectForKeyNotSupported {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    XCTAssertThrows([object objectForKey:@"someKey"], @"not supported by base class");
}

-(void)testCallMemberNotSupported {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    XCTAssertThrows(([object callMember:@"someMember" arguments:@[@1, @2, @3]]), @"not supported by base class");
}

-(void)testContextCanBeCleared {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    XCTAssertTrue(object.context == context, @"context correctly assigned");
    [object clearContext];
    XCTAssertNil(object.context, @"context removed");
}

-(void)testObjectForKey {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    [[[context stub] andReturn:@"value"] eval:@"@[@]" val:object val:@"key"];
    id value = [object objectForKey:@"key"];

    XCTAssertEqualObjects(@"value", value, @"returned correct value");
    XCTAssertNoThrow([context verify], @"verify mock");

    [[context expect] eval:@"@[@]=@" val:object val:@"key" val:@"value2"];
    [object setObject:@"value2" forKey:@"key"];
    XCTAssertNoThrow([context verify], @"verify mock");
}

-(void)testIndexedSubscript {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitObject *object = [TransitObject.alloc initWithContext:context];

    [[[context stub] andReturn:@"value"] eval:@"@[@]" val:object val:@1];
    id value = object[1];

    XCTAssertEqualObjects(@"value", value, @"returned correct value");
    XCTAssertNoThrow([context verify], @"verify mock");

    [[context expect] eval:@"@[@]=@" val:object val:@2 val:@"another value"];
    object[2] = @"another value";
    XCTAssertNoThrow([context verify], @"verify mock");
}

-(void)testKeyedSubscript {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    id  object = [TransitObject.alloc initWithContext:context];

    [[[context stub] andReturn:@"value"] eval:@"@[@]" val:object val:@"key"];
    id value = object[@"key"];

    XCTAssertEqualObjects(@"value", value, @"returned correct value");
    XCTAssertNoThrow([context verify], @"verify mock");

    [[context expect] eval:@"@[@]=@" val:object val:@"key" val:@"another value"];
    object[@"key"] = @"another value";
    XCTAssertNoThrow([context verify], @"verify mock");
}

-(void)testCallMember {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    id  object = [TransitObject.alloc initWithContext:context];

    NSArray* arguments = @[@1,@2,@3];

    [[[context stub] andReturn:@"value"] eval:@"@[@].apply(@,@)" values:@[object, @"someMethod", object, arguments]];
    id value = [object callMember:@"someMethod" arguments:arguments];

    XCTAssertEqualObjects(@"value", value, @"returned correct value");
    XCTAssertNoThrow([context verify], @"verify mock");


}



@end
