//
//  TransitTestsIOSTests.m
//  TransitTestsIOSTests
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "TransitTestsIOSTests.h"
#import "Transit.h"
#import "OCMock.h"

@implementation TransitTestsIOSTests

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

- (void)testJSExpressionFromCodeAndArguments {
    STAssertEqualObjects(@"no arguments", [TransitProxy jsExpressionFromCode:@"no arguments" arguments:@[]], @"no arguments");
    
    STAssertEqualObjects(@"int: 23", [TransitProxy jsExpressionFromCode:@"int: @" arguments:@[@23]], @"one int");
    STAssertEqualObjects(@"float: 42.5", [TransitProxy jsExpressionFromCode:@"float: @" arguments:@[@42.5]], @"one float");
    STAssertEqualObjects(@"bool: true", [TransitProxy jsExpressionFromCode:@"bool: @" arguments:@[@YES]], @"one true");
    STAssertEqualObjects(@"bool: false", [TransitProxy jsExpressionFromCode:@"bool: @" arguments:@[@NO]], @"one false");

    STAssertEqualObjects(@"string: \"foobar\"", [TransitProxy jsExpressionFromCode:@"string: @" arguments:@[@"foobar"]], @"one string");
    
    STAssertEqualObjects(@"\"foo\" + \"bar\"", [TransitProxy jsExpressionFromCode:@"@ + @" arguments:(@[@"foo", @"bar"])], @"two strings");
    STAssertEqualObjects(@"'baz' + \"bam\" + 23", [TransitProxy jsExpressionFromCode:@"'baz' + @ + @" arguments:(@[@"bam", @23])], @"two strings");
}

- (void)testJSExpressionFromObjectWithJsRepresentation {
    TransitProxy* proxy = [OCMockObject mockForClass:TransitProxy.class];
    [[[(id)proxy stub] andReturn:@"myRepresentation"] jsRepresentation];
    STAssertEqualObjects(proxy.jsRepresentation, @"myRepresentation", @"works");
    STAssertEqualObjects([TransitProxy jsExpressionFromCode:@"return @" arguments:@[proxy]], @"return myRepresentation", @"static method uses instance jsRepresentation");
}

- (void)testJSExpressionWithInvalidArgumentCount {
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"expect arg: @" arguments:@[]], NSException, NSInvalidArgumentException, @"too few arguments");
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"expect nothing" arguments:@[@"some"]], NSException, NSInvalidArgumentException, @"too many arguments");
}

- (void)testJSExpressionWithInvalidArgumentType {
    STAssertThrowsSpecificNamed([TransitProxy jsExpressionFromCode:@"obj: @" arguments:@[self]], NSException, NSInvalidArgumentException, @"cannot make JSON");
}


@end
