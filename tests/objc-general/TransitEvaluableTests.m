//
//  TransitProxyTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

@interface TransitEvaluableTests : XCTestCase

@end

@implementation TransitEvaluableTests


-(void)testDelegatesEvalToRootContext {
    id context = [CCWeakMockProxy mockForClass:TransitContext.class];
    TransitEvaluable *evaluable = [[TransitEvaluable alloc] initWithContext:context];

    [[[context stub] andReturn:@"4"] eval:@"2+2" thisArg:evaluable values:@[] returnJSResult:YES];
    NSString* actual = [evaluable eval:@"2+2"];
    XCTAssertEqualObjects(@"4", actual, @"passed through");
    [context verify];
}


@end
