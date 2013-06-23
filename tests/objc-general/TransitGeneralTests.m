//
//  TransitTestsIOSTests.m
//  TransitTestsIOSTests
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Transit.h"
#import "OCMock.h"

@interface TransitGeneralTests : SenTestCase
@end

@implementation TransitGeneralTests

-(void)testTransitNilSafeOnString {
    id value = @"undefined";
    id actual = TransitNilSafe(value);
    
    STAssertEqualObjects(value, actual, @"equal");
    STAssertTrue(value == actual, @"same");
    STAssertFalse(transit_isJSExpression(actual), @"plain string");
}

-(void)testTransitNilSafeOnNil {
    id value = nil;
    id actual = TransitNilSafe(value);
    
    STAssertFalse(value == actual, @"same");
    STAssertEqualObjects(@"undefined", actual, @"string containined 'undefined'");
    STAssertTrue(transit_isJSExpression(actual), @"marked as jsExpression");
}


@end
