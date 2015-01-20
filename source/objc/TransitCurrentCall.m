//
// Created by Marcel Jackwerth on 16/01/15.
// Copyright (c) 2015 BeamApp. All rights reserved.
//

#import "TransitEvaluable.h"
#import "TransitCurrentCall.h"
#import "TransitContext.h"
#import "TransitFunctionCallScope.h"

@implementation TransitCurrentCall

+(TransitContext *)context {
    return _TransitCurrentCall_currentContext;
}

+(TransitFunctionCallScope *)callScope {
    TransitFunctionCallScope *scope = (TransitFunctionCallScope *) self.context.currentCallScope;
    if(scope && ![scope isKindOfClass:TransitFunctionCallScope.class])
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"currentCallScope is not a TransitFunctionCallScope: %@", scope] userInfo:nil];
    return scope;
}

+(id)thisArg {
    return [self.callScope.thisArg copy];
}

+(NSArray*)arguments {
    return self.callScope.arguments;
}

+ (TransitFunction *)replacedFunction {
    return _TransitCurrentCall_originalFunctionForCurrentCall;
}

+(id)forwardToReplacedFunction {
    return [self.callScope forwardToFunction:self.replacedFunction];
}

@end
