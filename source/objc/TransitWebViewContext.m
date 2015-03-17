//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#if TRANSIT_OS_MAC
#import "TransitWebViewContext.h"
#import <WebKit/WebKit.h>

@interface TransitWebViewContext
@property(nonatomic, strong) WebView* webView;
@end

@implementation TransitWebViewContext {
    __weak id _originalFrameLoadDelegate;
    BOOL _shouldWaitForTransitLoaded;
}

+(id)contextWithWebView:(WebView*)webView {
    return [self.class.new initWithWebView:webView];
}

-(id)initWithWebView:(WebView*)webView {
    self = [self init];
    if(self) {
        _webView = webView;
        [self bindToWebView];
    }
    return self;
}

-(void)dealloc {
    [_webView removeObserver:self forKeyPath:@"frameLoadDelegate"];
}

-(id)originalFrameLoadDelegate {
    return _originalFrameLoadDelegate;
}

-(void)bindToWebView {
    _originalFrameLoadDelegate = _webView.frameLoadDelegate;
    _webView.frameLoadDelegate = self;
    [_webView addObserver:self forKeyPath:@"frameLoadDelegate" options:NSKeyValueObservingOptionNew context:nil];
    [self injectCodeToWebView];
}

- (NSString *)_stringByEvaluatingJavaScriptFromString:(NSString *)js {
    return [_webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark - WebFrameLoadDelegate

-(BOOL)shouldWaitForTransitLoaded {
    return _shouldWaitForTransitLoaded;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if(frame == sender.mainFrame) {

        // avoid race condition: under OSX ML, frame itself is loaded but not every JS
        // so poll for its existence and value of window.transit_loaded == true
        if(self.shouldWaitForTransitLoaded)
            [self pollForTransitLoadedAndEventuallyCallReadyHandler];
        else {
            if(self.readyHandler)
                self.readyHandler(self);
        }
    }

    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:sender didFinishLoadForFrame:frame];
}

- (void)pollForTransitLoadedAndEventuallyCallReadyHandler {
    if(!self.readyHandler)
        return;

//    DDLogVerbose(@"polling for transit loaded: %@", [self _stringByEvaluatingJavaScriptFromString:@"location.href"]);

    NSString* js = @"typeof(transit_loaded)=='boolean' && transit_loaded";
    NSString* result = [self _stringByEvaluatingJavaScriptFromString:js];
    if(result.boolValue) {
//        DDLogVerbose(@"loaded :) calling completionBlock");
        self.readyHandler(self);
    } else {
        // actual polling
        [self performSelector:_cmd withObject:nil afterDelay:0.1];
    }
}

#pragma mark - WebScripting protocol

- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)args {
    NSAssert("calling undefined method %@", name);
    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(sel == @selector(callHandleRequestBlock))
        return NO;
    return YES;
}

+(BOOL)isKeyExcludedFromWebScript:(const char *)name {
    return YES;
}

-(void)callHandleRequestBlock {
    if(self.handleRequestBlock)
        self.handleRequestBlock(self, nil);
}

NSString* TransitWebScriptNamespace = @"transit_callback";

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    if(frame == sender.mainFrame){
        [windowObject setValue:self forKey:TransitWebScriptNamespace];
        [self injectCodeToWebView];
    }
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:sender didClearWindowObject:windowObject forFrame:frame];
}

-(void)injectCodeToWebView {
    [super injectCodeToWebView];
    // temporary workaround, modify grunt.js to build proper string literal
    NSString* customJS = @"(function(){"
        "transit.doInvokeNative = function(invocationDescription){\n"
            "transit.nativeInvokeTransferObject = invocationDescription;\n"
            "transit_callback.callHandleRequestBlock();\n"
            "if(transit.nativeInvokeTransferObject === invocationDescription) {\n"
            "    throw new Error(\"internal error with transit: invocation transfer object not filled.\");\n"
            "}\n"
            "var result = transit.nativeInvokeTransferObject;\n"
            "if(result instanceof Error) {\n"
            "    throw result;\n"
            "} else {\n"
            "    return result;\n"
            "}\n"
        "};"

        "transit.doHandleInvocationQueue = function(invocationDescriptions) {\n"
            "transit.nativeInvokeTransferObject = invocationDescriptions;\n"
            "transit_callback.callHandleRequestBlock();\n"
            "transit.nativeInvokeTransferObject = null;\n"
        "};"

    "})()";



    [self _stringByEvaluatingJavaScriptFromString:customJS];
}
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)webView didStartProvisionalLoadForFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didStartProvisionalLoadForFrame:frame];
};

- (void)webView:(WebView *)webView didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didReceiveServerRedirectForProvisionalLoadForFrame:frame];
};

- (void)webView:(WebView *)webView didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didFailProvisionalLoadWithError:error forFrame:frame];
};

- (void)webView:(WebView *)webView didCommitLoadForFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didCommitLoadForFrame:frame];
};

- (void)webView:(WebView *)webView didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didReceiveTitle:title forFrame:frame];
};

- (void)webView:(WebView *)webView didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didReceiveIcon:image forFrame:frame];
};

//- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame{};

- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didFailLoadWithError:error forFrame:frame];
};

- (void)webView:(WebView *)webView didChangeLocationWithinPageForFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didChangeLocationWithinPageForFrame:frame];
};

- (void)webView:(WebView *)webView willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView willPerformClientRedirectToURL:URL delay:seconds fireDate:date forFrame:frame];
};

- (void)webView:(WebView *)webView didCancelClientRedirectForFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView didCancelClientRedirectForFrame:frame];
};

- (void)webView:(WebView *)webView willCloseFrame:(WebFrame *)frame{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView willCloseFrame:frame];
};

//- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame{};

- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject{
    if([_originalFrameLoadDelegate respondsToSelector:_cmd])
        [_originalFrameLoadDelegate webView:webView windowScriptObjectAvailable:windowScriptObject];
};

@end

#endif
