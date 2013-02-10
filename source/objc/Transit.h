//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TransitContext;

@interface TransitProxy : NSObject

-(id)initWithRootContext:(TransitContext*)rootContext;
-(id)initWithRootContext:(TransitContext*)rootContext proxyId:(NSString*)proxyId;
-(id)initWithRootContext:(TransitContext*)rootContext value:(id)value;
-(id)initWithRootContext:(TransitContext *)rootContext jsRepresentation:(NSString*)jsRepresentation;

-(TransitContext*)rootContext;
@property(nonatomic, readonly) id value;

-(id)eval:(NSString*)jsCode;
-(id)eval:(NSString*)jsCode arguments:(NSArray*)arguments;
-(id)eval:(NSString*)jsCode thisArg:(id)thisArg arguments:(NSArray*)arguments;

+(NSString*)jsExpressionFromCode:(NSString*)jsCode arguments:(NSArray*)arguments;

-(NSString*)jsRepresentation;

@end

@interface TransitContext : TransitProxy

@end

@interface TransitUIWebViewContext : TransitContext<UIWebViewDelegate>

+(id)contextWithUIWebView:(UIWebView*)webView;

-(id)initWithUIWebView:(UIWebView*)webView;

@property(readonly) UIWebView* webView;

@end

@interface TransitFunction : TransitProxy

-(id)call;
-(id)callWithArguments:(NSArray*)arguments;
-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments;

@end

typedef id (^TransitFunctionBlock)(TransitProxy *thisArg, NSArray* arguments);

@interface TransitNativeFunction : TransitFunction

-(id)initWithRootContext:(TransitContext *)rootContext nativeId:(NSString*)nativeId block:(TransitFunctionBlock)block;

-(void)dispose;

@property(readonly) NSString* nativeId;
@property(readonly) TransitFunctionBlock block;

@end


@interface TransitJSFunction : TransitFunction

@end