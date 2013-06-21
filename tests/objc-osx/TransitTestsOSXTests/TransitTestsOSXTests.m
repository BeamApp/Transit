//
//  TransitTestsOSXTests.m
//  TransitTestsOSXTests
//
//  Created by Heiko Behrens on 21.06.13.
//  Copyright (c) 2013 BeamApp UG. All rights reserved.
//

#import "TransitTestsOSXTests.h"
#import "OCMock.h"

@implementation TransitTestsOSXTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    id mock = [OCMockObject niceMockForClass:NSObject.class];
    [[mock expect] className];
    [mock className];
    STAssertNoThrow([mock verify], @"mock");
}

@end
