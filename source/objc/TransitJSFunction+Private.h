#import "TransitJSFunction.h"

@protocol TransitEvaluator;

@interface TransitJSFunction()

- (id)onEvaluator:(id <TransitEvaluator>)evaluator callWithThisArg:(id)thisArg arguments:(NSArray *)arguments returnResult:(BOOL)returnResult buildCallScope:(BOOL)buildCallScope;

@end
