#import "TransitCallScope.h"

@class TransitContext;

@interface TransitCallScope ()

- (id)initWithContext:(TransitContext *)context parentScope:(TransitCallScope *)parentScope thisArg:(id)thisArg expectsResult:(BOOL)expectsResult;

- (NSString*)callStackFrameDescription;

@end
