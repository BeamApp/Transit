#import "TransitFunctionCallScope.h"

@class TransitFunction;
@class TransitCallScope;
@class TransitContext;

@interface TransitFunctionCallScope ()

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)arg arguments:(NSArray *)arguments expectsResult:(BOOL)expectsResult function:(TransitFunction *)function;

@end
