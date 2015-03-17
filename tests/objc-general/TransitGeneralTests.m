//
//  TransitTestsIOSTests.m
//  TransitTestsIOSTests
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

@interface TransitGeneralTests : XCTestCase
@end

@implementation TransitGeneralTests

-(void)testTransitNilSafeOnString {
    id value = @"undefined";
    id actual = TransitNilSafe(value);
    
    XCTAssertEqualObjects(value, actual, @"equal");
    XCTAssertTrue(value == actual, @"same");
    XCTAssertFalse(transit_isJSExpression(actual), @"plain string");
}

-(void)testTransitNilSafeOnNil {
    id value = nil;
    id actual = TransitNilSafe(value);
    
    XCTAssertFalse(value == actual, @"same");
    XCTAssertEqualObjects(@"undefined", actual, @"string containined 'undefined'");
    XCTAssertTrue(transit_isJSExpression(actual), @"marked as jsExpression");
}


@end
