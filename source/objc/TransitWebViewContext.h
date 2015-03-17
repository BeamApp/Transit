//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#if TRANSIT_OS_MAC

#import "TransitAbstractWebViewContext.h"

@class WebView;

/// Context to expose JavaScript environment of existing webview on OS X.
@interface TransitWebViewContext : TransitAbstractWebViewContext

+(id)contextWithWebView:(WebView*)webView;

-(id)initWithWebView:(WebView*)webView;

@property(nonatomic, readonly, strong) WebView* webView;

@end

#endif
