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

@interface TransitContextTests : SenTestCase

@end

@implementation TransitContextTests

-(void)testJsRepresentationForProxy {
    TransitContext *context = [TransitContext new];
    NSString* actual = [context jsRepresentationForProxyWithId:@"someId"];
    STAssertEqualObjects(@"transit.retained[\"someId\"]", actual, @"proxy representation");
}

@end
