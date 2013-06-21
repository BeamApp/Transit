//
//  TransitWebViewTests.m
//  TransitTestsOSX
//
//  Created by Heiko Behrens on 21.06.13.
//  Copyright (c) 2013 BeamApp UG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <WebKit/WebKit.h>
#import "Transit+Private.h"

@interface TransitWebViewTests : SenTestCase

@end

@implementation TransitWebViewTests

-(void)testCreateWebView {
    WebView* wv = WebView.new;
    TransitWebViewContext *context = [TransitWebViewContext contextWithWebView:wv];
    STAssertEquals(wv, context.webView, @"same property");
}

@end