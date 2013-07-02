//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TRANSIT_OS_MAC (TARGET_OS_MAC && !(TARGET_OS_IPHONE))
#define TRANSIT_OS_IOS (TARGET_OS_IPHONE)

#if TRANSIT_OS_MAC

#import <WebKit/WebKit.h>

#endif

BOOL transit_iOS_6_OrLater();
BOOL transit_specificBlocksSupported();

NSString* transit_stringAsJSExpression(NSString* string);
BOOL transit_isJSExpression(NSString* string);

id TransitNilSafe(id valueOrNil);

@class TransitContext;
@class TransitFunction;
@class TransitEvaluable;
@class TransitNativeFunction;
@class TransitCallScope;
@class TransitNativeFunctionCallScope;
@class TransitFunctionCallScope;
@class TransitNativeFunctionCallScope;

/// TransitObject builds the foundation for many objects represented in the JavaScript environment.
@interface TransitObject : NSObject

/// The TransitContext this object belongs to. On TransitContext this property points to itself.
-(TransitContext*)context;

/// @name Accessing Properties of Object

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id < NSCopying >)key;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)object atIndexedSubscript:(NSInteger)index;
- (id)objectForKeyedSubscript:(id)key;
 - (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key;

/// @name Calling Methods on Object

- (id)callMember:(NSString *)key;
- (id)callMember:(NSString *)key arg:(id)arg0;
- (id)callMember:(NSString *)key arg:(id)arg0 arg:(id)arg1;
- (id)callMember:(NSString *)key arg:(id)arg0 arg:(id)arg1 arg:(id)arg2;
- (id)callMember:(NSString *)key arguments:(NSArray *)arguments;

@end

/// Representation of complex JavaScript objects such as DOM elements.
@interface TransitProxy : TransitObject
@end

typedef id (^TransitGenericFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef void (^TransitGenericVoidFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef id (^TransitGenericReplaceFunctionBlock)(TransitFunction* original, TransitNativeFunctionCallScope *callScope);

/// Protocol to provide native implementations for [TransitContext functionWithDelegate:]
@protocol TransitFunctionBodyProtocol <NSObject>

/// Called [TransitFunction call].
/// @param function Reference to TransitFunction this is the implementation for.
/// @param thisArg JavaScript's this argument.
/// @param arguments Array if arguments passed to the function.
/// @param expectsResult YES, if call expects to return a result. Can be NO on async calls.
- (id)callWithFunction:(TransitFunction *)function thisArg:(id)thisArg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult;
@end

/// Baseclass on anything you can evaluate JavaScript on.
@interface TransitEvaluable : TransitObject

/// Various convenience methods.
/// @param jsCode String with actual JavaScript code.
-(id)eval:(NSString*)jsCode;
-(id)eval:(NSString *)jsCode val:(id)val0;
-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1;
-(id)eval:(NSString *)jsCode val:(id)val0 val:(id)val1 val:(id)val2;
-(id)eval:(NSString *)jsCode values:(NSArray*)values;

-(id)eval:(NSString*)jsCode thisArg:(id)thisArg;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg val:(id)val0 val:(id)val1;
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray*)values;

/// Evaluates Javascript in the context of this object.
/// @param jsCode String with actual JavaScript code.
/// @param thisArg Explicit reference to JavaScript this if not nil. Other convenience methods will pass nil.
/// @param values Array of arguments.
/// @param returnJSResult YES, if result expected. Passing NO can increase performance. Other convenience methods will pass YES.
-(id)eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)values returnJSResult:(BOOL)returnJSResult;

@end

/// Represents JavaScript environment.
@interface TransitContext : TransitEvaluable

-(TransitFunction*)functionWithGenericBlock:(TransitGenericFunctionBlock)block;

/// Creates a new TransitNativeFunction based on a protocol.
/// @param delegate Method implementation.
-(TransitFunction*)functionWithDelegate:(id<TransitFunctionBodyProtocol>)delegate;
-(TransitFunction*)replaceFunctionAt:(NSString *)path withGenericBlock:(TransitGenericReplaceFunctionBlock)block;
-(TransitFunction*)asyncFunctionWithGenericBlock:(TransitGenericVoidFunctionBlock)block;

-(TransitFunction*)functionWithBlock:(id)block;// NS_AVAILABLE(10_8, 6_0);
-(TransitFunction*)replaceFunctionAt:(NSString *)path withBlock:(id)block;// NS_AVAILABLE(10_8, 6_0);

@property(nonatomic, readonly) TransitCallScope* currentCallScope;

-(void)dispose;

@property(nonatomic, copy) void (^readyHandler)(TransitContext *);

- (BOOL)evalContentsOfFileOnGlobalScope:(NSString *)path encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (void)evalOnGlobalScope:(NSString *)string;

@end

/// Super type for native and JavaScript functions to provide a uniform interface.
@interface TransitFunction : TransitProxy

/// Calls method without arguments.
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

/// Function that represents native implementation.
@interface TransitNativeFunction : TransitFunction

/// Call dispose to explicitly release native function.
-(void)dispose;

/// TRUE, if calls can be executed aynchronous. Can increase performance.
@property(nonatomic, assign) BOOL async;

/// TRUE, if this arg is not needed. Can increase performance.
@property(nonatomic, assign) BOOL noThis;

/// Block that represents native implementation. Will always be a block, even if created with [TransitContext functionWithDelegate:].
@property(readonly) TransitGenericFunctionBlock block;

@end


/// Function that represents JavaScript implementation.
@interface TransitJSFunction : TransitFunction

@end


/// Singleton to access state for current call to TransitNativeFunction.
@interface TransitCurrentCall : NSObject

+(TransitContext *)context;
+(TransitFunctionCallScope *)callScope;
+(id)thisArg;
+(NSArray*)arguments;
+(TransitFunction *)replacedFunction;

+(id)forwardToReplacedFunction;

@end

/// State for the current call of a TransitNativeFunction
// @see TransitCurrentCall
@interface TransitCallScope : TransitEvaluable

@property (nonatomic, readonly) TransitCallScope *parentScope;
@property (nonatomic, readonly) id thisArg;
@property (nonatomic, readonly) BOOL expectsResult;
@property (nonatomic, readonly) NSUInteger level;

-(NSString*)callStackDescription;

@end

/// Created when calling any [TransitEvaluable eval:].
@interface TransitEvalCallScope : TransitCallScope

@property (nonatomic, readonly) NSString* jsCode;
@property (nonatomic, readonly) NSArray* values;

@end

/// Implicitly created on asynchrounous call.
@interface TransitAsyncCallScope : TransitCallScope
@end

/// Super type of native and JavaScript function calls. Created whenever a function is called from native code or JavaScript.
@interface TransitFunctionCallScope : TransitCallScope

@property (nonatomic, readonly) TransitFunction *function;
@property (nonatomic, readonly) NSArray* arguments;

/// Forwards current call to another TransitFunction. Preservers all arguments and thisArg.
/// @param function To be called.
/// @returns Result of called TransitFunction.
-(id)forwardToFunction:(TransitFunction *)function;

-(id)forwardToDelegate:(id<TransitFunctionBodyProtocol>)delegate;

@end

/// Created when calling a TransitJSFunction function from native code or JavaScript.
@interface TransitJSFunctionCallScope : TransitFunctionCallScope
@end

/// Created when calling a TransitNativeFunction function from native code or JavaScript.
@interface TransitNativeFunctionCallScope : TransitFunctionCallScope

@end

/// Abstract base-class for TransitUIWebViewContext and TransitWebViewContext
@interface TransitAbstractWebViewContext : TransitContext
@end

#pragma mark - iOS-specific code

#if TRANSIT_OS_IOS

/// Context to expose JavaScript environment of existing webview on iOS.
@interface TransitUIWebViewContext : TransitAbstractWebViewContext<UIWebViewDelegate>

+(id)contextWithUIWebView:(UIWebView*)webView;

-(id)initWithUIWebView:(UIWebView*)webView;

@property(readonly) UIWebView* webView;

@end

#endif

#pragma mark - OSX-specific code

#if TRANSIT_OS_MAC

/// Context to expose JavaScript environment of existing webview on OS X.
@interface TransitWebViewContext : TransitAbstractWebViewContext

+(id)contextWithWebView:(WebView*)webView;

-(id)initWithWebView:(WebView*)webView;

@property(readonly) WebView* webView;

@end

#endif

