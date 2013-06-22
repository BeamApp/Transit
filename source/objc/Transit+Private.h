//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Transit.h"

@interface TransitObject(Private)

-(id)initWithContext:(TransitContext*)context;
-(void)clearContext;

@end


@interface TransitProxy(Private)

-(id)initWithContext:(TransitContext*)context;
-(id)initWithContext:(TransitContext *)context proxyId:(NSString*)proxyId;
-(id)initWithContext:(TransitContext *)context value:(id)value;
-(id)initWitContext:(TransitContext *)context jsRepresentation:(NSString*)jsRepresentation;

-(void)dispose;
-(BOOL)disposed;

@property(nonatomic, readonly) id value;
@property(readonly) NSString* proxyId;

-(void)clearContextAndProxyId;

+(NSString*)jsRepresentationFromCode:(NSString *)jsCode arguments:(NSArray *)arguments collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;
+(NSString*)jsRepresentation:(id)object collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;
-(NSString*)_jsRepresentationCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;
-(NSString*)jsRepresentationToResolveProxy;

@end

extern NSUInteger _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;


@protocol TransitEvaluator <NSObject>

- (id)_eval:(NSString *)jsExpression jsThisArg:(NSString *)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet *)proxiesOnScope returnJSResult:(BOOL)returnJSResult onGlobalScope:(BOOL)globalScope useAndRestoreCallScope:(TransitCallScope *)callScope;
- (id)_eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult useAndRestoreCallScope:(TransitCallScope *)callScope;

@end

@interface TransitContext(Private) <TransitEvaluator>

@property (readonly) NSMutableDictionary* retainedNativeProxies;

-(void)releaseJSProxyWithId:(NSString*)proxy;
-(void)drainJSProxies;

-(void)queueAsyncCallToJSFunction:(TransitJSFunction*)jsFunc thisArg:(id)thisArg arguments:(NSArray*)arguments;

-(void)retainNativeFunction:(TransitProxy*)proxy;
-(void)releaseNativeFunction:(TransitProxy*)proxy;
-(TransitNativeFunction*)retainedNativeFunctionWithId:(id)nativeProxyId;

-(id)recursivelyReplaceMarkersWithProxies:(id)unproxified;
- (id)recursivelyReplaceBlocksWithNativeFunctions:(id)value;

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId;
-(NSString*)jsRepresentationToResolveProxyWithId:(NSString*)proxyId;
-(NSString*)jsRepresentationForNativeFunctionWithId:(NSString*)proxyId;
-(NSString*)jsRepresentationToResolveNativeFunctionWithId:(NSString*)proxyId async:(BOOL)async noThis:(BOOL)noThis;

-(id)invokeNativeWithDescription:(NSDictionary*)description;

-(NSString*)transitGlobalVarJSRepresentation;

-(NSString*)lastEvaluatedJSCode;

-(NSString*)nextNativeFunctionId;

- (id)_eval:(NSString *)jsExpression jsThisArg:(NSString *)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet *)proxiesOnScope returnJSResult:(BOOL)returnJSResult onGlobalScope:(BOOL)globalScope useAndRestoreCallScope:(TransitCallScope *)callScope;
- (id)_eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult useAndRestoreCallScope:(TransitCallScope *)callScope;

- (void)pushCallScope:(TransitCallScope *)scope;
- (void)popCallScope;

@end

@interface TransitNativeFunction(Private)

-(id)_callWithScope:(TransitNativeFunctionCallScope *)scope;
-(id)initWithContext:(TransitContext *)context nativeId:(NSString *)nativeId genericBlock:(TransitGenericFunctionBlock)block;

+ (TransitGenericFunctionBlock)genericFunctionBlockWithDelegate:(id <TransitFunctionBodyProtocol>)delegate;
+ (TransitGenericFunctionBlock)genericFunctionBlockWithBlock:(id)block;
+ (void)assertSpecificBlockCanBeUsedAsTransitFunction:(id)block;

@end

@interface TransitJSFunction(Private)

- (id)onEvaluator:(id <TransitEvaluator>)evaluator callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult buildCallScope:(BOOL)buildCallScope;

@end

@interface TransitQueuedCallToJSFunction : NSObject<TransitEvaluator>

-(id)initWithJSFunction:(TransitJSFunction*)jsFunc thisArg:(id)thisArg arguments:(NSArray*)arguments;
-(NSString*)jsRepresentationOfCallCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;

@end

@interface TransitCallScope (Private)

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)thisArg expectsResult:(BOOL)expectsResult;

- (NSString*)callStackFrameDescription;

@end

@interface TransitEvalCallScope (Private)

- (id)initWithContext:(TransitContext *)parentScope parentScope:(TransitCallScope *)scope thisArg:(id)thisArg jsCode:(NSString *)jsCode values:(NSArray *)values expectsResult:(BOOL)expectsResult;

@end

@interface TransitFunctionCallScope (Private)

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)arg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult function:(TransitFunction *)function;

@end

@interface NSInvocation (TransitAdditions)

-(void)transit_setObject:(id)object forArgumentAtIndex:(NSUInteger)index;
-(id)transit_returnValueAsObject;

@end

extern NSString* _TRANSIT_JS_RUNTIME_CODE;
extern NSString* _TRANSIT_MARKER_PREFIX_JS_FUNCTION_;
extern NSString* _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_;
extern NSString* _TRANSIT_MARKER_GLOBAL_OBJECT;
extern NSUInteger _TRANSIT_DRAIN_JS_PROXIES_THRESHOLD;


typedef void (^TransitWebViewContextRequestHandler)(TransitAbstractWebViewContext*,NSURLRequest*);

@interface TransitAbstractWebViewContext(Private)

@property (readonly) BOOL codeInjected;
@property(copy) TransitWebViewContextRequestHandler handleRequestBlock;

- (void)doInvokeNative;
- (id)parseJSON:(NSString *)json;

@end

#pragma mark - iOS-specific code

#if TARGET_OS_IPHONE

@interface TransitUIWebViewContext(Private)

@property(assign) BOOL proxifyEval;

@end

#endif