//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitContext.h"
#import "TransitNativeFunction.h"
#import "TransitCurrentCall.h"
#import "TransitQueuedCallToJSFunction.h"
#import "TransitNativeFunction+Private.h"
#import "TransitJSFunction.h"
#import "TransitEvalCallScope.h"
#import "TransitEvalCallScope+Private.h"
#import "TransitProxy+Private.h"
#import "TransitFunctionCallScope.h"
#import "TransitFunctionCallScope+Private.h"
#import "TransitCallScope+Private.h"

@implementation TransitContext {
    NSMutableDictionary* _retainedNativeProxies;
    int _lastNativeFunctionId;
    NSMutableArray* _jsProxiesToBeReleased;
    NSString* _transitGlobalVarJSRepresentation;
    NSMutableArray* _queuedAsyncCallsToJSFunctions;
}

-(id)init {
    self = [super init];
    if(self){
        _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT++;
        _retainedNativeProxies = [NSMutableDictionary dictionary];
        _jsProxiesToBeReleased = [NSMutableArray array];
        _transitGlobalVarJSRepresentation = transit_stringAsJSExpression(@"transit");
        _queuedAsyncCallsToJSFunctions = [NSMutableArray array];
    }
    return self;
}

-(void)dealloc {
    // dispose manually from here to maintain correct life cycle
    [self disposeAllNativeProxies];
    _TRANSIT_CONTEXT_LIVING_INSTANCE_COUNT--;
}

-(void)dispose {
    [self disposeAllNativeProxies];
}

-(TransitContext*)context {
    return self;
}

-(id)objectForImplicitVars {
    return transit_stringAsJSExpression(@"window");
}

-(NSString*)jsRepresentationForProxyWithId:(NSString*)proxyId {
    return proxyId;
}

-(NSString*)jsRepresentationToResolveProxyWithId:(NSString*)proxyId {
    return transit_stringAsJSExpression([NSString stringWithFormat:@"%@.r(\"%@\")", self.transitGlobalVarJSRepresentation, proxyId]);
}

-(NSString*)jsRepresentationForNativeFunctionWithId:(NSString*)proxyId {
    return [NSString stringWithFormat:@"%@%@", _TRANSIT_MARKER_PREFIX_NATIVE_FUNCTION, proxyId];
}

-(NSString*)jsRepresentationToResolveNativeFunctionWithId:(NSString*)proxyId async:(BOOL)async noThis:(BOOL)noThis {
    NSMutableString * result = [NSMutableString stringWithString:self.transitGlobalVarJSRepresentation];
    [result appendString:@".nativeFunction(\""];
    [result appendString:proxyId];
    [result appendString:@"\""];
    if(async || noThis) {
        [result appendString:@",{"];
        if(async)
            [result appendString:@"async:true"];
        if(async && noThis)
            [result appendString:@","];
        if(noThis)
            [result appendString:@"noThis:true"];
        [result appendString:@"}"];
    }
    [result appendString:@")"];

    return result;
}

-(void)disposeAllNativeProxies {
    for (id proxy in _retainedNativeProxies.allValues) {
        [proxy dispose];
    }
}

-(void)drainJSProxies {
    [self              eval:@"(function(ids){"
            "for(var i=0;i<ids.length;i++)"
            "@.releaseElementWithId(ids[i]);"
            "})(@)" thisArg:nil values:@[_transitGlobalVarJSRepresentation, _jsProxiesToBeReleased] returnJSResult:NO];
    [_jsProxiesToBeReleased removeAllObjects];

}


-(void)releaseJSProxyWithId:(NSString*)id {
    [_jsProxiesToBeReleased addObject:id];
    if(_jsProxiesToBeReleased.count > _TRANSIT_DRAIN_JS_PROXIES_THRESHOLD)
        [self drainJSProxies];
}

-(NSString*)nextNativeFunctionId {
    return [NSString stringWithFormat:@"%d", ++_lastNativeFunctionId];
}

-(TransitFunction*)functionWithGenericBlock:(TransitGenericFunctionBlock)block {
    TransitNativeFunction* function = [[TransitNativeFunction alloc] initWithContext:self nativeId:[self nextNativeFunctionId] genericBlock:block];
    [self retainNativeFunction:function];
    return function;
}

-(TransitFunction*)functionWithDelegate:(id<TransitFunctionBodyProtocol>)delegate {
    return [self functionWithGenericBlock:[TransitNativeFunction genericFunctionBlockWithDelegate:delegate]];
}

-(TransitFunction*)functionWithBlock:(id)block {
    return [self functionWithGenericBlock:[TransitNativeFunction genericFunctionBlockWithBlock:block]];
}

-(TransitFunction*)asyncFunctionWithGenericBlock:(TransitGenericVoidFunctionBlock)block {
    TransitNativeFunction* func = (TransitNativeFunction*) [self functionWithGenericBlock:^id(TransitNativeFunctionCallScope *scope) {
        block(scope);
        return nil;
    }];
    func.async = YES;
    return func;
}

-(TransitFunction*)replaceFunctionAt:(NSString *)path withGenericBlock:(TransitGenericReplaceFunctionBlock)block {
    TransitFunction *original = [self eval:path];
    if(!original)
        return nil;

    TransitFunction *function = [self functionWithGenericBlock:^id(TransitNativeFunctionCallScope *scope) {
        TransitFunction *oldOriginalFunctionForCurrentCall = _TransitCurrentCall_originalFunctionForCurrentCall;
        @try {
            _TransitCurrentCall_originalFunctionForCurrentCall = original;
            return block(original, scope);
        }@finally{
            _TransitCurrentCall_originalFunctionForCurrentCall = oldOriginalFunctionForCurrentCall;
        }
    }];

    [self eval:@"@ = @" values:@[transit_stringAsJSExpression(path), function]];

    return function;
}

-(TransitFunction*)replaceFunctionAt:(NSString *)path withBlock:(id)block {
    TransitGenericFunctionBlock genericBlock = [TransitNativeFunction genericFunctionBlockWithBlock:block];
    TransitGenericReplaceFunctionBlock genericReplaceBlock = ^id(TransitFunction *original, TransitNativeFunctionCallScope *callScope) {
        return genericBlock(callScope);
    };
    return [self replaceFunctionAt:path withGenericBlock:genericReplaceBlock];
}

-(void)retainNativeFunction:(TransitProxy*)proxy {
    NSParameterAssert(proxy.context == self);
    NSParameterAssert(proxy.proxyId);

//    if(_retainedNativeProxies[proxy.proxyId])
//        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"cannot retain native proxy twice" userInfo:nil];

    _retainedNativeProxies[proxy.proxyId] = proxy;
}

-(void)releaseNativeFunction:(TransitProxy *)proxy {
    NSParameterAssert(proxy.context == self);
    NSParameterAssert(proxy.proxyId);

//    id existing = _retainedNativeProxies[proxy.proxyId];
//    if(!existing)
//        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"cannot release unretained proxy" userInfo:nil];

    [_retainedNativeProxies removeObjectForKey:proxy.proxyId];
}

-(NSDictionary*)retainedNativeProxies {
    return _retainedNativeProxies;
}

-(NSString*)transitGlobalVarJSRepresentation {
    return _transitGlobalVarJSRepresentation;
}

-(TransitNativeFunction*)retainedNativeFunctionWithId:(id)nativeProxyId {
    TransitNativeFunction* func = _retainedNativeProxies[nativeProxyId];

    if(!func) {
        NSString* reason = [NSString stringWithFormat:@"No native function with id: %@. Could have been disposed.", nativeProxyId];
        @throw [NSException exceptionWithName:@"TransitException" reason:reason userInfo:@{NSLocalizedDescriptionKey: reason}];
    }

    return func;
}

+(NSRegularExpression*)regularExpressionForMarker:(NSString*)marker {
    static NSMutableDictionary* cache;
    if(!cache)cache = [NSMutableDictionary dictionary];

    NSRegularExpression *result = cache[marker];
    if(!result) {
        NSString* pattern = [NSString stringWithFormat:@"^%@([\\d\\w]+)$", [NSRegularExpression escapedPatternForString:marker]];
        result = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        cache[marker] = result;
    }
    return result;
}

+(id)proxyIdFromString:(NSString*)string atGroupIndex:(NSUInteger)idx forMarker:(NSString*)marker {
    NSRegularExpression* expression = [self regularExpressionForMarker:marker];
    NSTextCheckingResult *match = [expression firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if(match) {
        return [string substringWithRange:[match rangeAtIndex:idx]];
    }
    return nil;
}

-(id)recursivelyReplaceMarkersWithProxies:(id)unproxified {
    if([unproxified isKindOfClass:NSString.class]) {
        if([unproxified length] >= _TRANSIT_MARKER_PREFIX_MIN_LEN && [unproxified characterAtIndex:0] == '_' && [unproxified characterAtIndex:1] == '_') {
            id jsFunctionProxyId = [self.class proxyIdFromString:unproxified atGroupIndex:0 forMarker:_TRANSIT_MARKER_PREFIX_JS_FUNCTION_];
            if(jsFunctionProxyId)
                return [[TransitJSFunction alloc] initWithContext:self proxyId:jsFunctionProxyId];

            id objectProxyId = [self.class proxyIdFromString:unproxified atGroupIndex:0 forMarker:_TRANSIT_MARKER_PREFIX_OBJECT_PROXY_];
            if(objectProxyId)
                return [[TransitProxy alloc] initWithContext:self proxyId:objectProxyId];

            id nativeFunctionProxyId = [self.class proxyIdFromString:unproxified atGroupIndex:1 forMarker:_TRANSIT_MARKER_PREFIX_NATIVE_FUNCTION];
            if(nativeFunctionProxyId)
                return [self retainedNativeFunctionWithId:nativeFunctionProxyId];

            if([_TRANSIT_MARKER_GLOBAL_OBJECT isEqualToString:unproxified])
                return self;
        }
    }
    if([unproxified isKindOfClass:NSDictionary.class]) {
        // JSONParser already returns mutable values
        //NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:unproxified];
        NSMutableDictionary *dict = unproxified;
        for (id key in dict.allKeys) {
            dict[key] = [self recursivelyReplaceMarkersWithProxies:dict[key]];
        }
        return dict;
    }
    if([unproxified isKindOfClass:NSArray.class]) {
        // JSONParser already returns mutable values
        //NSMutableArray *array = [NSMutableArray arrayWithArray:unproxified];
        NSMutableArray *array = unproxified;
        for(int i=0; i<array.count; i++)
            array[i] = [self recursivelyReplaceMarkersWithProxies:array[i]];
        return array;
    }

    return unproxified;
}

- (id)recursivelyReplaceBlocksWithNativeFunctions:(id)value {
    if([value isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *dict = [value mutableCopy];
        for (id key in dict.allKeys) {
            dict[key] = [self recursivelyReplaceBlocksWithNativeFunctions:dict[key]];
        }
        return dict;
    }
    if([value isKindOfClass:NSArray.class]) {
        NSMutableArray *array = [value mutableCopy];
        for(NSUInteger i=0; i<array.count; i++)
            array[i] = [self recursivelyReplaceBlocksWithNativeFunctions:array[i]];
        return array;
    }
    if([value isKindOfClass:NSClassFromString(@"NSBlock")]) {
        return [self functionWithBlock:value];
    }

    return value;
}

-(id)invokeNativeWithDescription:(NSDictionary*)description {
    id nativeProxyId = description[@"nativeId"];
    TransitFunction* func;
    @try {
        func = [self retainedNativeFunctionWithId:nativeProxyId];
    } @catch (NSException *exception) {
        NSError* error = transit_errorWithCodeFromException(5, exception);
        NSLog(@"TRANSIT-BRIDGE-ERROR: %@ (while called from JavaScript)", error.userInfo[NSLocalizedDescriptionKey]);
        return error;
    }

    id thisArg = description[@"thisArg"];
    NSArray *arguments = description[@"args"];
    @try {
        id result = [func callWithThisArg:thisArg arguments:arguments];
        return result;
    }
    @catch (NSException *exception) {
        NSError* error = transit_errorWithCodeFromException(5, exception);
        NSLog(@"TRANSIT-NATIVE-ERROR: %@ (while called from javascript with arguments %@)", error.userInfo[NSLocalizedDescriptionKey], arguments);
        return error;
    }
    @finally {

    }
}

- (id)invokeNativeFunc:(TransitNativeFunction *)func thisArg:(id)thisArg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult {
    if(thisArg == nil || thisArg == NSNull.null) {
        thisArg = self;
    }

    TransitNativeFunctionCallScope *scope = [[TransitNativeFunctionCallScope alloc] initWithContext:self parentScope:_currentCallScope thisArg:thisArg arguments:arguments expectsResult:expectsResult function:func];
    _currentCallScope = scope;
    TransitContext *oldTransitContextCurrentContext = _TransitCurrentCall_currentContext;
    _TransitCurrentCall_currentContext = self;
    @try {
        return [func _callWithScope:scope];
    }
    @finally {
        _TransitCurrentCall_currentContext = oldTransitContextCurrentContext;
        _currentCallScope = _currentCallScope.parentScope;
    }
}

- (id)_eval:(NSString *)jsExpression jsThisArg:(NSString *)jsAdjustedThisArg collectedProxiesOnScope:(NSOrderedSet *)proxiesOnScope returnJSResult:(BOOL)returnJSResult onGlobalScope:(BOOL)globalScope useAndRestoreCallScope:(TransitCallScope *)callScope {
    @throw @"to be implemented by subclass";
}

- (id)_eval:(NSString *)jsCode thisArg:(id)thisArg values:(NSArray *)arguments returnJSResult:(BOOL)returnJSResult useAndRestoreCallScope:(TransitCallScope *)callScope {
    @throw @"to be implemented by subclass";
}

-(void)handleQueuedAsyncCallsToJSFunctions{
    if(_queuedAsyncCallsToJSFunctions.count <= 0)
        return;

    NSMutableString* js = [NSMutableString stringWithString:@""];
    NSMutableOrderedSet* proxiesOnScope = NSMutableOrderedSet.orderedSet;

    for(TransitQueuedCallToJSFunction* queuedCall in _queuedAsyncCallsToJSFunctions) {
        [js appendString:[queuedCall jsRepresentationOfCallCollectingProxiesOnScope:proxiesOnScope]];
    }
    [_queuedAsyncCallsToJSFunctions removeAllObjects];

    TransitCallScope *callScope = [TransitAsyncCallScope.alloc initWithContext:self parentScope:_currentCallScope thisArg:nil expectsResult:NO];
    [self _eval:js jsThisArg:@"null" collectedProxiesOnScope:proxiesOnScope returnJSResult:NO onGlobalScope:NO useAndRestoreCallScope:callScope];
}

-(void)queueAsyncCallToJSFunction:(TransitJSFunction*)jsFunc thisArg:(id)thisArg arguments:(NSArray*)arguments {
    [_queuedAsyncCallsToJSFunctions addObject:[TransitQueuedCallToJSFunction.alloc initWithJSFunction:jsFunc thisArg:thisArg arguments:arguments]];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleQueuedAsyncCallsToJSFunctions) object:nil];
    [self performSelector:@selector(handleQueuedAsyncCallsToJSFunctions) withObject:nil afterDelay:_TRANSIT_ASYNC_CALL_DELAY];
}

- (void)pushCallScope:(TransitCallScope *)scope {
    NSParameterAssert(scope.parentScope == _currentCallScope);
    _currentCallScope = scope;
}

- (void)popCallScope {
    NSAssert(_currentCallScope != nil, @"cannot pop call scope any further");
    _currentCallScope = _currentCallScope.parentScope;
}

- (BOOL)evalContentsOfFileOnGlobalScope:(NSString *)path encoding:(NSStringEncoding)encoding error:(NSError **)error {
    NSString* jsCode = [NSString stringWithContentsOfFile:path encoding:encoding error:error];
    if(jsCode)
        [self evalOnGlobalScope:jsCode];
    return jsCode != nil;
}

- (void)evalOnGlobalScope:(NSString *)jsCode {
    TransitCallScope *callScope = [[TransitEvalCallScope alloc] initWithContext:self parentScope:_currentCallScope thisArg:self jsCode:jsCode values:@[] expectsResult:NO];
    [self _eval:jsCode jsThisArg:@"null" collectedProxiesOnScope:nil returnJSResult:NO onGlobalScope:YES useAndRestoreCallScope:callScope];
}
@end
