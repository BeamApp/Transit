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

-(void)dispose;
-(BOOL)disposed;
-(TransitProxy*)transitGlobalVarProxy;

@property(readonly) NSString* proxyId;

-(void)clearRootContextAndProxyId;

@end

extern NSUInteger _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT;

@interface TransitContext(Private)

@property (readonly) NSMutableDictionary* retainedNativeProxies;

-(void)releaseJSProxyWithId:(NSString*)proxy;
-(void)retainNativeProxy:(TransitProxy*)proxy;
-(void)releaseNativeProxy:(TransitProxy*)proxy;

-(id)recursivelyReplaceMarkersWithProxies:(id)unproxified;

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId;

-(id)invokeNativeDescription:(NSDictionary*)description;

@end

@interface TransitJSDirectExpression : NSObject

-(id)initWithExpression:(NSString*)expression;

@property(readonly) NSString* expression;

@end

@interface TransitNativeFunction(Private)

-(id)callWithProxifedThisArg:(TransitProxy*)thisArg proxifiedArguments:(NSArray*)arguments;

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