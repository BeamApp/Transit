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

-(NSString*)jsRepresentation;

@end

@interface TransitContext : TransitProxy
@end

@interface TransitUIWebViewContext : TransitContext

+(id)contextWithUIWebView:(UIWebView*)webView;

-(id)initWithUIWebView:(UIWebView*)webView;

@property(readonly) UIWebView* webView;

@end

@interface TransitFunction : TransitProxy

-(id)initWithRootContext:(TransitContext*)rootContext;

@property(readonly) TransitContext* rootContext;

-(id)call;
-(id)callWithArguments:(NSArray*)arguments;
-(id)callWithThisArg:(TransitProxy*)thisArg arguments:(NSArray*)arguments;

@end

typedef id (^TransitFunctionBlock)(TransitProxy *thisArg, NSArray* arguments);

@interface TransitNativeFunction : TransitFunction

-(id)initWithRootContext:(TransitContext *)rootContext nativeId:(NSString*)nativeId block:(TransitFunctionBlock)block;

@property(readonly) NSString* nativeId;
@property(readonly) TransitFunctionBlock block;

@end