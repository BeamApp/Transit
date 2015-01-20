#import "TransitEvaluator.h"
#import "TransitContext.h"

@class TransitCallScope;
@class TransitNativeFunction;
@class TransitProxy;
@class TransitJSFunction;

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
