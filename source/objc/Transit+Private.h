//
//  Transit.h
//  TransitTestsIOS
//
//  Created by Heiko Behrens on 08.02.13.
//  Copyright (c) 2013 BeamApp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Transit.h"


@interface TransitProxy(Private)

-(id)initWithRootContext:(TransitContext*)rootContext;
-(id)initWithRootContext:(TransitContext*)rootContext proxyId:(NSString*)proxyId;
-(id)initWithRootContext:(TransitContext*)rootContext value:(id)value;
-(id)initWithRootContext:(TransitContext *)rootContext jsRepresentation:(NSString*)jsRepresentation;

-(void)dispose;
-(BOOL)disposed;

@property(readonly) NSString* proxyId;

-(void)clearRootContextAndProxyId;

+(NSString*)jsExpressionFromCode:(NSString*)jsCode arguments:(NSArray*)arguments collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;
+(NSString*)jsRepresentation:(id)object collectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;
-(NSString*)_jsRepresentationCollectingProxiesOnScope:(NSMutableOrderedSet*)proxiesOnScope;
-(NSString*)jsRepresentationToResolveProxy;

@end

extern NSUInteger _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;

@interface TransitContext(Private)

@property (readonly) NSMutableDictionary* retainedNativeProxies;

-(void)releaseJSProxyWithId:(NSString*)proxy;
-(void)drainJSProxies;

-(void)retainNativeProxy:(TransitProxy*)proxy;
-(void)releaseNativeProxy:(TransitProxy*)proxy;
-(TransitNativeFunction*)retainedNativeFunctionWithId:(id)nativeProxyId;

-(id)recursivelyReplaceMarkersWithProxies:(id)unproxified;

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId;
-(NSString*)jsRepresentationToResolveProxyWithId:(NSString*)proxyId;
-(NSString*)jsRepresentationForNativeFunctionWithId:(NSString*)proxyId;
-(NSString*)jsRepresentationToResolveNativeFunctionWithId:(NSString*)proxyId;

-(id)invokeNativeDescription:(NSDictionary*)description;

-(NSString*)transitGlobalVarJSExpression;

-(NSString*)lastEvaluatedJSCode;

-(NSString*)nextNativeFunctionId;

-(id)_evalJsExpression:(NSString*)jsExpression jsThisArg:(NSString*)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet*)proxiesOnScope returnJSResult:(BOOL)returnJSResult;

@end

@interface TransitNativeFunction(Private)

-(id)callWithProxifedThisArg:(TransitProxy*)thisArg proxifiedArguments:(NSArray*)arguments;
-(id)initWithRootContext:(TransitContext *)rootContext nativeId:(NSString*)nativeId block:(TransitFunctionBlock)block;

@end

typedef void (^TransitUIWebViewContextRequestHandler)(TransitUIWebViewContext*,NSURLRequest*);
@interface TransitUIWebViewContext(Private)

-(void)invokeNative;

@property(copy) TransitUIWebViewContextRequestHandler handleRequestBlock;
@property(assign) BOOL proxifyEval;

@end

extern NSString* _TRANSIT_JS_RUNTIME_CODE;
extern NSString* _TRANSIT_MARKER_PREFIX_JS_FUNCTION_;
extern NSString* _TRANSIT_MARKER_PREFIX_OBJECT_PROXY_;
extern NSUInteger _TRANSIT_DRAIN_JS_PROXIES_THRESHOLD;