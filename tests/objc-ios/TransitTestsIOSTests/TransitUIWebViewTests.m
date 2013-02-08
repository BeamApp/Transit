//
//  TransitUIWebViewTests.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "TransitUIWebViewTests.h"
#import "Transit.h"

@implementation TransitUIWebViewTests

-(UIWebView*)webViewWithEmptyPage {
    UIWebView* result = [UIWebView new];
    [result loadHTMLString:@"<html><h1>empty page</h1></html>" baseURL:nil];
    return result;
}

-(void)testResultTypes {
    TransitUIWebViewContext *context = [TransitUIWebViewContext contextWithUIWebView:[self webViewWithEmptyPage]];
    
    STAssertEqualObjects([context eval:@"2+2"], @4, @"number");
    STAssertEqualObjects([context eval:@"3>2"], @YES, @"boolean");
    STAssertEqualObjects([context eval:@"'foo'+'bar'"], @"foobar", @"string");
    
    STAssertEqualObjects([context eval:@"{a:1,b:'two'}"],(@{@"a":@1,@"b":@"two"}), @"object");
    STAssertEqualObjects([context eval:@"null"], NSNull.null, @"null");
    STAssertEqualObjects([context eval:@"undefined"], nil, @"undefined");
}



@end
