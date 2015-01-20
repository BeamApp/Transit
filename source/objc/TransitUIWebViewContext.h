//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitAbstractWebViewContext.h"

/// Context to expose JavaScript environment of existing webview on iOS.
@interface TransitUIWebViewContext : TransitAbstractWebViewContext<UIWebViewDelegate>

+(id)contextWithUIWebView:(UIWebView*)webView;

-(id)initWithUIWebView:(UIWebView*)webView;

@property (nonatomic, readonly, strong) UIWebView *webView;

@end
