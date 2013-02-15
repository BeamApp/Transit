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

@end
