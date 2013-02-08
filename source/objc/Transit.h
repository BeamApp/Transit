//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransitProxy : NSObject

-(id)eval:(NSString*)jsCode;
-(id)eval:(NSString*)jsCode arguments:(NSArray*)arguments;
-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arguments:(NSArray*)arguments;

+(NSString*)jsExpressionFromCode:(NSString*)jsCode arguments:(NSArray*)arguments;

@end

@interface TransitContext : TransitProxy
@end

@interface TransitUIWebViewContext : TransitContext

+(id)contextWithUIWebView:(UIWebView*)webView;

-(id)initWithUIWebView:(UIWebView*)webView;

@property(readonly) UIWebView* webView;

@end
