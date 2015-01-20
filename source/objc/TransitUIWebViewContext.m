//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitUIWebViewContext.h"
#import "TransitAbstractWebViewContext+Private.h"
#import "TransitCore.h"

@interface TransitUIWebViewContext ()
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation TransitUIWebViewContext {
    id<UIWebViewDelegate> _originalDelegate;
}

+(id)contextWithUIWebView:(UIWebView*)webView {
    return [[self alloc] initWithUIWebView: webView];
}

-(id)initWithUIWebView:(UIWebView*)webView {
    self = [self init];
    if (self) {
        _webView = webView;
        [self bindToWebView];
    }
    return self;
}

-(void)dealloc {
    [_webView removeObserver:self forKeyPath:@"delegate"];
}

-(void)bindToWebView {
    _originalDelegate = _webView.delegate;
    _webView.delegate = self;
    [_webView addObserver:self forKeyPath:@"delegate" options:NSKeyValueObservingOptionNew context:nil];
    [self injectCodeToWebView];
}

- (NSString *)_stringByEvaluatingJavaScriptFromString:(NSString *)js {
    return [_webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([request.URL.scheme isEqual:_TRANSIT_SCHEME]){
        if (self.handleRequestBlock) {
            self.handleRequestBlock(self, request);
        }

        return NO;
    }

    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];

    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webViewDidStartLoad:webView];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self injectCodeToWebView];

    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webViewDidFinishLoad:webView];
    if(self.readyHandler)
        self.readyHandler(self);
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([_originalDelegate respondsToSelector:_cmd])
        return [_originalDelegate webView:webView didFailLoadWithError:error];
}

@end
