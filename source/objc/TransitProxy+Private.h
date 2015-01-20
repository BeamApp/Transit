#import "TransitProxy.h"

@class TransitContext;

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
