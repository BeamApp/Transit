#import "TransitCore.h"
#import "TransitNativeFunction.h"

@protocol TransitFunctionBodyProtocol;
@class TransitContext;

@interface TransitNativeFunction(Private)

-(id)_callWithScope:(TransitNativeFunctionCallScope *)scope;
-(id)initWithContext:(TransitContext *)context nativeId:(NSString *)nativeId genericBlock:(TransitGenericFunctionBlock)block;

+ (TransitGenericFunctionBlock)genericFunctionBlockWithDelegate:(id <TransitFunctionBodyProtocol>)delegate;
+ (TransitGenericFunctionBlock)genericFunctionBlockWithBlock:(id)block;
+ (void)assertSpecificBlockCanBeUsedAsTransitFunction:(id)block;

@end
