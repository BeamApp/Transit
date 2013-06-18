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
@class TransitNativeFunction;
@class TransitCallScope;
@class TransitNativeFunctionCallScope;
@class TransitFunctionCallScope;
@class TransitNativeFunctionCallScope;

@interface TransitObject : NSObject

-(TransitContext*)context;

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id < NSCopying >)key;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSInteger)idx;
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

- (id)callMember:(NSString *)string;
- (id)callMember:(NSString *)string arg:(id)arg0;
- (id)callMember:(NSString *)string arg:(id)arg0 arg:(id)arg1;
- (id)callMember:(NSString *)string arg:(id)arg0 arg:(id)arg1 arg:(id)arg2;
- (id)callMember:(NSString *)string arguments:(NSArray *)arguments;



@end

@interface TransitProxy : TransitObject

@property(nonatomic, readonly) id value;

@end

typedef id (^TransitGenericFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef void (^TransitVoidFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef id (^TransitReplaceFunctionBlock)(TransitFunction* original, TransitNativeFunctionCallScope *callScope);

@protocol TransitFunctionBodyProtocol <NSObject>
- (id)callWithFunction:(TransitFunction *)function thisArg:(id)thisArg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult;
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

-(TransitFunction*)functionWithGenericBlock:(TransitGenericFunctionBlock)block;
-(TransitFunction*)functionWithDelegate:(id<TransitFunctionBodyProtocol>)delegate;
-(TransitFunction*)replaceFunctionAt:(NSString*)path withFunctionWithBlock:(TransitReplaceFunctionBlock)block;

-(TransitFunction*)asyncFunctionWithBlock:(TransitVoidFunctionBlock)block;

@property(nonatomic, readonly) TransitCallScope* currentCallScope;

-(void)dispose;

@property(nonatomic, copy) void (^readyHandler)(TransitContext *);

- (void)evalContentsOfFileOnGlobalScope:(NSString *)path encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (void)evalOnGlobalScope:(NSString *)string;

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

@property(readonly) TransitGenericFunctionBlock block;

@end


@interface TransitJSFunction : TransitFunction

@end

@interface TransitCallScope : TransitEvaluable

@property (nonatomic, readonly) TransitCallScope *parentScope;
@property (nonatomic, readonly) id thisArg;
@property (nonatomic, readonly) BOOL expectsResult;
@property (nonatomic, readonly) NSUInteger level;

-(NSString*)callStackDescription;

@end

@interface TransitEvalCallScope : TransitCallScope

@property (nonatomic, readonly) NSString* jsCode;
@property (nonatomic, readonly) NSArray* values;

- (id)initWithContext:(TransitContext *)parentScope parentScope:(TransitCallScope *)scope thisArg:(id)thisArg jsCode:(NSString *)jsCode values:(NSArray *)values expectsResult:(BOOL)expectsResult;
@end

@interface TransitAsyncCallScope : TransitCallScope
@end

@interface TransitFunctionCallScope : TransitCallScope

@property (nonatomic, readonly) TransitFunction *function;
@property (nonatomic, readonly) NSArray* arguments;

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)arg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult function:(TransitFunction *)function;

-(id)forwardToFunction:(TransitFunction *)function;
-(id)forwardToDelegate:(id<TransitFunctionBodyProtocol>)delegate;

@end

@interface TransitJSFunctionCallScope : TransitFunctionCallScope
@end

@interface TransitNativeFunctionCallScope : TransitFunctionCallScope

@end