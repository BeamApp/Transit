//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef TRANSIT_SPECIFIC_BLOCKS_SUPPORTED
#define TRANSIT_SPECIFIC_BLOCKS_SUPPORTED (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0)
#endif

BOOL transit_iOS6OrLater();
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

/// Returns the value associated with a given key.
/// @param key The key for which to return the corresponding value.
- (id)objectForKey:(id)key;

/// Adds or overrides a given key-value pair to the object.
/// @param object The value for key.
/// @param key The key for value.
- (void)setObject:(id)object forKey:(id < NSCopying >)key;

/// Adds or overrides a given key-value pair to the object.
/// @param idx An index within the bounds of the array.
- (id)objectAtIndexedSubscript:(NSUInteger)idx;


/// Replaces the object at the index with the new object, possibly adding the object.
/// @param object The object with which to replace the object at index index in the array. This value can be nil.
/// @param index The index of the object to be replaced.
- (void)setObject:(id)object atIndexedSubscript:(NSInteger)index;

/// Returns the value associated with a given key.
/// @param key The key for which to return the corresponding value.
- (id)objectForKeyedSubscript:(id)key;

/// Set or adds a given key-value pair to the object.
/// @param object The value for key.
/// @param key The key for value.
 - (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key;

/// @name Calling Methods on Object

/// Executes method on object
/// @param key Name of method to be executed.
- (id)callMember:(NSString *)key;

/// Executes method on object
/// @param key Name of method to be executed.
/// @param arg0 First argument.
- (id)callMember:(NSString *)key arg:(id)arg0;

/// Executes method on object
/// @param key Name of method to be executed.
/// @param arg0 First argument.
/// @param arg1 Second argument.
- (id)callMember:(NSString *)key arg:(id)arg0 arg:(id)arg1;

/// Executes method on object
/// @param key Name of method to be executed.
/// @param arg0 First argument.
/// @param arg1 Second argument.
/// @param arg2 Third argument.
- (id)callMember:(NSString *)key arg:(id)arg0 arg:(id)arg1 arg:(id)arg2;

/// Executes method on object
/// @param key Name of method to be executed.
/// @param arguments Array of arguments.
- (id)callMember:(NSString *)key arguments:(NSArray *)arguments;

@end

@interface TransitProxy : TransitObject

@property(nonatomic, readonly) id value;

@end

typedef id (^TransitGenericFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef void (^TransitGenericVoidFunctionBlock)(TransitNativeFunctionCallScope *callScope);
typedef id (^TransitGenericReplaceFunctionBlock)(TransitFunction* original, TransitNativeFunctionCallScope *callScope);

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
-(TransitFunction*)replaceFunctionAt:(NSString *)path withGenericBlock:(TransitGenericReplaceFunctionBlock)block;
-(TransitFunction*)asyncFunctionWithGenericBlock:(TransitGenericVoidFunctionBlock)block;

#if TRANSIT_SPECIFIC_BLOCKS_SUPPORTED
-(TransitFunction*)functionWithBlock:(id)block NS_AVAILABLE_IOS(6_0);
-(TransitFunction*)replaceFunctionAt:(NSString *)path withBlock:(id)block NS_AVAILABLE_IOS(6_0);
#endif


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


@interface TransitCurrentCall : NSObject

+(TransitContext *)context;
+(TransitFunctionCallScope *)callScope;
+(id)thisArg;
+(NSArray*)arguments;
+(TransitFunction *)replacedFunction;

+(id)forwardToReplacedFunction;

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