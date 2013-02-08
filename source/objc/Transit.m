//
//  Transit.m
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import "Transit.h"
#import "SBJson.h"

@implementation TransitProxy

-(id)eval:(NSString*)jsCode {
    return [self eval:jsCode thisArg:nil arguments:@[]];
}

-(id)eval:(NSString*)jsCode arguments:(NSArray*)arguments {
    return [self eval:jsCode thisArg:nil arguments:arguments];
}

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arguments:(NSArray*)arguments {
    @throw @"must be implemented by subclass";
}


@end

@implementation TransitContext
@end

@implementation TransitUIWebViewContext

+(id)contextWithUIWebView:(UIWebView*)webView {
    return [[self alloc] initWithUIWebView: webView];
}

-(id)initWithUIWebView:(UIWebView*)webView {
    self = [self init];
    if(self) {
        _webView = webView;
    }
    return self;
}

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg arguments:(NSArray *)arguments {
    SBJsonParser *parser = [SBJsonParser new];
    NSString* js = [NSString stringWithFormat: @"JSON.stringify({v:%@})", jsCode];
    NSString* jsResult = [_webView stringByEvaluatingJavaScriptFromString: js];
    return [parser objectWithString:jsResult][@"v"];
}

@end
