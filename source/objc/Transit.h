//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(Transit)

-(NSString*)stringAsJSExpression;
-(BOOL) isJSExpression;

@end

id TransitNilSafe(id valueOrNil);

@class TransitContext;
@class TransitFunction;
@class TransitEvaluable;

@interface TransitObject : NSObject

-(TransitContext*)context;

- (id)objectForKey:(NSString *)string;

- (BOOL)callMember:(NSString *)string arguments:(NSArray *)arguments;
@end

@interface TransitProxy : TransitObject

@property(nonatomic, readonly) id value;

@end

typedef void (^TransitVoidFunctionBlock)(id thisArg, NSArray* arguments);
typedef id (^TransitFunctionBlock)(id thisArg, NSArray* arguments);
typedef id (^TransitReplaceFunctionBlock)(TransitFunction* original, id thisArg, NSArray* arguments);

@protocol TransitFunctionBodyProtocol <NSObject>
-(id)callWithThisArg:(TransitProxy*)thisArg arguments:(NSArray *)arguments;
@end

@interface TransitEvaluable : TransitObject

-(id)eval:(NSString*)jsCode;

-(id)eval:(NSString *)jsCode val:(id)val0;
-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1;
-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1 val:(id)val2;
-(id)eval:(NSString *)jsCode values:(NSArray*)values;

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0 val:(id)val1;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray*)values;

-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)values returnJSResult:(BOOL)returnJSResult;

@end


@interface TransitContext : TransitEvaluable

-(TransitFunction*)functionWithBlock:(TransitFunctionBlock)block;
-(TransitFunction*)functionWithDelegate:(id<TransitFunctionBodyProtocol>)delegate;
-(TransitFunction*)replaceFunctionAt:(NSString*)path withFunctionWithBlock:(TransitReplaceFunctionBlock)block;

-(TransitFunction*)asyncFunctionWithBlock:(TransitVoidFunctionBlock)block;

-(void)dispose;

@end

@interface TransitUIWebViewContext : TransitContext<UIWebViewDelegate>

+(id)contextWithUIWebView:(UIWebView*)webView;

-(id)initWithUIWebView:(UIWebView*)webView;

@property(readonly) UIWebView* webView;

@end

@interface TransitFunction : TransitProxy

-(id)call;
-(id)callWithArg:(id)arg0;
-(id)callWithArg:(id)arg0 arg:(id)arg1;
-(id)callWithArg:(id)arg0 arg:(id)arg1 arg:(id)arg2;
-(id)callWithArguments:(NSArray*)arguments;


-(id)callWithThisArg:(id)thisArg;
-(id)callWithThisArg:(id)thisArg arg:(id)arg0;
-(id)callWithThisArg:(id)thisArg arg:(id)arg0 arg:(id)arg1;
-(id)callWithThisArg:(id)thisArg arguments:(NSArray*)arguments;

-(id)callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult;

-(void)callAsync;
-(void)callAsyncWithArg:(id)arg0;
-(void)callAsyncWithArg:(id)arg0 arg:(id)arg1;
-(void)callAsyncWithArguments:(NSArray*)arguments;
-(void)callAsyncWithThisArg:(id)thisArg arguments:(NSArray*)arguments;

@end

@interface TransitNativeFunction : TransitFunction

-(void)dispose;

@property(nonatomic, assign) BOOL async;
@property(nonatomic, assign) BOOL noThis;

@property(readonly) TransitFunctionBlock block;

@end


@interface TransitJSFunction : TransitFunction

@end

