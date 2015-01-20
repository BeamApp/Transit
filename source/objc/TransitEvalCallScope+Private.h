#import "TransitEvalCallScope.h"

@class TransitContext;
@class TransitCallScope;

@interface TransitEvalCallScope ()

- (id)initWithContext:(TransitContext *)parentScope parentScope:(TransitCallScope *)scope thisArg:(id)thisArg jsCode:(NSString *)jsCode values:(NSArray *)values expectsResult:(BOOL)expectsResult;

@end
