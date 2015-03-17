#import "TransitObject.h"

@class TransitContext;

@interface TransitObject(Private)

-(id)initWithContext:(TransitContext*)context;
-(void)clearContext;

@end
